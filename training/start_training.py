"""
Startet ein mlagents-Training im KI_Agenten-Projekt.

Verwendung:
    python training/start_training.py [--run-id=<name>] [--resume] [--force] [--no-patch]

Standardmäßig:
    Config:   config/labyrinth_transformer.yaml
    Run-ID:   transformer_v5
    Venv:     C:/Users/Finnl/mlagents-31008

Beispiele:
    python training/start_training.py
    python training/start_training.py --run-id=transformer_v5 --resume
    python training/start_training.py --run-id=transformer_v5 --force
"""

import subprocess
import sys
import os
from pathlib import Path

# ── Konfiguration ──────────────────────────────────────────────────────────────

VENV        = Path(r"C:\Users\Finnl\mlagents-31008")
PYTHON      = VENV / "Scripts" / "python.exe"
PROJECT_DIR = Path(__file__).parent.parent   # KI_Agenten/
CONFIG      = "config/labyrinth_transformer.yaml"
DEFAULT_RUN = "transformer_v5"

# ── Argumente parsen ───────────────────────────────────────────────────────────

args = sys.argv[1:]
run_id  = next((a.split("=", 1)[1] for a in args if a.startswith("--run-id=")), DEFAULT_RUN)
resume  = "--resume" in args
force   = "--force" in args
no_patch = "--no-patch" in args

# ── Patch anwenden (einmalig nötig) ───────────────────────────────────────────

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
    CONFIG,
    f"--run-id={run_id}",
]
if resume:
    cmd.append("--resume")
if force:
    cmd.append("--force")

print(f"=== Training starten ===")
print(f"  Config:  {CONFIG}")
print(f"  Run-ID:  {run_id}")
print(f"  Flags:   {'--resume' if resume else '--force' if force else '(keine)'}")
print(f"  Venv:    {VENV}")
print()
print("Warte auf Unity: Wenn 'Listening on port 5004' erscheint -> Play in Unity druecken.")
print("-" * 70)

os.chdir(PROJECT_DIR)
subprocess.run(cmd)
