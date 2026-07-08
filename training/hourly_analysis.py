# -*- coding: utf-8 -*-
"""Stündliche Trainingsanalyse - erstellt 4-seitige PDF in Analyse/."""
import glob
import os
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
RESULTS_DIR = PROJECT_DIR / "results" / "model_comparison_v4"
ANALYSE_DIR = PROJECT_DIR / "Analyse" / "v4"
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
        return np.array([]), np.array([]), np.array([])
    return (np.array([e.step      for e in events], dtype=float),
            np.array([e.value     for e in events], dtype=float),
            np.array([e.wall_time for e in events], dtype=float))


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


# ── Seite 1: Zusammenfassung ───────────────────────────────────────────────────
def page_summary(pdf, all_data, runtime_str, timestamp):
    fig = plt.figure(figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")

    fig.text(0.5, 0.96, "KI-Agenten Trainingsanalyse - Modellvergleich",
             ha="center", fontsize=18, fontweight="bold", color="white")
    fig.text(0.5, 0.92,
             f"Stand: {timestamp.replace('_', ' ')}  |  Laufzeit: {runtime_str}  |  Run: model_comparison_v3",
             ha="center", fontsize=10, color="#aaaaaa")

    col_labels = ["Metrik", "LSTM", "Transformer", "MLP"]
    col_colors = ["#2d2d4e", "#1a4a7a", "#7a4a1a", "#1a6a3a"]

    rows = []
    for b in BEHAVIORS:
        ev  = all_data[b].get("Environment/Cumulative Reward", [])
        s   = ev[-1].step if ev else 0
        pct = s / MAX_STEPS * 100
        rows.append([
            s, pct,
            last_val(all_data[b], "Environment/Cumulative Reward"),
            last_val(all_data[b], f"{b}/CurriculumPhase"),
            last_val(all_data[b], f"{b}/RollingSuccessRate"),
            peak_val(all_data[b], f"{b}/RollingSuccessRate"),
            last_val(all_data[b], f"{b}/LavaCrossings"),
            last_val(all_data[b], f"{b}/DeathByTimeout"),
            last_val(all_data[b], f"{b}/DeathByLava"),
        ])

    metrics = [
        ("Steps",            lambda r: f"{int(r[0]):,}"),
        ("Fortschritt",      lambda r: f"{r[1]:.2f}%"),
        ("Reward (aktuell)", lambda r: f"{r[2]:.3f}" if r[2] is not None else "N/A"),
        ("Curriculum Phase", lambda r: str(int(r[3])) if r[3] is not None else "N/A"),
        ("Rolling Success",  lambda r: f"{r[4]:.1%}" if r[4] is not None else "N/A"),
        ("Beste Success",    lambda r: f"{r[5]:.1%}" if r[5] is not None else "N/A"),
        ("Lava-Crossings",   lambda r: f"{r[6]:.3f}" if r[6] is not None else "N/A"),
        ("Tod: Timeout",     lambda r: f"{r[7]:.1%}" if r[7] is not None else "N/A"),
        ("Tod: Lava",        lambda r: f"{r[8]:.1%}" if r[8] is not None else "N/A"),
    ]
    table_data = [[m[0]] + [m[1](rows[i]) for i in range(3)] for m in metrics]

    ax = fig.add_axes([0.05, 0.12, 0.90, 0.74])
    ax.axis("off")
    tbl = ax.table(cellText=table_data, colLabels=col_labels, cellLoc="center", loc="center")
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(11)
    tbl.scale(1, 2.2)

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


# ── Seite 2: Reward & Success ─────────────────────────────────────────────────
def page_reward_success(pdf, all_data):
    fig, axes = plt.subplots(2, 1, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Reward & Erfolgsrate", color="white", fontsize=14, fontweight="bold", y=0.98)

    for b in BEHAVIORS:
        c, lbl = COLORS[b], LABELS[b]
        ev = all_data[b].get("Environment/Cumulative Reward", [])
        if ev:
            st, vl, _ = to_arrays(ev)
            axes[0].plot(st, smooth(vl), color=c, label=lbl, linewidth=1.8)
        ev = all_data[b].get(f"{b}/RollingSuccessRate", [])
        if ev:
            st, vl, _ = to_arrays(ev)
            axes[1].plot(st, smooth(vl * 100), color=c, label=lbl, linewidth=1.8)

    for ax, title, ylabel in zip(axes, ["Kumulativer Reward", "Rolling Success Rate (%)"], ["Reward", "Erfolg [%]"]):
        style_ax(ax)
        ax.set_title(title, color="#ccccee", fontsize=11)
        ax.set_ylabel(ylabel, color="#aaaacc", fontsize=9)
        ax.legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=9)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 3: Curriculum & Tode ────────────────────────────────────────────────
def page_curriculum_deaths(pdf, all_data):
    fig, axes = plt.subplots(2, 2, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Curriculum & Todesursachen", color="white", fontsize=14, fontweight="bold", y=0.98)
    axs = axes.flatten()

    plots = [
        (f"{b}/CurriculumPhase",  "Curriculum Phase",         lambda v: v,     False),
        (f"{b}/LavaCrossings",    "Lava-Crossings/Episode",   lambda v: v,     True),
        (f"{b}/DeathByTimeout",   "Tod durch Timeout [%]",    lambda v: v*100, True),
        (f"{b}/DeathByLava",      "Tod durch Lava [%]",       lambda v: v*100, True),
    ]

    for i, (tag_tmpl, title, transform, do_smooth) in enumerate(plots):
        for b in BEHAVIORS:
            tag = tag_tmpl.replace(f"{b}/", f"{b}/") if "{b}" not in tag_tmpl else tag_tmpl.replace("{b}", b)
            # handle the template
            real_tag = tag_tmpl.replace("f\"{b}/", "").replace("{b}/", b + "/") if "{b}" in tag_tmpl else tag_tmpl
            real_tag = f"{b}/" + tag_tmpl.split("/", 1)[1] if "/" in tag_tmpl else tag_tmpl
            ev = all_data[b].get(real_tag, [])
            if not ev:
                continue
            st, vl, _ = to_arrays(ev)
            vl = transform(vl)
            plotted = smooth(vl) if do_smooth else vl
            if i == 0:
                axs[i].step(st, plotted, color=COLORS[b], label=LABELS[b], linewidth=1.8, where="post")
            else:
                axs[i].plot(st, plotted, color=COLORS[b], label=LABELS[b], linewidth=1.8)
        style_ax(axs[i])
        axs[i].set_title(title, color="#ccccee", fontsize=10)
        axs[i].legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=8)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Seite 4: Policy ────────────────────────────────────────────────────────────
def page_policy(pdf, all_data):
    fig, axes = plt.subplots(1, 2, figsize=(11.69, 8.27))
    fig.patch.set_facecolor("#1a1a2e")
    fig.suptitle("Policy-Metriken", color="white", fontsize=14, fontweight="bold", y=0.98)

    for b in BEHAVIORS:
        c, lbl = COLORS[b], LABELS[b]
        for ax, tag in zip(axes, ["Policy/Policy Loss", "Policy/Entropy"]):
            ev = all_data[b].get(tag, [])
            if ev:
                st, vl, _ = to_arrays(ev)
                ax.plot(st, smooth(vl), color=c, label=lbl, linewidth=1.8)

    for ax, title in zip(axes, ["Policy Loss", "Entropy"]):
        style_ax(ax)
        ax.set_title(title, color="#ccccee", fontsize=11)
        ax.legend(facecolor="#1e1e30", edgecolor="#444466", labelcolor="white", fontsize=9)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    pdf.savefig(fig, facecolor=fig.get_facecolor())
    plt.close(fig)


# ── Hauptfunktion ──────────────────────────────────────────────────────────────
def create_analysis():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M")
    pdf_path  = ANALYSE_DIR / f"analyse_{timestamp}.pdf"
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
