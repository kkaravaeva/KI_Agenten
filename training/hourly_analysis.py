# -*- coding: utf-8 -*-
"""Stündliche Trainingsanalyse (final) - erstellt 6-seitige PDF in Analyse/final."""
import glob
import time
import datetime
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.ticker as ticker

try:
    from tensorboard.backend.event_processing.event_accumulator import EventAccumulator
except ImportError:
    raise SystemExit("tensorboard nicht installiert")

PROJECT_DIR = Path(__file__).parent.parent
RUN_ID      = "model_comparison_final_v3"
RESULTS_DIR = PROJECT_DIR / "results" / RUN_ID
ANALYSE_DIR = PROJECT_DIR / "Analyse" / "final_v3"
ANALYSE_DIR.mkdir(parents=True, exist_ok=True)

BEHAVIORS = ["LSTM_Navigator", "Transformer_Navigator", "MLP_Navigator"]
COLORS    = {"LSTM_Navigator": "#3498db", "Transformer_Navigator": "#e67e22", "MLP_Navigator": "#2ecc71"}
LABELS    = {"LSTM_Navigator": "LSTM",    "Transformer_Navigator": "Transformer", "MLP_Navigator": "MLP"}
MAX_STEPS = 30_000_000


def load_all_scalars(behavior):
    bdir  = RESULTS_DIR / behavior
    files = sorted(glob.glob(str(bdir / "*.tfevents*")))
    merged = {}
    for f in files:
        ea = EventAccumulator(f)
        ea.Reload()
        for tag in ea.Tags().get("scalars", []):
            events = ea.Scalars(tag)
            if not events:
                continue
            existing = merged.get(tag, [])
            last_t   = existing[-1].wall_time if existing else 0
            merged[tag] = existing + [e for e in events if e.wall_time > last_t]
    return merged


def to_arrays(events):
    if not events:
        return np.array([]), np.array([])
    return (np.array([e.step  for e in events], dtype=float),
            np.array([e.value for e in events], dtype=float))


def smooth(v, w=15):
    if len(v) < w:
        return v
    return np.convolve(v, np.ones(w) / w, mode="same")


def last_val(data, tag):
    ev = data.get(tag, [])
    return ev[-1].value if ev else None


def peak_val(data, tag):
    ev = data.get(tag, [])
    return max(e.value for e in ev) if ev else None


def sum_val(data, tag):
    ev = data.get(tag, [])
    return sum(e.value for e in ev) if ev else None


def fmt_dur(sec):
    return f"{int(sec//3600)}h {int((sec%3600)//60):02d}m"


def style_ax(ax):
    ax.set_facecolor("#12122a")
    ax.tick_params(colors="#888899", labelsize=8)
    for sp in ax.spines.values():
        sp.set_color("#333355")
    ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f"{x/1e6:.1f}M"))
    ax.grid(color="#2a2a4a", linewidth=0.5)
    ax.set_xlabel("Steps", color="#aaaacc", fontsize=8)


def plot_metric(ax, all_data, tag_suffix, per_behavior=True, transform=None, do_smooth=True, step_plot=False):
    for b in BEHAVIORS:
        tag = (b + "/" + tag_suffix) if per_behavior else tag_suffix
        ev = all_data[b].get(tag, [])
        if not ev:
            continue
        st, vl = to_arrays(ev)
        if transform:
            vl = transform(vl)
        plotted = smooth(vl) if do_smooth else vl
        if step_plot:
            ax.step(st, plotted, color=COLORS[b], label=LABELS[b], linewidth=1.8, where="post")
        else:
            ax.plot(st, plotted, color=COLORS[b], label=LABELS[b], linewidth=1.8)
        if not per_behavior:
            break  # geteilte Metrik: einmal reicht
    style_ax(ax)
    ax.legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=8)


