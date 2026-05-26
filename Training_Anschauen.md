# Transformer-Training in Unity live anschauen (Inference-Mode)

Diese Anleitung erklärt, wie ein abgeschlossenes Transformer-Training visuell im Unity-Editor inspiziert wird, um das gelernte Verhalten (Lava-Sprünge, Navigation, Ziel-Erreichung) zu beobachten.

> **Pendant zu `Training_Starten.md`** — dort wird das Trainieren erklärt, hier das Anschauen einer fertig trainierten Policy.

---

## Warum nicht einfach ONNX in Unity laden?

Bei MLP-Baselines (z.B. `mlp_baseline_v2_final.onnx`) reicht es, die ONNX-Datei auf das Agent-Prefab zu ziehen und `BehaviorType = InferenceOnly` zu setzen. Das funktioniert **bei dieser Transformer-Implementierung nicht**, weil:

1. Die Transformer-Memory ist nicht Teil der Standard-ML-Agents-API. Sie ist als Custom-Patch im venv installiert (`mlagents-31008/Lib/site-packages/mlagents/trainers/torch_entities/transformer_memory.py`).
2. PyTorch 2.0.1 hat bekannte ONNX-Export-Bugs bei `nn.MultiheadAttention` und `aten::unflatten`. Die Export-Skripte `export_onnx.py` / `export_onnx_standalone.py` umgehen das mit Custom Symbolics, erzeugen aber **kein ML-Agents-konformes ONNX** (Inputs heißen `input` statt `obs_0, obs_1, action_masks`).
3. Barracuda 2.0.0 (in `Packages/`) unterstützt die Transformer-Ops in der nötigen Form nicht zuverlässig.

**Konsequenz:** Inferenz muss in Python passieren. ML-Agents liefert dafür den `--inference`-Modus — der Python-Trainer lädt den Checkpoint und schickt nur noch die Aktionen an Unity, ohne die Gewichte zu verändern. Unity und Python kommunizieren wie beim Training über Port 5004.

---

## Voraussetzungen

- Python-Venv unter `C:\Users\Finnl\mlagents-31008` aktiv (siehe `Training_Starten.md`)
- Transformer-Patch im Venv angewendet (`python training/patch_mlagents.py` — beim Training automatisch durch `start_training.py`)
- Unity-Projekt `KI_Agenten` mit Szene `Assets/Scenes/Transformer_Test_V2.unity`
- Ein abgeschlossener oder laufender Trainings-Run unter `results/<run-id>/`

---

## Schritt 1 — Training-Snapshot anlegen

Damit Inference einen stabilen, eingefrorenen Stand benutzt (und nicht einen Checkpoint, der gerade vom laufenden Trainer überschrieben wird), wird ein Snapshot kopiert.

```powershell
# Beispiel: v21 wird als v21_snapshot eingefroren
$src = "C:\Users\Finnl\KI_Agenten\results\v21\LabyrinthNavigator"
$dst = "C:\Users\Finnl\KI_Agenten\results\v21_snapshot\LabyrinthNavigator"
New-Item -ItemType Directory -Path $dst -Force | Out-Null
robocopy $src $dst /E /R:2 /W:2 /NFL /NDL /NJH /NJS /NC /NS

# Config mitnehmen (mlagents-learn erwartet sie im Run-Ordner)
Copy-Item "C:\Users\Finnl\KI_Agenten\config\labyrinth_transformer.yaml" `
          "C:\Users\Finnl\KI_Agenten\results\v21_snapshot\configuration.yaml" -Force
