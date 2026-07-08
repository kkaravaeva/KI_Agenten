"""Runs generate_report.py every 5 minutes in an infinite loop."""
import time
import subprocess
import sys
from pathlib import Path

INTERVAL = 300
script = Path(__file__).parent / "generate_report.py"

print(f"Auto-Report gestartet. Erstelle alle {INTERVAL}s eine PDF.")
print(f"Script: {script}")
print("Stoppen: Fenster schliessen oder Strg+C\n")

iteration = 0
while True:
    iteration += 1
    print(f"\n[{time.strftime('%H:%M:%S')}] Report #{iteration} wird erstellt...")
    result = subprocess.run([sys.executable, str(script)], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if "[Report]" in line:
            print(line)
    for line in result.stderr.splitlines():
        if "[Report]" in line:
            print(line)
    print(f"[{time.strftime('%H:%M:%S')}] Naechster Report in {INTERVAL}s...")
    time.sleep(INTERVAL)
