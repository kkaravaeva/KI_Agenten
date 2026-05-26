# Training pausieren & später fortsetzen

Kurzanleitung, wie ein laufendes ML-Agents-Training sauber gestoppt und am gleichen Stand wieder aufgenommen wird. Ergänzt `Training_Starten.md` (Starten) und `Training_Anschauen.md` (Inference).

---

## Wann sinnvoll?

- Laptop muss heruntergefahren / neugestartet werden
- GPU/CPU für etwas anderes gebraucht (anderes Training, Unity-Arbeit, Benchmarks)
- Run läuft heiß / Thermal Throttling
- Hyperparameter-Wechsel mitten im Verlauf ist *nicht* der Use-Case — dafür neuen `--run-id` mit `--initialize-from=<alter-run>` nutzen

---

## Schritt 1 — Sauber stoppen

Im **Trainer-Terminal** (das mit der `mlagents.trainers.learn`-Ausgabe und den Step-Zahlen):

```
Strg + C
```

Einmal reicht. Der Trainer fängt das ab, schreibt einen **finalen `checkpoint.pt`** und beendet sich danach. Im Idealfall liegt der finale Stand sogar leicht *vor* dem nächsten regulären Auto-Checkpoint (also kein/kaum Step-Verlust).

**Headless-Build (Unity-Standalone, falls per `--env=...` gestartet):** schließt sich nach dem Trainer-Exit automatisch (Socket-Disconnect → Player-Quit). Kein Eingriff nötig.

**Unity-Editor (falls Training aus dem Editor lief):** in Unity einmal **Stop** drücken.

### Verifizieren, dass der finale Flush geklappt hat