```

**Was wird kopiert:**

| Datei | Zweck |
|---|---|
| `LabyrinthNavigator-<step>.pt` (Auto-Checkpoints) | Einzelne Trainings-Snapshots, alle 500k Steps |
| `checkpoint.pt` | Der zuletzt geschriebene Stand (wird von `--resume` geladen) |
| `events.out.tfevents.*` | TensorBoard-Daten (für späteren Vergleich) |
| `configuration.yaml` | Die verwendete Trainings-Config |

**Was wird NICHT kopiert:** `run_logs/Player-*.log` (Episode-Logs aus dem headless Build — typischerweise 2-3 GB, für Inference nicht nötig).

**Bei laufendem Training:** Robocopy verträgt sich mit dem Schreibvorgang. Einzige Files, die der Trainer aktiv beschreibt:
- `checkpoint.pt` — alle 500k Steps neu geschrieben
- `events.out.tfevents.*` — alle 20k Steps (`summary_freq`) ergänzt

Die einzelnen `LabyrinthNavigator-<step>.pt`-Dateien sind nach dem Schreiben unveränderlich.

---

## Schritt 2 — Spezifischen Checkpoint wählen (optional)

`--resume` lädt automatisch den letzten Stand (`checkpoint.pt`). Wenn du einen **bestimmten** Step inspizieren willst (z.B. um den Reward-Hacking-Verdacht aus 22.5M Steps zu prüfen), kopiere den gewünschten Auto-Checkpoint über `checkpoint.pt`:

```powershell
Copy-Item "C:\Users\Finnl\KI_Agenten\results\v21_snapshot\LabyrinthNavigator\LabyrinthNavigator-22499945.pt" `
          "C:\Users\Finnl\KI_Agenten\results\v21_snapshot\LabyrinthNavigator\checkpoint.pt" -Force
```

> Original-Snapshot bleibt durch das Kopieren der anderen `*.pt`-Files erhalten — `checkpoint.pt` ist nur eine Kopie für den `--resume`-Loader.

---

## Schritt 3 — Inference-Prozess starten

In einer **neuen** PowerShell oder cmd (Trainings-Terminal kann parallel laufen, weil der Editor Port 5004 nutzt, der headless Trainer 5005+):

```powershell
cd C:\Users\Finnl\KI_Agenten
C:\Users\Finnl\mlagents-31008\Scripts\python.exe -m mlagents.trainers.learn `
    config/labyrinth_transformer.yaml `
    --run-id=v21_snapshot `
    --inference `
    --resume `
    --time-scale=1