# ── Seite 1: Zusammenfassung ───────────────────────────────────────────────────
def page_summary(pdf, all_data, runtime_str, timestamp):
    fig = plt.figure(figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")

    fig.text(0.5, 0.96, "KI-Agenten Trainingsanalyse - Modellvergleich (final)",
             ha="center", fontsize=18, fontweight="bold", color="white")
    fig.text(0.5, 0.92,
             f"Stand: {timestamp.replace('_', ' ')}  |  Laufzeit: {runtime_str}  |  Run: {RUN_ID}",
             ha="center", fontsize=10, color="#aaaaaa")

    col_labels = ["Metrik", "LSTM", "Transformer", "MLP"]
    col_colors = ["#2d2d4e", "#1a4a7a", "#7a4a1a", "#1a6a3a"]

    rows = []
    for b in BEHAVIORS:
        ev  = all_data[b].get("Environment/Cumulative Reward", [])
        s   = ev[-1].step if ev else 0
        rows.append({
            "steps":   s,
            "pct":     s / MAX_STEPS * 100,
            "reward":  last_val(all_data[b], "Environment/Cumulative Reward"),
            "phase":   last_val(all_data[b], f"{b}/CurriculumPhase"),
            "rsucc":   last_val(all_data[b], f"{b}/RollingSuccessRate"),
            "bsucc":   peak_val(all_data[b], f"{b}/RollingSuccessRate"),
            "cross":   sum_val(all_data[b],  f"{b}/LavaCrossings"),
            "attempt": last_val(all_data[b], f"{b}/LavaJumpAttempts"),
            "jumps":   last_val(all_data[b], f"{b}/JumpsPerEpisode"),
            "dlava":   last_val(all_data[b], f"{b}/DeathByLava"),
            "dtime":   last_val(all_data[b], f"{b}/DeathByTimeout"),
            "gate":    last_val(all_data[b], "Curriculum/GateSuccessRate"),
            "epph":    last_val(all_data[b], "Curriculum/EpisodeInPhase"),
        })

    def fmt(v, kind):
        if v is None:
            return "N/A"
        if kind == "int":
            return f"{int(v):,}"
        if kind == "pct":
            return f"{v:.1%}"
        return f"{v:.3f}"

    metrics = [
        ("Steps",                  lambda r: fmt(r["steps"], "int")),
        ("Fortschritt",            lambda r: f"{r['pct']:.2f}%"),
        ("Reward (aktuell)",       lambda r: fmt(r["reward"], "f")),
        ("Curriculum Phase",       lambda r: fmt(r["phase"], "int") if r["phase"] is not None else "N/A"),
        ("Episode in Phase",       lambda r: fmt(r["epph"], "int") if r["epph"] is not None else "N/A"),
        ("Gate-SuccessRate",       lambda r: fmt(r["gate"], "pct")),
        ("Rolling Success",        lambda r: fmt(r["rsucc"], "pct")),
        ("Beste Success",          lambda r: fmt(r["bsucc"], "pct")),
        ("Lava-Crossings (Summe)", lambda r: fmt(r["cross"], "f")),
        ("Lava-Sprungversuche",    lambda r: fmt(r["attempt"], "f")),
        ("Sprünge/Episode",        lambda r: fmt(r["jumps"], "f")),
        ("Tod: Lava",              lambda r: fmt(r["dlava"], "pct")),
        ("Tod: Timeout",           lambda r: fmt(r["dtime"], "pct")),
    ]
    table_data = [[m[0]] + [m[1](rows[i]) for i in range(3)] for m in metrics]

    ax = fig.add_axes([0.05, 0.08, 0.90, 0.78])
    ax.axis("off")
    tbl = ax.table(cellText=table_data, colLabels=col_labels, cellLoc="center", loc="center")
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(10)
    tbl.scale(1, 1.8)

    for (row, col), cell in tbl.get_celld().items():
        cell.set_edgecolor("#444466")
        if row == 0:
            cell.set_facecolor(col_colors[col] if col < len(col_colors) else "#2d2d4e")
            cell.set_text_props(color="white", fontweight="bold")
        elif col == 0:
            cell.set_facecolor("#2a2a3e")
            cell.set_text_props(color="#ccccee")
        else:
            cell.set_facecolor("#1e1e30" if row % 2 == 0 else "#252540")
            cell.set_text_props(color="white")

    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 2: Reward & Erfolgsrate ─────────────────────────────────────────────
def page_reward_success(pdf, all_data):
    fig, axes = plt.subplots(2, 1, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Reward & Erfolgsrate", color="white", fontsize=14, fontweight="bold", y=0.98)

    for b in BEHAVIORS:
        ev = all_data[b].get("Environment/Cumulative Reward", [])
        if ev:
            st, vl = to_arrays(ev)
            axes[0].plot(st, smooth(vl), color=COLORS[b], label=LABELS[b], linewidth=1.8)
        ev = all_data[b].get(f"{b}/RollingSuccessRate", [])
        if ev:
            st, vl = to_arrays(ev)
            axes[1].plot(st, smooth(vl * 100), color=COLORS[b], label=LABELS[b], linewidth=1.8)

    for ax, title, ylabel in zip(axes, ["Kumulativer Reward", "Rolling Success Rate (%)"], ["Reward", "Erfolg [%]"]):
        style_ax(ax)
        ax.set_title(title, color="#ccccee", fontsize=11)
        ax.set_ylabel(ylabel, color="#aaaacc", fontsize=9)
        ax.legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=9)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 3: Curriculum & Todesursachen ───────────────────────────────────────
def page_curriculum_deaths(pdf, all_data):
    fig, axes = plt.subplots(2, 2, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Curriculum & Todesursachen", color="white", fontsize=14, fontweight="bold", y=0.98)
    axs = axes.flatten()

    plot_metric(axs[0], all_data, "CurriculumPhase", do_smooth=False, step_plot=True)
    axs[0].set_title("Curriculum Phase", color="#ccccee", fontsize=10)

    plot_metric(axs[1], all_data, "Curriculum/GateSuccessRate", per_behavior=False,
                transform=lambda v: v * 100)
    axs[1].set_title("Gate-SuccessRate [%] (geteilt)", color="#ccccee", fontsize=10)

    plot_metric(axs[2], all_data, "DeathByTimeout", transform=lambda v: v * 100)
    axs[2].set_title("Tod durch Timeout [%]", color="#ccccee", fontsize=10)

    plot_metric(axs[3], all_data, "DeathByLava", transform=lambda v: v * 100)
    axs[3].set_title("Tod durch Lava [%]", color="#ccccee", fontsize=10)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 4: Lava-Fokus (Kernfrage der Arbeit) ────────────────────────────────
def page_lava(pdf, all_data):
    fig, axes = plt.subplots(2, 2, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Lava-Fokus: Lernt der Agent den Sprung?", color="white", fontsize=14, fontweight="bold", y=0.98)
    axs = axes.flatten()

    plot_metric(axs[0], all_data, "LavaJumpAttempts")
    axs[0].set_title("Lava-Sprungversuche / Episode", color="#ccccee", fontsize=10)

    plot_metric(axs[1], all_data, "LavaCrossings")
    axs[1].set_title("Erfolgreiche Überquerungen / Episode", color="#ccccee", fontsize=10)

    plot_metric(axs[2], all_data, "JumpsPerEpisode")
    axs[2].set_title("Sprünge gesamt / Episode", color="#ccccee", fontsize=10)

    plot_metric(axs[3], all_data, "EndDistanceToGoal")
    axs[3].set_title("Distanz zum Ziel bei Episodenende", color="#ccccee", fontsize=10)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 5: Reward-Zerlegung (Shaping-Diagnose) ──────────────────────────────
def page_shaping(pdf, all_data):
    fig, axes = plt.subplots(2, 2, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Reward-Zerlegung: Woher kommt der Reward?", color="white", fontsize=14, fontweight="bold", y=0.98)
    axs = axes.flatten()

    plot_metric(axs[0], all_data, "PBRSRewardSum")
    axs[0].set_title("PBRS-Shaping-Summe / Episode", color="#ccccee", fontsize=10)

    plot_metric(axs[1], all_data, "LineOfSightRewardSum")
    axs[1].set_title("Line-of-Sight-Reward-Summe / Episode", color="#ccccee", fontsize=10)

    for b in BEHAVIORS:
        ev = all_data[b].get("Policy/Curiosity Reward", [])
        if ev:
            st, vl = to_arrays(ev)
            axs[2].plot(st, smooth(vl), color=COLORS[b], label=LABELS[b], linewidth=1.8)
    style_ax(axs[2])
    axs[2].set_title("Curiosity Reward", color="#ccccee", fontsize=10)
    axs[2].legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=8)

    plot_metric(axs[3], all_data, "DistanceProgress", transform=lambda v: v * 100)
    axs[3].set_title("Distanz-Fortschritt [%] (Start→Ende)", color="#ccccee", fontsize=10)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 6: Policy-Metriken ──────────────────────────────────────────────────
def page_policy(pdf, all_data):
    fig, axes = plt.subplots(2, 2, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Policy-Metriken", color="white", fontsize=14, fontweight="bold", y=0.98)
    axs = axes.flatten()

    tags = [("Losses/Policy Loss", "Policy Loss"),
            ("Losses/Value Loss", "Value Loss"),
            ("Policy/Entropy", "Entropy"),
            ("Policy/Learning Rate", "Learning Rate")]

    for ax, (tag, title) in zip(axs, tags):
        for b in BEHAVIORS:
            ev = all_data[b].get(tag, [])
            if ev:
                st, vl = to_arrays(ev)
                ax.plot(st, smooth(vl), color=COLORS[b], label=LABELS[b], linewidth=1.8)
        style_ax(ax)
        ax.set_title(title, color="#ccccee", fontsize=10)
        ax.legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=8)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Hauptfunktion ──────────────────────────────────────────────────────────────
def create_analysis():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M")
    pdf_path  = ANALYSE_DIR / f"report_{timestamp}.pdf"
    all_data  = {b: load_all_scalars(b) for b in BEHAVIORS}

    t_start = t_end = None
    for b in BEHAVIORS:
        ev = all_data[b].get("Environment/Cumulative Reward", [])
        if ev:
            if t_start is None or ev[0].wall_time < t_start: t_start = ev[0].wall_time
            if t_end   is None or ev[-1].wall_time > t_end:  t_end   = ev[-1].wall_time
    runtime_str = fmt_dur(t_end - t_start) if (t_start and t_end) else "0h 00m"

    with PdfPages(str(pdf_path)) as pdf:
        page_summary(pdf, all_data, runtime_str, timestamp)
        page_reward_success(pdf, all_data)
        page_curriculum_deaths(pdf, all_data)
        page_lava(pdf, all_data)
        page_shaping(pdf, all_data)
        page_policy(pdf, all_data)

    return pdf_path


if __name__ == "__main__":
    print(f"Hourly Analysis gestartet -> {ANALYSE_DIR}")
    i = 0
    while True:
        i += 1
        try:
            p = create_analysis()
            print(f"[{time.strftime('%H:%M:%S')}] #{i}: {p.name}")
        except Exception as e:
            print(f"[{time.strftime('%H:%M:%S')}] Fehler: {e}")
        time.sleep(3600)