```powershell
ls results\<run-id>\LabyrinthNavigator | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

- `checkpoint.pt` sollte einen Timestamp **nach** dem letzten `LabyrinthNavigator-<step>.pt` haben
- Höchster Step in den `.pt`-Files = letzter Auto-Checkpoint (alle 500k Steps; Intervall in `config/*.yaml` → `checkpoint_interval`)

### NICHT machen

| Aktion | Was passiert |
|---|---|
| Trainer-Fenster per X / Task-Manager schließen | Hard-Kill → kein finaler Flush → Verlust bis zum letzten 500k-Auto-Checkpoint |
| `Stop-Process` auf den Python-Prozess | Wie oben — TerminateProcess sendet kein SIGINT |
| Headless-Build vor dem Trainer schließen | Trainer hängt im Socket-Read, muss zusätzlich Ctrl+C bekommen |
| Mehrfaches Ctrl+C hintereinander | Zweites Ctrl+C kann den Flush abbrechen — einmal genügt, einfach warten |

---

## Schritt 2 — Später wieder fortsetzen

Genau derselbe Startbefehl wie zum ersten Mal, nur ans Ende **`--resume`** hängen — `--run-id` muss **identisch** sein.

**Wenn das Training mit `training/start_training.py` gestartet wurde:**

```powershell
cd C:\Users\Finnl\KI_Agenten
C:\Users\Finnl\mlagents-31008\Scripts\python.exe training\start_training.py --run-id=<run-id> --resume
```

**Direkt mit `mlagents.trainers.learn` (z.B. mit Headless-Build):**

```powershell
cd C:\Users\Finnl\KI_Agenten
C:\Users\Finnl\mlagents-31008\Scripts\python.exe -m mlagents.trainers.learn `
    config/labyrinth_transformer.yaml `
    --run-id=<run-id> `
    --env="<pfad-zum-build>\LabyrinthTraining.exe" `
    --num-envs=4 `
    --resume
```

Danach (falls Editor statt Build): in Unity wieder **Play** drücken.

### Was `--resume` macht

- Sucht in `results/<run-id>/LabyrinthNavigator/checkpoint.pt`
- Lädt Gewichte, Optimizer-State, Step-Counter
- Training läuft am letzten Stand weiter (z.B. v23 nach Stopp bei 18,0M Steps → setzt bei 18,0M fort, nicht bei 0)
- TensorBoard schreibt in dieselbe `events.out.tfevents.*`-Datei weiter → eine durchgehende Kurve

### ⚠️ Was `--resume` NICHT wiederherstellt: das Unity-seitige Curriculum

`--resume` lädt nur den Trainer-State (Python-Seite). Der **Curriculum-Tracker im `MapGenerator` der Unity-Builds wird beim Build-Neustart auf Phase 0 zurückgesetzt**. Symptom in TensorBoard:

- `Custom/CurriculumPhase` fällt im Resume-Step abrupt von z.B. 10.9 auf 0.0
- Reward bricht entsprechend kurz ein, weil zu einfache Maps gespielt werden
- Agent klettert relativ schnell zurück, weil die gelernten Netzgewichte noch da sind (v23-Beispiel: 0 → 2.6 in ~700k Steps nach Resume von Phase 10.9)

**Verlorene Compute:** die Steps, die das Curriculum zum Re-Hochklettern braucht. Bei lang trainierten Runs (Phase 10+) sind das mehrere Mio. Steps. Wenn das stört: möglichst lang am Stück trainieren statt oft pausieren.

---

## Was zwischen Stopp und Resume NICHT geändert werden darf

Reine **Curriculum/Reward-Werte** in der YAML sind meistens OK. Alles, was die **Modell-Shapes** betrifft, bricht den Resume mit `Error(s) in loading state_dict`:

| Parameter | Folge bei Änderung |
|---|---|
| `hidden_units` | Shape-Mismatch im Backbone |
| `memory_size` / `sequence_length` | Shape-Mismatch in Transformer-Layer |
| `num_layers` / `nhead` | Layer-Anzahl passt nicht zu State-Dict |
| `memory_type` (lstm ↔ transformer) | Komplett anderes Modul |
| Anzahl/Größe der Observations am Agent | Input-Layer-Mismatch |
| Anzahl/Aufteilung der Actions | Output-Heads-Mismatch |

Auch nicht ändern: venv-Pfad / Transformer-Patch entfernen. Der Patch unter `C:\Users\Finnl\mlagents-31008\Lib\site-packages\mlagents\trainers\torch_entities\transformer_memory.py` muss erhalten bleiben, sonst lädt mlagents wieder die LSTM-Variante und das State-Dict matched nicht.

---

## Troubleshooting

### `Previous data from this run ID was found`

```
UnityTrainerException: Previous data from this run ID was found.
```

→ `--resume` vergessen. **Nicht** `--force` benutzen (würde alle bisherigen Checkpoints überschreiben). Befehl mit `--resume` erneut starten.

### `Error(s) in loading state_dict ... Missing key(s)` / `size mismatch`

Eine architektur-relevante Config wurde zwischen Stopp und Resume geändert. Entweder
- Config auf den ursprünglichen Stand zurücksetzen und nochmal `--resume`, oder
- Bewusst neuer Run: `--run-id=<neuer-name>` mit `--initialize-from=<alter-run>` (übernimmt nur kompatible Gewichte)

### Port 5004 belegt

```
RuntimeError: Failed to bind to address [::]:5004
```

Alter Trainer-/Inference-Prozess hängt noch. Prüfen und beenden:
```powershell
Get-NetTCPConnection -LocalPort 5004 | Select-Object OwningProcess
Stop-Process -Id <PID> -Force
```

### Resume scheint bei Step 0 zu starten

`--run-id` falsch geschrieben → mlagents legt einen neuen leeren Run an. Mit `--run-id=<exakter-name>` (siehe Ordnernamen in `results/`) erneut starten.

---

## Beispiel-Ablauf (real, v23)

```
16:14   Auto-Checkpoint geschrieben         → 17,0M Steps
16:25   Auto-Checkpoint                      → 17,5M Steps
16:36   Auto-Checkpoint                      → 18,0M Steps
~16:36  Ctrl+C im Trainer-Terminal
16:36   Finaler checkpoint.pt geflusht       → 18,0M Steps
        Headless-Build schließt sich automatisch

(Stunden später)
        python training\start_training.py --run-id=v23 --resume
        → Training läuft ab 18,0M weiter
```
