"""
Liest TensorBoard-Logs aus results/model_comparison_v2/ und erstellt eine PDF-Analyse.
Wird alle 5 Minuten aufgerufen (via ScheduleWakeup in Claude Code).

Ausgabe: training_reports/report_YYYY-MM-DD_HH-MM-SS.pdf
"""

import sys
import os
import datetime
import tempfile
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.backends.backend_pdf import PdfPages

from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

# â”€â”€ Konfiguration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

PROJECT_DIR  = Path(__file__).parent.parent
RESULTS_DIR  = PROJECT_DIR / "results" / "model_comparison_v2"
REPORTS_DIR  = PROJECT_DIR / "training_reports"
REPORTS_DIR.mkdir(exist_ok=True)

WINDOW_SEC = 5 * 60   # letzte 5 Minuten

BEHAVIORS = {
    "LSTM_Navigator":        {"label": "LSTM",        "color": "#2980b9"},
    "Transformer_Navigator": {"label": "Transformer", "color": "#e67e22"},
    "MLP_Navigator":         {"label": "MLP",         "color": "#27ae60"},
}

# TensorBoard-Keys die pro Behavior-Verzeichnis geloggt werden
STD_KEYS = [
    "Environment/Cumulative Reward",
    "Environment/Episode Length",
    "Losses/Policy Loss",
    "Losses/Value Loss",
    "Policy/Entropy",
    "Policy/Learning Rate",
]

CUSTOM_KEY_SUFFIXES = [
    "SuccessRate",
    "RollingSuccessRate",
    "CurriculumPhase",
    "LavaCrossings",
    "LavaJumpAttempts",
    "DeathByLava",
    "DeathByHole",
    "DeathByTimeout",
    "EpisodeLength",
    "StepsToGoal",
]

# â”€â”€ Hilfsfunktionen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

def load_scalars(behavior_name):
    """Laedt alle Scalar-Events aus dem TensorBoard-Verzeichnis eines Behaviors."""
    bdir = RESULTS_DIR / behavior_name
    if not bdir.exists():
        return {}

    ea = EventAccumulator(str(bdir), size_guidance={"scalars": 0})
    try:
        ea.Reload()
    except Exception as e:
        print(f"[WARN] EventAccumulator Reload fuer {behavior_name}: {e}")
        return {}

    data = {}
    available = ea.Tags().get("scalars", [])
    for key in available:
        try:
            events = ea.Scalars(key)
            data[key] = {
                "wall_times": np.array([e.wall_time for e in events]),
                "steps":      np.array([e.step      for e in events]),
                "values":     np.array([e.value     for e in events]),
            }
        except Exception:
            pass
    return data


def last_value(series):
    """Letzter Wert einer Serie oder None."""
    if series is None or len(series["values"]) == 0:
        return None
    return float(series["values"][-1])


def recent_mean(series, window_sec):
    """Mittelwert der Werte in den letzten window_sec Sekunden."""
    if series is None or len(series["values"]) == 0:
        return None
    cutoff = series["wall_times"][-1] - window_sec
    mask   = series["wall_times"] >= cutoff
    vals   = series["values"][mask]
    return float(np.mean(vals)) if len(vals) > 0 else None


def fmt(v, decimals=3):
    if v is None:
        return "â€”"
    return f"{v:.{decimals}f}"


def training_duration(all_data):
    """Gibt die Gesamtlaufzeit des Trainings als String zurueck."""
    earliest = None
    latest   = None
    for bname, data in all_data.items():
        for key, series in data.items():
            if len(series["wall_times"]) == 0:
                continue
            t0 = series["wall_times"][0]
            t1 = series["wall_times"][-1]
            earliest = t0 if earliest is None else min(earliest, t0)
            latest   = t1 if latest   is None else max(latest,   t1)
    if earliest is None:
        return "â€”"
    secs = int(latest - earliest)
    h, rem = divmod(secs, 3600)
    m, s   = divmod(rem, 60)
    return f"{h:02d}:{m:02d}:{s:02d}"