```

**Wichtige Flags:**

| Flag | Bedeutung |
|---|---|
| `--inference` | Forward-Pass only, kein Gradient-Update |
| `--resume` | Lädt `results/v21_snapshot/LabyrinthNavigator/checkpoint.pt` |
| `--time-scale=1` | Echtzeit-Wiedergabe (Default beim Training ist 20, dann sieht man nichts) |

**Was bewusst NICHT gesetzt wird:**

| Flag | Warum nicht |
|---|---|
| `--env=...` | Würde headless Build starten; wir wollen den Editor |
| `--no-graphics` | Würde die Grafik abschalten — wir wollen ja zuschauen |
| `--num-envs N` | Default ist 1; mehrere parallele Editor-Sessions geht eh nicht |
| `--force` | Verwirft Daten; wir wollen ja aus dem Snapshot lesen |

**Erwartete Ausgabe:**
```
[INFO] Listening on port 5004. Start training by pressing the Play button in the Unity Editor.
```

---

## Schritt 4 — Unity-Editor verbinden

1. Unity-Editor öffnen
2. Szene `Assets/Scenes/Transformer_Test_V2.unity` öffnen
3. **Play** drücken

Erwartete Ausgabe im Inference-Terminal:
```
[INFO] Connected to Unity environment ...
[INFO] Connected new brain: LabyrinthNavigator?team=0
```

Ab jetzt führt der Agent in der Szene seine gelernte Policy aus. Sichtbar werden:

- **Bewegung**: Welche Pfade wählt der Agent? Sucht er aktiv das Ziel oder bleibt er in sicheren Zonen?
- **Lava-Sprünge**: Setzt er bewusst zum Sprung an (Anlauf, dann Action `d[2]=1`) oder springt er zufällig?
- **Lava-Crossings**: Schafft er die Sprünge tatsächlich oder stirbt er?
- **Goal-Erreichung**: Debug-Log `[Ziel] Reached | Reward=... | LavaAtt/Succ/Fail=...` in der Unity-Console (`LabyrinthAgent.cs:677`)

---

## Schritt 5 — Beenden

1. In Unity **Stop** drücken
2. Im Inference-Terminal `Ctrl+C`

> `--inference` schreibt **keine** neuen TensorBoard-Daten. Der Snapshot bleibt unverändert.

---

## Use-Cases

### A. Reward-Hacking-Verdacht prüfen

Wenn TensorBoard zeigt: LavaCross-Reward steigt, Goal-Reward stagniert, SuccessRate sinkt — Verdacht auf Lava-Farming.

Im Inference-Mode sichtbar:
- Bleibt der Agent in der Nähe von Lava-Stellen, statt zum Goal zu laufen?
- Macht er mehrere Lava-Sprünge in derselben Episode auf demselben Stück Lava?
- Wenn er Goal sieht: läuft er hin oder dreht er ab?

### B. Vergleich zweier Trainingsstände

Zwei verschiedene Checkpoints in zwei verschiedene Snapshot-Ordner ablegen, jeweils einzeln per `--run-id=...` und `--resume` inspizieren.

### C. Curriculum-Phase fixieren

Per Inspector-Override in der `Transformer_Test_V2.unity`-Szene am `MapGenerator` die aktive Phase fixieren (statt Auto-Curriculum), um gezielt Hazard-Maps zu testen.

---

## Troubleshooting

### Port 5004 belegt

**Symptom:**
```
RuntimeError: Failed to bind to address [::]:5004
```

**Ursache:** Ein anderer Editor-Inference-Prozess läuft noch.

**Lösung:**
```powershell
Get-NetTCPConnection -LocalPort 5004 | Select-Object OwningProcess
Stop-Process -Id <PID> -Force
```

> **Nicht zu verwechseln** mit dem laufenden Training: Der headless Trainer (mit `--env=...`) nutzt Port 5005+, nicht 5004.

### Modell hat falsche Anzahl Parameter

**Symptom:**
```
RuntimeError: Error(s) in loading state_dict ... Missing key(s): ...
```

**Ursache:** Der Transformer-Patch im Venv ist nicht (mehr) angewendet, oder eine andere Config (LSTM statt Transformer) wird benutzt.

**Lösung:**
```powershell
cd C:\Users\Finnl\KI_Agenten
C:\Users\Finnl\mlagents-31008\Scripts\python.exe training/patch_mlagents.py
```

Stelle sicher, dass `--run-id` und die geladene Config konsistent zum Trainings-Setup sind (gleiche `memory_type: transformer`, gleiche `sequence_length`, `hidden_units`, `memory_size`).

### Agent steht nur rum / handelt zufällig

**Mögliche Ursachen:**

- Du hast `--inference` **ohne** `--resume`/`--initialize-from` benutzt → Policy wurde mit Zufallsgewichten initialisiert.
- Falscher `--run-id` → Snapshot wurde gar nicht geladen.
- `BehaviorType` auf dem Agent-Prefab ist `HeuristicOnly` (Tastatursteuerung) statt `Default`.

Prüfen: Im Unity-Inspector am Agent-Prefab → `BehaviorParameters` → `Behavior Type` = `Default`.

### Agent ist viel zu schnell

`--time-scale=1` vergessen. Default wäre 20 (Trainings-Geschwindigkeit).

---

## Anhang: Verzeichnisstruktur nach Snapshot

```
results/
├── v21/                                          ← laufendes/aktives Training
│   ├── LabyrinthNavigator/
│   │   ├── LabyrinthNavigator-22999913.pt
│   │   ├── LabyrinthNavigator-23499825.pt
│   │   ├── ...
│   │   ├── checkpoint.pt                          ← wird live überschrieben
│   │   └── events.out.tfevents.*
│   └── run_logs/                                  ← große Player-Logs (2.5 GB)
│
└── v21_snapshot/                                 ← eingefrorener Snapshot für Inference
    ├── configuration.yaml                         ← Kopie der Trainings-Config
    └── LabyrinthNavigator/
        ├── LabyrinthNavigator-22999913.pt        ← unveränderlich
        ├── LabyrinthNavigator-23499825.pt
        ├── ...
        ├── checkpoint.pt                          ← der Stand zum Zeitpunkt des Snapshots
        └── events.out.tfevents.*
```

---

## Quick-Start (kurze Version)

```powershell
# 1. Snapshot anlegen
robocopy "results\v21\LabyrinthNavigator" "results\v21_snapshot\LabyrinthNavigator" /E /R:2 /W:2 /NFL /NDL
Copy-Item "config\labyrinth_transformer.yaml" "results\v21_snapshot\configuration.yaml"

# 2. Optional: bestimmten Step laden
Copy-Item "results\v21_snapshot\LabyrinthNavigator\LabyrinthNavigator-22499945.pt" `
          "results\v21_snapshot\LabyrinthNavigator\checkpoint.pt" -Force

# 3. Inference starten
C:\Users\Finnl\mlagents-31008\Scripts\python.exe -m mlagents.trainers.learn `
    config/labyrinth_transformer.yaml --run-id=v21_snapshot --inference --resume --time-scale=1

# 4. Unity: Transformer_Test_V2.unity öffnen, Play drücken
```
