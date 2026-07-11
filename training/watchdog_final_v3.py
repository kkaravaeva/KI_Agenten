# -*- coding: utf-8 -*-
"""Watchdog für den final_v3-Vergleichslauf.

Läuft als eigenständiger Prozess (unabhängig von Claude-Session/Terminal) und
prüft alle 5 Minuten:

1. ENTROPY-NOTBREMSE: Fällt die Transformer-Entropy unter ENTROPY_LIMIT,
   wird das Training gestoppt (Kollaps-Schutz). Es wird NICHT neu gestartet,
   Marker: trainer_logs/WATCHDOG_ENTROPY_STOP.flag
   Nur der Transformer wird überwacht: Er trainiert mit konstanter Lernrate
   bis zum Schluss (Kollaps-Risiko). MLP/LSTM haben linear abfallende
   Lernraten — niedrige Entropy spät im Training ist dort harmlos.

2. AUTO-RESUME: Läuft kein Trainer-Prozess (Absturz, externer Kill), wird
   das Training mit --resume neu gestartet (Curriculum bleibt dank
   curriculum_state_*.json erhalten). Ebenso wird die stündliche
   PDF-Analyse (hourly_analysis.py) wiederbelebt.

Deaktivieren: Datei trainer_logs/WATCHDOG_DISABLE.flag anlegen
(oder den Prozess beenden). Log: trainer_logs/watchdog_final_v3.log
"""
import datetime
import glob
import os
import subprocess
import time
from pathlib import Path

ROOT          = Path(__file__).resolve().parent.parent
VENV_PY       = r"C:\Users\Finnl\mlagents-31008\Scripts\python.exe"
LOG_DIR       = ROOT / "trainer_logs"
LOG_FILE      = LOG_DIR / "watchdog_final_v3.log"
FLAG_ENTROPY  = LOG_DIR / "WATCHDOG_ENTROPY_STOP.flag"
FLAG_DISABLE  = LOG_DIR / "WATCHDOG_DISABLE.flag"

ENTROPY_LIMIT  = 0.5    # kritischer Wert: Policy praktisch deterministisch
CHECK_INTERVAL = 300    # Sekunden
STARTUP_GRACE  = 180    # nach einem Neustart so lange nicht erneut eingreifen

DETACHED = 0x00000008 | 0x00000200 | 0x08000000  # DETACHED | NEW_GROUP | NO_WINDOW

LOG_DIR.mkdir(exist_ok=True)


def log(msg):
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def ps(cmd):
    r = subprocess.run(["powershell", "-NoProfile", "-Command", cmd],
                       capture_output=True, text=True, timeout=60)
    return (r.stdout or "").strip()


def trainer_running():
    out = ps("(Get-CimInstance Win32_Process -Filter \"Name = 'python.exe'\" | "
             "Where-Object { $_.CommandLine -match 'mlagents\\.trainers\\.learn' } | "
             "Measure-Object).Count")
    return out.isdigit() and int(out) > 0


def analysis_running():
    out = ps("(Get-CimInstance Win32_Process -Filter \"Name = 'python.exe'\" | "
             "Where-Object { $_.CommandLine -match 'hourly_analysis' } | "
             "Measure-Object).Count")
    return out.isdigit() and int(out) > 0


def transformer_entropy():
    """Letzter Policy/Entropy-Wert des Transformers (neueste Event-Datei zuerst)."""
    from tensorboard.backend.event_processing.event_accumulator import EventAccumulator
    bdir = ROOT / "results" / "model_comparison_final_v3" / "Transformer_Navigator"
    files = sorted(glob.glob(str(bdir / "*.tfevents*")), key=os.path.getmtime, reverse=True)
    for f in files:
        try:
            ea = EventAccumulator(f, size_guidance={"scalars": 0})
            ea.Reload()
            if "Policy/Entropy" in ea.Tags().get("scalars", []):
                ev = ea.Scalars("Policy/Entropy")
                if ev:
                    return ev[-1].value, ev[-1].step
        except Exception:
            continue
    return None, None


def kill_training(reason):
    log(f"Stoppe Training: {reason}")
    ps("Get-CimInstance Win32_Process -Filter \"Name = 'python.exe'\" | "
       "Where-Object { $_.CommandLine -match 'mlagents\\.trainers\\.learn|spawn_main' } | "
       "ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; "
       "Get-Process -Name KI_Agenten -ErrorAction SilentlyContinue | Stop-Process -Force")


def start_training():
    ts = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    out = open(LOG_DIR / f"resume_{ts}.log", "w", encoding="utf-8")
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    subprocess.Popen(
        [VENV_PY, "-m", "mlagents.trainers.learn",
         "config\\model_comparison_final_v3.yaml",
         "--run-id", "model_comparison_final_v3",
         "--env", "Build\\KI_Agenten.exe",
         "--num-envs", "5", "--no-graphics", "--time-scale", "40",
         "--base-port", "5004", "--results-dir", "results", "--resume"],
        cwd=str(ROOT), stdout=out, stderr=subprocess.STDOUT,
        env=env, creationflags=DETACHED)
    log(f"Training neu gestartet (--resume), Log: resume_{ts}.log")


def start_analysis():
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    subprocess.Popen(
        [VENV_PY, str(ROOT / "training" / "hourly_analysis.py")],
        cwd=str(ROOT), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        env=env, creationflags=DETACHED)
    log("hourly_analysis.py neu gestartet")


def main():
    log(f"Watchdog gestartet. Entropy-Limit={ENTROPY_LIMIT} (nur Transformer), "
        f"Intervall={CHECK_INTERVAL}s")
    last_restart = 0.0
    while True:
        try:
            if FLAG_DISABLE.exists():
                log("WATCHDOG_DISABLE.flag gefunden — Watchdog beendet sich.")
                return

            if FLAG_ENTROPY.exists():
                # Nach Entropy-Stopp: nichts mehr neu starten, nur weiter wachen.
                time.sleep(CHECK_INTERVAL)
                continue

            running = trainer_running()

            if running:
                ent, step = transformer_entropy()
                if ent is not None and ent < ENTROPY_LIMIT:
                    FLAG_ENTROPY.write_text(
                        f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
                        f"Entropy={ent:.3f} bei Step {step} < Limit {ENTROPY_LIMIT}\n",
                        encoding="utf-8")
                    kill_training(f"Transformer-Entropy {ent:.3f} < {ENTROPY_LIMIT} "
                                  f"(Step {step}) — Kollaps-Notbremse")
                    continue
            elif time.time() - last_restart > STARTUP_GRACE:
                log("Kein Trainer-Prozess gefunden — starte Training neu.")
                start_training()
                last_restart = time.time()

            if not analysis_running():
                start_analysis()

        except Exception as e:
            log(f"Watchdog-Fehler (mache weiter): {e}")

        time.sleep(CHECK_INTERVAL)


if __name__ == "__main__":
    main()