def total_steps(data):
    key = "Environment/Cumulative Reward"
    if key not in data or len(data[key]["steps"]) == 0:
        return 0
    return int(data[key]["steps"][-1])


# â”€â”€ Chart-Hilfsfunktionen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

def smooth(values, w=10):
    if len(values) < w:
        return values
    kernel = np.ones(w) / w
    padded = np.concatenate([np.full(w - 1, values[0]), values])
    return np.convolve(padded, kernel, mode="valid")


def plot_metric(ax, all_data, key, title, ylabel, smooth_w=15, pct=False):
    ax.set_title(title, fontsize=10, fontweight="bold")
    ax.set_xlabel("Steps", fontsize=8)
    ax.set_ylabel("%" if pct else ylabel, fontsize=8)
    ax.tick_params(labelsize=7)
    ax.grid(True, alpha=0.3)

    has_data = False
    for bname, cfg in BEHAVIORS.items():
        data = all_data.get(bname, {})
        series = data.get(key)
        if series is None or len(series["values"]) == 0:
            continue
        steps  = series["steps"]
        vals   = series["values"] * (100 if pct else 1)
        smoothed = smooth(vals, smooth_w)
        ax.plot(steps, smoothed, color=cfg["color"], label=cfg["label"],
                linewidth=1.5, alpha=0.9)
        has_data = True

    if has_data:
        ax.legend(fontsize=7)
    else:
        ax.text(0.5, 0.5, "Noch keine Daten", transform=ax.transAxes,
                ha="center", va="center", color="gray", fontsize=9)


# â”€â”€ PDF erzeugen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

