# Runbook: Model-Comparison Training headless starten (ohne Unity-GUI)

> Zielgruppe: eine KI/ein Agent, der den 3-Wege-Vergleich (Transformer/LSTM/MLP)
> vollständig über die Kommandozeile startet — Standalone-Build im Batchmode,
> Training headless (`--no-graphics`), keine manuelle Interaktion in Unity nötig.
>
> Branch: `ModelTrainingComparsion` · Unity `6000.2.6f1` · ML-Agents 0.30 (Python)

---

## 0. Feste Werte (bei anderem Rechner hier anpassen)

| Zweck | Pfad / Wert |
|---|---|
| Projekt-Root | `C:\Users\Finnl\KI_Agenten` |
| Unity-Editor | `C:\Program Files\Unity\Hub\Editor\6000.2.6f1\Editor\Unity.exe` |
| venv-Python | `C:\Users\Finnl\mlagents-31008\Scripts\python.exe` |
| Config | `config\model_comparison_final_v3.yaml` |
| Run-ID | `model_comparison_final_v3` |
| Build-Output | `Build\KI_Agenten.exe` |
| Trainings-Szene | `Assets/Scenes/Training Area.unity` (3×9 Areas: LSTM/Transformer/MLP) |

Alle Befehle unten sind **PowerShell** und werden aus dem Projekt-Root ausgeführt.
Der Aufruf-Operator `&` ist nötig, weil die Pfade Leerzeichen enthalten.

---

## 1. Voraussetzungen prüfen

```powershell
# Richtiger Branch?
git -C "C:\Users\Finnl\KI_Agenten" branch --show-current   # muss: ModelTrainingComparsion

# Ist der Unity-Editor auf diesem Projekt GESCHLOSSEN?
# -> Der Batchmode-Build (Schritt 3) scheitert an einem Projekt-Lock,
#    wenn parallel ein Unity-Editor dasselbe Projekt geöffnet hat.
#    Vor dem Build den Editor schließen.
```

---

## 2. Transformer-Patch sicherstellen (idempotent)

Der Python-Trainer braucht den `memory_type: transformer`-Patch in der venv.
Das Skript prüft selbst, ob schon gepatcht ist — mehrfaches Ausführen ist harmlos.

```powershell
$env:PYTHONIOENCODING = "utf-8"
& "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" `
  "C:\Users\Finnl\KI_Agenten\training\patch_mlagents.py"
```

**Erwartet:** entweder „…memory_type bereits vorhanden — überspringe" oder eine
Meldung, dass der Patch angewendet wurde. Kein Traceback.

> `PYTHONIOENCODING=utf-8` ist nötig, weil das Skript Pfeil-Zeichen (`→`) druckt
> und auf der cp1252-Konsole sonst mit `UnicodeEncodeError` abbricht — die
> Patches selbst sind zu dem Zeitpunkt aber meist schon geschrieben (beim
> nächsten Lauf meldet er „bereits vorhanden").

---

## 3. Standalone-Build im Batchmode bauen (ohne GUI)

Baut die **Training Area**-Szene nach `Build\KI_Agenten.exe`. Läuft ohne Fenster,
beendet sich selbst. **Unity-Editor muss vorher geschlossen sein** (Projekt-Lock).

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.2.6f1\Editor\Unity.exe" `
  -batchmode -quit `
  -projectPath "C:\Users\Finnl\KI_Agenten" `
  -executeMethod StandaloneBuild.BuildFromCommandLine `
  -logFile "C:\Users\Finnl\KI_Agenten\build.log"
```

> Der Befehl **blockiert**, bis der Build fertig ist. Beim ersten Öffnen unter
> Unity 6 reimportiert die Engine das ganze Projekt — das kann 10–30 Min dauern.

**Erfolg prüfen:**

```powershell
Test-Path "C:\Users\Finnl\KI_Agenten\Build\KI_Agenten.exe"        # muss True sein
Select-String -Path "C:\Users\Finnl\KI_Agenten\build.log" -Pattern "Build\] Status|Succeeded|error CS"
```

