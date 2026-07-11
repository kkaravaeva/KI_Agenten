# Evaluations-Vorbereitung — model_comparison_final_v3

Finale Modelle des 3-Wege-Vergleichs (MLP / LSTM / Transformer) nach
**30 Mio. Steps** pro Behavior. Run abgeschlossen am **11.07.2026, ~07:42 Uhr**
(Branch `ModelTrainingComparsion`, Config `config/model_comparison_final_v3.yaml`).

## Inhalt

| Pfad | Was ist das |
|---|---|
| `onnx/MLP_Navigator.onnx` | Finales MLP, **opset 10** → in Unity/Barracuda direkt nutzbar |
| `onnx/LSTM_Navigator.onnx` | Finales LSTM, **opset 11**, mit `recurrent_in/out` → Unity/Barracuda |
| `checkpoints/*.pt` | Finale Torch-Checkpoints aller drei Behaviors (Originale) |
| `inference_setup/` | Selbständiges Python-Inference-Setup (alle drei Modelle, inkl. Transformer) |
| `export_final_models.py` | Reproduzierbarer ONNX-Export (siehe unten) |

## Transformer laufen lassen (Python-Inference)

Der Transformer lässt sich **nicht als ONNX exportieren** — das Tracing von
`nn.MultiheadAttention` schlägt fehl, und Barracuda könnte die Datei ohnehin
nicht laden (bekanntes Problem, vgl. `Transformer_v24_opset18_backup.onnx`).
Der vorgesehene Weg ist ML-Agents-Inference über Python — **getestet am
11.07.2026** (alle 3 Brains verbunden, „Not Training", Steps laufen über die
30M hinaus weiter):

**Variante A — mit Unity-Editor (zum Zuschauen/Debuggen):**
1. `inference_setup\start_inference.bat` doppelklicken
2. In Unity die Szene **Training Area** öffnen und **Play** drücken (Port 5004)

**Variante B — ohne Editor, ein Klick:**
- `inference_setup\start_inference_build.bat` doppelklicken → startet den
  Standalone-Build (`Build\KI_Agenten.exe`) sichtbar in Echtzeit (Port 5005)

In beiden Fällen laufen **alle drei Behaviors** (auch MLP und LSTM) mit ihren
finalen 30M-Gewichten, ohne Lern-Updates. Das Setup ist selbständig: Config +
`results`-Struktur mit den finalen `checkpoint.pt` liegen im Ordner, der
Launcher zeigt per `--results-dir` darauf. Benötigt die Trainings-venv
(`C:\Users\Finnl\mlagents-31008`); Variante B zusätzlich den Projekt-Build.

## ONNX in Unity verwenden

`.onnx` ins Projekt ziehen und im **Behavior Parameters**-Component als Model
zuweisen (Behavior Name muss `MLP_Navigator` bzw. `LSTM_Navigator` bleiben).
Beim LSTM verwaltet Unity die Memory über `recurrent_in/out` automatisch.

**Hinweis zur Aktionswahl:** Beim Export wurde das Sampling durch **argmax**
ersetzt (deterministische Aktionen), weil `torch.multinomial` beim ONNX-Export
segfaultet. Für Evaluationen ist deterministisches Verhalten üblich; es kann
aber minimal von den (stochastischen) TensorBoard-Trainingswerten abweichen.

## Export reproduzieren

Der Export braucht eine **eigene venv mit torch 2.1.2+cpu** (das Trainings-torch
2.0.1+cu118 crasht nativ beim ONNX-Export — deshalb ist in der Trainings-venv
auch `convert_to_onnx = False` gesetzt). Die venv liegt unter
`training\venv_mlagents` und wurde so gebaut:

```powershell
& "...\Python310\python.exe" -m venv training\venv_mlagents
training\venv_mlagents\Scripts\python -m pip install torch==2.1.2 --index-url https://download.pytorch.org/whl/cpu
# mlagents pinnt numpy 1.21.2 (kein Py3.10-Wheel) → Deps manuell, mlagents ohne Resolver:
training\venv_mlagents\Scripts\python -m pip install numpy==1.23.5 h5py pyyaml "attrs>=19.3.0" "cattrs<1.7,>=1.1.0" "grpcio>=1.11.0" protobuf==3.20.3 Pillow pypiwin32 six onnx==1.15.0
training\venv_mlagents\Scripts\python -m pip install --no-deps mlagents-envs==0.30.0 mlagents==0.30.0
training\venv_mlagents\Scripts\python training\patch_mlagents.py training\venv_mlagents  # 2× ausführen (v3→v4)!
# Gepatchte Module aus der Trainings-venv übernehmen (Modul-Namen müssen zum Checkpoint passen):
#   networks.py, transformer_memory.py, lstm_memory.py, torch_policy.py
# Dann:
training\venv_mlagents\Scripts\python -u Evaluations_Vorbereitung\export_final_models.py
```

## Provenienz

- Checkpoints: `LSTM_Navigator-30003930.pt`, `Transformer_Navigator-30006822.pt`,
  `MLP_Navigator-30000089.pt` (aus `results/model_comparison_final_v3/`)
- Zusätzliche Sicherung der Rohgewichte: `results/model_comparison_final_v3_final_backup/`
- Endstand (RollingSuccess auf schweren Maps, Ø 20–25M-Block): MLP 67 %,
  Transformer 56 %, LSTM 53 %
- Bekannter Messfehler des Runs: `LavaCrossings`-Zähler und +8-Crossing-Reward
  waren konstruktionsbedingt tot (siehe Projektnotizen) — Lava-Aussagen über
  `LavaJumpAttempts`, `DeathByLava` und Gate-SuccessRates treffen.