def generate_pdf():
    now       = datetime.datetime.now()
    timestamp = now.strftime("%Y-%m-%d_%H-%M-%S")
    pdf_path  = REPORTS_DIR / f"report_{timestamp}.pdf"

    print(f"[Report] Lade TensorBoard-Daten aus: {RESULTS_DIR}")
    all_data = {bname: load_scalars(bname) for bname in BEHAVIORS}

    # Pruefe ob ueberhaupt Daten vorhanden
    total_events = sum(len(d) for d in all_data.values())
    if total_events == 0:
        print("[Report] Keine TensorBoard-Daten gefunden. Training laeuft noch nicht?")
        print(f"         Erwartetes Verzeichnis: {RESULTS_DIR}")
        return None

    runtime = training_duration(all_data)
    print(f"[Report] Trainingsdauer: {runtime}  â€”  Erstelle {pdf_path.name} ...")

    with PdfPages(str(pdf_path)) as pdf:

        # â”€â”€ Seite 1: Titelseite + 5-Minuten-Zusammenfassung â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        fig = plt.figure(figsize=(11.69, 8.27))   # A4 quer
        fig.patch.set_facecolor("#f8f9fa")
        gs  = gridspec.GridSpec(3, 1, figure=fig,
                                top=0.92, bottom=0.05, left=0.06, right=0.97,
                                hspace=0.6)

        # Titel
        fig.text(0.5, 0.97,
                 f"Training Report â€” {now.strftime('%d.%m.%Y %H:%M:%S')}",
                 ha="center", va="top", fontsize=16, fontweight="bold", color="#2c3e50")
        fig.text(0.5, 0.94,
                 f"Laufzeit: {runtime}   |   Run-ID: model_comparison_v2   |   Fenster: letzte 5 Minuten",
                 ha="center", va="top", fontsize=9, color="#7f8c8d")

        # Tabelle Seite 1: Zusammenfassung letzte 5 Minuten
        ax_tbl = fig.add_subplot(gs[0])
        ax_tbl.axis("off")

        col_labels = [
            "Architektur", "Steps gesamt",
            "Ã˜ Reward (5min)", "Ã˜ SuccessRate (5min)", "Ã˜ RollingSuccess (5min)",
            "Curriculum-Phase", "Ã˜ Lava-Crossings (5min)"
        ]
        rows = []
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            bkey = lambda s: f"{bname}/{s}"
            rows.append([
                cfg["label"],
                f"{total_steps(data):,}",
                fmt(recent_mean(data.get("Environment/Cumulative Reward"), WINDOW_SEC), 2),
                fmt(recent_mean(data.get(bkey("SuccessRate")),             WINDOW_SEC), 3),
                fmt(recent_mean(data.get(bkey("RollingSuccessRate")),      WINDOW_SEC), 3),
                fmt(last_value (data.get(bkey("CurriculumPhase"))),        0),
                fmt(recent_mean(data.get(bkey("LavaCrossings")),           WINDOW_SEC), 2),
            ])

        colors_rows = [[BEHAVIORS[b]["color"] + "22"] * len(col_labels)
                       for b in BEHAVIORS]
        tbl = ax_tbl.table(
            cellText=rows, colLabels=col_labels,
            cellLoc="center", loc="center",
            cellColours=colors_rows,
        )
        tbl.auto_set_font_size(False)
        tbl.set_fontsize(8)
        tbl.scale(1, 1.6)
        ax_tbl.set_title("5-Minuten-Zusammenfassung", fontsize=10, fontweight="bold", pad=4)

        # Tabelle 2: Tod-Analyse letzte 5 Minuten
        ax_death = fig.add_subplot(gs[1])
        ax_death.axis("off")

        col_labels2 = [
            "Architektur",
            "Ã˜ Tod durch Lava (5min)", "Ã˜ Tod durch Loch (5min)", "Ã˜ Tod durch Timeout (5min)",
            "Ã˜ Lava-Versuche (5min)", "Ã˜ Steps-To-Goal (5min)", "Ã˜ EpisodenlÃ¤nge (5min)"
        ]
        rows2 = []
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            bkey = lambda s: f"{bname}/{s}"
            rows2.append([
                cfg["label"],
                fmt(recent_mean(data.get(bkey("DeathByLava")),    WINDOW_SEC), 3),
                fmt(recent_mean(data.get(bkey("DeathByHole")),    WINDOW_SEC), 3),
                fmt(recent_mean(data.get(bkey("DeathByTimeout")), WINDOW_SEC), 3),
                fmt(recent_mean(data.get(bkey("LavaJumpAttempts")),WINDOW_SEC), 2),
                fmt(recent_mean(data.get(bkey("StepsToGoal")),    WINDOW_SEC), 0),
                fmt(recent_mean(data.get(bkey("EpisodeLength")),  WINDOW_SEC), 0),
            ])

        tbl2 = ax_death.table(
            cellText=rows2, colLabels=col_labels2,
            cellLoc="center", loc="center",
            cellColours=colors_rows,
        )
        tbl2.auto_set_font_size(False)
        tbl2.set_fontsize(8)
        tbl2.scale(1, 1.6)
        ax_death.set_title("Tod-Analyse & Effizienz (letzte 5 Minuten)", fontsize=10,
                            fontweight="bold", pad=4)

        # Mini-Narrative (Text-Interpretation)
        ax_narr = fig.add_subplot(gs[2])
        ax_narr.axis("off")
        lines = ["Automatische Analyse:"]
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            bkey = lambda s: f"{bname}/{s}"
            sr   = recent_mean(data.get(bkey("RollingSuccessRate")), WINDOW_SEC)
            rew  = recent_mean(data.get("Environment/Cumulative Reward"), WINDOW_SEC)
            lc   = recent_mean(data.get(bkey("LavaCrossings")), WINDOW_SEC)
            phase = last_value(data.get(bkey("CurriculumPhase")))
            if sr is None:
                lines.append(f"  {cfg['label']}: Noch keine Daten.")
                continue
            trend = "Gut" if sr > 0.3 else ("Lernend" if sr > 0.05 else "Frueh")
            lava_str = f", Lava-Ueberquerungen: {lc:.2f}" if lc else ""
            rew_str   = f"{rew:.2f}"  if rew   is not None else "?"
            phase_str = f"{int(phase)}" if phase is not None else "?"
            lines.append(
                f"  {cfg['label']}: Phase={phase_str} | "
                f"Rolling-Success={sr:.1%} | Ã˜ Reward={rew_str} | "
                f"Status={trend}{lava_str}"
            )
        ax_narr.text(0.01, 0.95, "\n".join(lines), transform=ax_narr.transAxes,
                     va="top", fontsize=8, family="monospace",
                     bbox=dict(boxstyle="round", facecolor="#ecf0f1", alpha=0.7))

        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)

        # â”€â”€ Seite 2: Reward + SuccessRate Charts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        fig2, axes2 = plt.subplots(2, 2, figsize=(11.69, 8.27))
        fig2.patch.set_facecolor("#f8f9fa")
        fig2.suptitle("Reward & Lernfortschritt", fontsize=13, fontweight="bold", y=0.98)

        plot_metric(axes2[0, 0], all_data,
                    "Environment/Cumulative Reward",
                    "Ã˜ Cumulative Reward", "Reward", smooth_w=20)

        plot_metric(axes2[0, 1], all_data,
                    "LSTM_Navigator/RollingSuccessRate",
                    "Rolling Success Rate (LSTM)", "Rate", pct=True)
        # Alle drei in einem Chart zusammen (manuell)
        ax_sr = axes2[0, 1]
        ax_sr.set_title("Rolling Success Rate (%)", fontsize=10, fontweight="bold")
        ax_sr.clear()
        ax_sr.set_xlabel("Steps", fontsize=8)
        ax_sr.set_ylabel("%", fontsize=8)
        ax_sr.tick_params(labelsize=7)
        ax_sr.grid(True, alpha=0.3)
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            key  = f"{bname}/RollingSuccessRate"
            s    = data.get(key)
            if s and len(s["values"]) > 0:
                ax_sr.plot(s["steps"], smooth(s["values"] * 100, 15),
                           color=cfg["color"], label=cfg["label"], linewidth=1.5)
        ax_sr.legend(fontsize=7)

        plot_metric(axes2[1, 0], all_data,
                    "LSTM_Navigator/CurriculumPhase",
                    "Curriculum Phase", "Phase")
        ax_ph = axes2[1, 0]
        ax_ph.clear()
        ax_ph.set_title("Curriculum Phase", fontsize=10, fontweight="bold")
        ax_ph.set_xlabel("Steps", fontsize=8)
        ax_ph.set_ylabel("Phase", fontsize=8)
        ax_ph.tick_params(labelsize=7)
        ax_ph.grid(True, alpha=0.3)
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            s    = data.get(f"{bname}/CurriculumPhase")
            if s and len(s["values"]) > 0:
                ax_ph.step(s["steps"], s["values"], color=cfg["color"],
                           label=cfg["label"], linewidth=1.5, where="post")
        ax_ph.legend(fontsize=7)
        ax_ph.yaxis.get_major_locator().set_params(integer=True)

        # Episode Length
        ax_el = axes2[1, 1]
        ax_el.set_title("Ã˜ Episode Length", fontsize=10, fontweight="bold")
        ax_el.set_xlabel("Steps", fontsize=8)
        ax_el.set_ylabel("Steps", fontsize=8)
        ax_el.tick_params(labelsize=7)
        ax_el.grid(True, alpha=0.3)
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            s    = data.get("Environment/Episode Length")
            if s and len(s["values"]) > 0:
                ax_el.plot(s["steps"], smooth(s["values"], 20),
                           color=cfg["color"], label=cfg["label"], linewidth=1.5)
        ax_el.legend(fontsize=7)

        fig2.tight_layout(rect=[0, 0, 1, 0.96])
        pdf.savefig(fig2, bbox_inches="tight")
        plt.close(fig2)

        # â”€â”€ Seite 3: Lava-Verhalten + Loss Charts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        fig3, axes3 = plt.subplots(2, 2, figsize=(11.69, 8.27))
        fig3.patch.set_facecolor("#f8f9fa")
        fig3.suptitle("Lava-Verhalten & Lernkurven", fontsize=13, fontweight="bold", y=0.98)

        # Lava Crossings
        ax_lc = axes3[0, 0]
        ax_lc.set_title("Lava-Ueberquerungen pro Episode", fontsize=10, fontweight="bold")
        ax_lc.set_xlabel("Steps", fontsize=8)
        ax_lc.set_ylabel("Ueberquerungen", fontsize=8)
        ax_lc.tick_params(labelsize=7)
        ax_lc.grid(True, alpha=0.3)
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            s    = data.get(f"{bname}/LavaCrossings")
            if s and len(s["values"]) > 0:
                ax_lc.plot(s["steps"], smooth(s["values"], 15),
                           color=cfg["color"], label=cfg["label"], linewidth=1.5)
        ax_lc.legend(fontsize=7)

        # Todesursachen (letzter bekannter Wert als Balken)
        ax_death2 = axes3[0, 1]
        ax_death2.set_title("Todesursachen (letzte 5 Min, Ã˜ pro Episode)", fontsize=10, fontweight="bold")
        ax_death2.tick_params(labelsize=7)
        ax_death2.grid(True, alpha=0.3, axis="y")
        width    = 0.25
        x_pos    = np.arange(3)
        labels_d = ["Lava", "Loch", "Timeout"]
        for i, (bname, cfg) in enumerate(BEHAVIORS.items()):
            data = all_data.get(bname, {})
            vals = [
                recent_mean(data.get(f"{bname}/DeathByLava"),    WINDOW_SEC) or 0,
                recent_mean(data.get(f"{bname}/DeathByHole"),    WINDOW_SEC) or 0,
                recent_mean(data.get(f"{bname}/DeathByTimeout"), WINDOW_SEC) or 0,
            ]
            ax_death2.bar(x_pos + i * width, vals, width,
                          label=cfg["label"], color=cfg["color"], alpha=0.8)
        ax_death2.set_xticks(x_pos + width)
        ax_death2.set_xticklabels(labels_d, fontsize=8)
        ax_death2.legend(fontsize=7)

        # Policy Loss
        ax_pl = axes3[1, 0]
        ax_pl.set_title("Policy Loss", fontsize=10, fontweight="bold")
        ax_pl.set_xlabel("Steps", fontsize=8)
        ax_pl.set_ylabel("Loss", fontsize=8)
        ax_pl.tick_params(labelsize=7)
        ax_pl.grid(True, alpha=0.3)
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            s    = data.get("Losses/Policy Loss")
            if s and len(s["values"]) > 0:
                ax_pl.plot(s["steps"], smooth(np.abs(s["values"]), 20),
                           color=cfg["color"], label=cfg["label"], linewidth=1.5)
        ax_pl.legend(fontsize=7)

        # Entropy
        ax_ent = axes3[1, 1]
        ax_ent.set_title("Policy Entropy (Exploration)", fontsize=10, fontweight="bold")
        ax_ent.set_xlabel("Steps", fontsize=8)
        ax_ent.set_ylabel("Entropy", fontsize=8)
        ax_ent.tick_params(labelsize=7)
        ax_ent.grid(True, alpha=0.3)
        for bname, cfg in BEHAVIORS.items():
            data = all_data.get(bname, {})
            s    = data.get("Policy/Entropy")
            if s and len(s["values"]) > 0:
                ax_ent.plot(s["steps"], smooth(s["values"], 20),
                            color=cfg["color"], label=cfg["label"], linewidth=1.5)
        ax_ent.legend(fontsize=7)

        fig3.tight_layout(rect=[0, 0, 1, 0.96])
        pdf.savefig(fig3, bbox_inches="tight")
        plt.close(fig3)

        # Metadaten im PDF
        d = pdf.infodict()
        d["Title"]   = f"Training Report {now.strftime('%Y-%m-%d %H:%M')}"
        d["Author"]  = "KI_Agenten AutoReport"
        d["Subject"] = "LSTM vs Transformer vs MLP â€” Labyrinth Navigation"

    print(f"[Report] PDF gespeichert: {pdf_path}")
    return pdf_path


if __name__ == "__main__":
    result = generate_pdf()
    if result is None:
        sys.exit(1)