Erwartet: `[Build] Status: Succeeded`. Exit-Code des Unity-Prozesses = 0.

---

## 4. Training starten (headless)

Run-ID `model_comparison_final_v3` ist noch frei → frischer Start (kein `--force`
nötig). Der Trainer startet die Build-Exe selbst und trainiert ohne Rendering.

```powershell
& "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" -m mlagents.trainers.learn `
  "config\model_comparison_final_v3.yaml" `
  --run-id model_comparison_final_v3 `
  --env "Build\KI_Agenten.exe" `
  --num-envs 5 `
  --no-graphics `
  --time-scale 40 `
  --base-port 5004 `
  --results-dir results
```

**Flags:**
- `--env … --no-graphics` → Standalone ohne Fenster (das ist „ohne Unity-GUI").
- `--num-envs 5` → 5 parallele Instanzen der Szene (5×27 = 135 Agenten gesamt).
- `--time-scale 40` → Simulation 40× beschleunigt.
- `--base-port 5004` → Kommunikationsport Unity↔Python.

**Erfahrungswert zu `--num-envs` (Messung 2026-07-09, Ryzen 5 5625U, RTX 3050
Laptop, 16 GB):** 3 vs. 5 Envs macht im Dauerbetrieb **keinen Unterschied**
(~300–310 Steps/s je Behavior ≈ 1,1 Mio. Steps/h je Behavior, beide
Konfigurationen). Der Engpass ist die Update-Phase des Trainers (PPO-Updates
für Transformer/LSTM), die nicht mit der Env-Anzahl skaliert — nur die
Anlaufphase (~erste 30k Steps) profitiert. Auch `--time-scale` weiter zu
erhöhen bringt nichts (Envs idlen bei ~1 % CPU). Kosten pro Env: ~0,5 GB RAM.
Kurz: 3–5 Envs sind gleichwertig; bei knappem RAM oder Throttling-Verdacht
lieber 3 nehmen. Hochrechnung: 30 Mio. Steps ≈ 27 h.

**Alternative (macht dasselbe + Auto-Neustart nach Crash):**
`start_trainer_standalone.bat` doppelklicken. Der Launcher nutzt bereits
`final_v3`/Run-ID `model_comparison_final_v3` und resumed automatisch, wenn ein
Checkpoint existiert. **Baut aber nicht** — Schritt 3 muss vorher gelaufen sein.

---

## 5. Verifikation — läuft es wirklich?

Im Trainer-Output (bzw. `trainer_logs\...` bei der .bat) sollte erscheinen:

1. `Connected to Unity environment` / `Listening on port 5004`
2. Die drei Behaviors werden geladen — **kein** `behavior "…" not found in trainer config`
3. Nach ~20 000 Steps die erste Summary-Zeile mit
   `Environment/Cumulative Reward` je Behavior (LSTM/Transformer/MLP)

Wenn nach ~2 Min noch „waiting for Unity" steht und sich nichts tut → siehe
Troubleshooting (Port belegt, Build-Exe startet nicht, Behavior-Namen).

---

## 6. Monitoring (TensorBoard + stündliche PDF-Analyse)

```powershell
& "C:\Users\Finnl\mlagents-31008\Scripts\tensorboard.exe" --logdir results --port 6006
# -> http://localhost:6006
```

**Stündliche PDF-Reports (Pflicht bei Vergleichs-Runs):** Das Skript
`training\hourly_analysis.py` erzeugt jede Stunde einen 6-seitigen PDF-Report
(Zusammenfassungstabelle, Reward/Erfolgsrate, Curriculum/Todesursachen,
Lava-Fokus, Reward-Zerlegung, Policy-Metriken) nach `Analyse\final_v3\`.

```powershell
# Nach dem Trainingsstart (sobald erste Summaries laufen) im Hintergrund starten:
$env:PYTHONIOENCODING = "utf-8"
& "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" `
  "C:\Users\Finnl\KI_Agenten\training\hourly_analysis.py"
```

⚠️ `RUN_ID` und `ANALYSE_DIR` sind im Skript **hart kodiert** (Kopfbereich).
Bei einem neuen Run beide Konstanten anpassen, sonst analysiert es den alten
Run weiter. Aktuell: `model_comparison_final_v3` → `Analyse\final_v3`.

---

## 7. Fortsetzen nach Abbruch

```powershell
# gleicher Befehl wie Schritt 4, aber:
  --resume        # statt frischem Start
# ODER kompletten Neustart erzwingen (überschreibt den Run):
  --force
```

⚠️ **Wichtig bei `--resume`:** Der Trainer-State (Netzgewichte) wird geladen, aber
das Unity-**Curriculum startet wieder bei Phase 0**. Ein sichtbarer Reward-Einbruch
direkt nach dem Resume ist daher normal; das Re-Climb kostet Millionen Steps.

---

## 8. Troubleshooting

| Symptom | Ursache / Lösung |
|---|---|
| Build: „Multiple Unity instances cannot open the same project" | Unity-Editor auf dem Projekt ist offen → schließen, Build erneut starten. |
| Build: `error CS…` in `build.log` | Compile-Fehler im Projekt → müssen zuerst behoben werden, sonst keine Exe. |
| Training: `behavior "Transformer_Navigator" not found` o. ä. | Szene enthält die Behaviors nicht (mehr). Szene neu generieren (siehe unten), dann neu bauen. |
| Training bleibt bei „waiting for Unity" | Port `5004` belegt → `--base-port 5010` probieren; oder Build-Exe startet nicht (manuell 1× per Doppelklick testen). |
| Rote ONNX-Fehler `Transformer_v24_opset18_backup.onnx` beim Import | **Harmlos.** Barracuda (veraltet in Unity 6) kann diese Backup-Datei nicht lesen. Blockiert weder Build noch Training. Ignorieren. |
| Laptop drosselt nach Stunden (Throttling) | `--num-envs 1 --time-scale 20` statt 3/40. Die Szene hat schon 9 Areas pro Behavior — das reicht als Parallelität. |

**Szene neu generieren (nur falls Behaviors fehlen)** — braucht ebenfalls kein
GUI-Klicken, läuft im Batchmode (Editor vorher schließen):

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.2.6f1\Editor\Unity.exe" `
  -batchmode -quit `
  -projectPath "C:\Users\Finnl\KI_Agenten" `
  -executeMethod ModelComparisonSceneBuilder.BuildModelComparisonScene `
  -logFile "C:\Users\Finnl\KI_Agenten\scene_build.log"
```
Danach Schritt 3 (Build) wiederholen.

---

## Kurzfassung (Copy-Paste-Reihenfolge)

```powershell
# 1. Editor schließen (falls offen)!
$env:PYTHONIOENCODING = "utf-8"
# 2. Patch
& "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" "C:\Users\Finnl\KI_Agenten\training\patch_mlagents.py"
# 3. Build (headless)
& "C:\Program Files\Unity\Hub\Editor\6000.2.6f1\Editor\Unity.exe" -batchmode -quit -projectPath "C:\Users\Finnl\KI_Agenten" -executeMethod StandaloneBuild.BuildFromCommandLine -logFile "C:\Users\Finnl\KI_Agenten\build.log"
# 4. Training (headless)
& "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" -m mlagents.trainers.learn "config\model_comparison_final_v3.yaml" --run-id model_comparison_final_v3 --env "Build\KI_Agenten.exe" --num-envs 5 --no-graphics --time-scale 40 --base-port 5004 --results-dir results
# 5. Stündliche PDF-Analyse (separates Terminal, nach den ersten Summaries)
& "C:\Users\Finnl\mlagents-31008\Scripts\python.exe" "C:\Users\Finnl\KI_Agenten\training\hourly_analysis.py"
```
