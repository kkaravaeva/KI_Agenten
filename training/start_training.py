"""
Startet ein mlagents-Training im KI_Agenten-Projekt.

Verwendung:
    python training/start_training.py [--run-id=<name>] [--resume] [--force] [--no-patch] [--config=<pfad>]

Standardmäßig:
    Config:   config/model_comparison.yaml   (LSTM + Transformer + MLP gleichzeitig)
    Run-ID:   model_comparison_v1
    Venv:     C:/Users/Finnl/mlagents-31008

Beispiele:
    python training/start_training.py
    python training/start_training.py --run-id=model_comparison_v1 --resume
    python training/start_training.py --run-id=model_comparison_v1 --force
    python training/start_training.py --config=config/labyrinth_lstm_v7.yaml --run-id=lstm_v8
"""

import subprocess
import sys
import os
from pathlib import Path

# ── Konfiguration ──────────────────────────────────────────────────────────────

PROJECT_DIR = Path(__file__).parent.parent   # KI_Agenten/

# venv-Python portabel finden (Laptop oder Desktop); zuerst Kandidaten, dann sys.executable
_VENV_CANDIDATES = [
    Path(r"C:\Users\Finnl\mlagents-31008\Scripts\python.exe"),
    Path(r"C:\Users\alxbe\KI_Agent\.venv\Scripts\python.exe"),
]
PYTHON = next((p for p in _VENV_CANDIDATES if p.exists()), Path(sys.executable))
CONFIG      = "config/model_comparison.yaml"
DEFAULT_RUN = "model_comparison_v1"

# ── Argumente parsen ───────────────────────────────────────────────────────────

args     = sys.argv[1:]
run_id   = next((a.split("=", 1)[1] for a in args if a.startswith("--run-id=")),   DEFAULT_RUN)
config   = next((a.split("=", 1)[1] for a in args if a.startswith("--config=")),   CONFIG)
resume   = "--resume"   in args
force    = "--force"    in args
no_patch = "--no-patch" in args

# ── Patch anwenden (für Transformer-Memory erforderlich) ──────────────────────

if not no_patch:
    print("=== Transformer-Patch prüfen / anwenden ===")
    patch_result = subprocess.run(
        [str(PYTHON), "training/patch_mlagents.py"],
        cwd=PROJECT_DIR,
    )
    if patch_result.returncode != 0:
        print("[FEHLER] Patch fehlgeschlagen. Abbruch.")
        sys.exit(1)
    print()

# ── mlagents-learn starten ─────────────────────────────────────────────────────

cmd = [
    str(PYTHON), "-m", "mlagents.trainers.learn",
    config,
    f"--run-id={run_id}",
]
if resume:
    cmd.append("--resume")
if force:
    cmd.append("--force")

flags_str = " ".join([
    "--resume" if resume else "",
    "--force"  if force  else "",
]).strip() or "(keine)"

print("=== Model Comparison Training starten ===")
print(f"  Config:    {config}")
print(f"  Run-ID:    {run_id}")
print(f"  Flags:     {flags_str}")
print(f"  Python:    {PYTHON}")
print()
print("  Behaviors in dieser Config:")
print("    LSTM_Navigator        -> Spalte 0 (LSTM_0/1/2)")
print("    Transformer_Navigator -> Spalte 1 (Transformer_0/1/2)")
print("    MLP_Navigator         -> Spalte 2 (MLP_0/1/2)")
print()
print("Warte auf Unity: Wenn 'Listening on port 5004' erscheint -> Play in Unity druecken.")
print("-" * 70)

os.chdir(PROJECT_DIR)
subprocess.run(cmd)
