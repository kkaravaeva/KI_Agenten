# Abschlussbericht: Trainingslauf `model_comparison_final`

**Zeitraum:** 08.07.2026 ~23:00 Uhr bis 09.07.2026 ~13:50 Uhr
**Branch:** `ModelTrainingComparsion` · **Config:** `config/model_comparison_standalone.yaml`
**Abschluss-Stand:** 3,99M von 30M geplanten Steps pro Agent (~13,3%) — Lauf bewusst vorzeitig beendet, um grundsätzliche Änderungen vor dem zweiten finalen Lauf vorzunehmen.

**Begleitmaterial:**
- Charts: `Analyse/final/ABSCHLUSSREPORT_model_comparison_final.pdf` (4 Seiten)
- Resumierbares Archiv: `Training_Archive/model_comparison_final_2026-07-09/` (inkl. `RESUME_ANLEITUNG.md`)
- Rohdaten: `results/model_comparison_final/` (TensorBoard-Events, Checkpoints, ONNX)

---

## 1. Versuchsaufbau

Direkter Architekturvergleich dreier PPO-Agenten im selben Labyrinth-Environment:

| | MLP | LSTM | Transformer |
|---|---|---|---|
| Gedächtnis | keines | LSTM (seq 16, mem 256) | Attention (seq 16, mem 128, Eigenimplementierung) |
| normalize | false | true | false |
| learning_rate | 3e-4 | 3e-4 | **1e-4** |
| batch / buffer | 512 / 40.960 | 512 / 40.960 | 1.024 / 81.920 |
| gamma (extrinsic) | 0.995 | 0.995 | 0.997 |
| time_horizon | 512 | 512 | 256 |
| Curiosity | 0.05 | 0.05 | 0.05 |

Design **„Best vs. Best"**: jede Architektur mit ihren historisch besten Hyperparametern (Transformer 1:1 aus milestone-7/V14, LSTM aus v7, MLP aus M5-Baseline mit dokumentierten Anpassungen). Unity-Seite für alle identisch.

**Environment:** Szene „Training Area" mit **9 Agenten pro Architektur** (27 gesamt), headless ×2 Environments (time-scale 20). Observations: 28 Vektor-Werte (Boden-Raycasts 9×2, Velocity 3, isGrounded, **Zieldistanz**, Wand-Raycasts 4, **Line-of-Sight-Flag**) + RayPerceptionSensor (11 Strahlen, 120°, 12 m, 2 Stacks). **Keine Zielrichtungs-Observation** (Unterschied zu milestone-7!). Rewards: Ziel +30, Tod −3, Timeout −10, Step −0,002, PBRS-Distanz-Shaping 0,01, LOS-Bonus 0,005/Step, Lava-Sprung +1,5 / Überquerung +8.

**Curriculum (geteilt über alle Agenten):** 7 Phasen (Trivial → TrivialCorr → 2× TrivialLava → Easy → Medium → Hard) mit Episoden-Schwellen, **Erfolgs-Gates** (30–40% in Phasen 0–3, Fenster 200, Notausstieg bei 3× Schwelle) und **Loop** ab Phase 6 zurück zu Phase 4. Phasen-Fortschritt dateipersistent (übersteht Prozess-Neustarts).

## 2. Verlauf (Timeline)

| Zeit | Ereignis |
|---|---|
| 08.07. ~23:00 | Start als Editor-Training (bis 125k Steps) |
| 09.07. 01:05–01:10 | Umstellung auf Headless; Curriculum-State vom Editor übernommen |
| 01:10–08:38 | **Nachtlauf: 7,5 h crash-frei** bis 2,8M Steps; Curriculum von Phase 1 bis Phase 6 (Hard) durchlaufen — alle Gates regulär bestanden |
| 08:40–10:20 | Editor-Session (Beobachtung); dabei 3 Bugs entdeckt und behoben (siehe §5) |
| 10:24–13:37 | Headless: Curriculum-Loop, 2. Durchlauf Easy/Medium, bis 3,8M Steps |
| 13:38–13:50 | Editor-Session 2; Abschluss des Laufs bei ~3,87M Steps |

6 Trainer-Sessions gesamt (6 Event-Dateien pro Agent); resumierbarer Endstand: **Checkpoint 3,8M** (Editor-Sessions sichern beim Play-Stopp keinen Checkpoint).

## 3. Ergebnisse

### 3.1 Erfolgsraten je Curriculum-Phase (Ø gesamter Lauf, inkl. 2. Durchlauf)

| Phase | MLP | LSTM | Transformer |
|---|---|---|---|
| 1 TrivialCorr | 7,5% | **15,0%** | 3,9% |
| 2 TrivialLava | 17,0% | **24,9%** | 2,4% |
| 3 TrivialLava 2 | 26,8% | **38,1%** | 2,7% |
| 4 Easy (beide Durchläufe) | **29,2%** | 25,0% | 3,7% |
| 5 Medium (beide Durchläufe) | **24,9%** | 16,7% | 2,2% |
| 6 Hard | **10,3%** | 7,4% | 1,2% |

### 3.2 Endstand (letzte ~100k Steps, Phase 5 Medium, 2. Durchlauf)

| | Erfolgsrate | Mean Reward |
|---|---|---|
| **MLP** | **~50%** | **+13,9** |
| LSTM | ~40% | +10,3 |
| Transformer | ~5% | −3,1 |

### 3.3 Lernfortschritts-Nachweis (gleiche Phase, 1. vs. 2. Durchlauf)

| Easy | 1. Durchlauf (Nacht) | 2. Durchlauf (Mittag) |
|---|---|---|
| MLP | 18,9% | **42,5%** |
| LSTM | 15,2% | **40,6%** |
| Transformer | 3,3% | 4,7% |

MLP und LSTM haben ihre Erfolgsrate auf identischen Maps **mehr als verdoppelt** — das dazwischenliegende Hard-Training generalisiert. Der Transformer verbessert sich nicht nennenswert.

### 3.4 Verhaltensbild (Todesursachen)

- **Frühphase (bis ~0,7M):** Timeout dominiert (bis >90%) — Agenten „sitzen ab".
- **Ab ~1M:** Timeouts fallen auf 1–3%; Tode fast ausschließlich Hole (~40–50%) und Lava (~38–47%). Die Agenten scheitern an Manövrier-Präzision, nicht an Passivität — qualitativ der deutlich bessere Fehlermodus.
- Lava-Überquerungen gelingen seit der Sprungkraft-Erhöhung regulär (Gates der Lava-Phasen mit 30–38% bestanden; in Vorgänger-Läufen: 0 Überquerungen).

### 3.5 Kernbefund Architekturvergleich

1. **MLP und LSTM lernen die Aufgabe robust**; das LSTM dominierte die frühen/engen Phasen (Korridore, Lava-Timing), der MLP übernahm ab den offeneren Maps (Easy/Medium/Hard) und hielt die Führung.
2. **Der Transformer versagt durchgängig** (1–4% Erfolg in allen Phasen, Reward-Plateau bei −3 bis −4 ab ~1M Steps). Sein moderater Reward speist sich aus Shaping-Boni (PBRS/LOS), nicht aus Zielerreichung — ein stabiles lokales Optimum.
3. **Mean Reward überzeichnet den Transformer massiv** — die Erfolgsrate ist die belastbare Primärmetrik.

## 4. Einordnung & Limitationen (wichtig für die Studienarbeit)

1. **Architektur und Hyperparameter sind konfundiert** („Best vs. Best"): Der Lauf zeigt streng genommen „MLP-Setup schlägt Transformer-Setup". Insbesondere wurde die V14-Transformer-Config für ein Environment **mit Zielrichtungs-Observation** getunt, die es hier nicht gibt; seine lr 1e-4 (⅓ der anderen) ist auf die schwerere Suchaufgabe nicht validiert.
2. **Geteiltes Curriculum:** Die starken Agenten ziehen den Transformer per Gate in Phasen, die er nicht beherrscht; umgekehrt sieht kein Agent ein individuell angepasstes Schwierigkeitsprofil.
3. **Nur ~13% der geplanten Steps:** Aussagen zu Endleistungen sind vorläufig; die Schlussphase (Medium, 2. Durchlauf) zeigte MLP/LSTM noch klar im Aufwärtstrend.
4. **Uneinheitliche Bedingungen in Teilabschnitten:** 19 defekte Layout-Referenzen (bis 10:24), fehlendes Phase-6-Timeout in der Editor-Session (08:40–10:20), Editor-Abschnitte mit time-scale 10/1 Env. Für phasensaubere Auswertungen die Zeiträume aus §2 beachten.

## 5. Behobene Bugs & infrastrukturelle Lektionen

| Problem | Ursache | Fix |
|---|---|---|
| Crash-Loop (~alle 22 min, vor final) | `MemoryError` durch buffer_size 409.600 ×3 bei 16 GB RAM | buffer_size reduziert |
| Curriculum-Reset bei Neustarts | Statische Felder ohne Persistenz | JSON-State-Datei pro Env (`curriculum_state_*.json`) |
| `MissingReferenceException` im Editor | `layout?.name` umgeht Unitys Destroyed-Check (Asset-Reimport im Play-Modus) | Unity-Null-Guard in `CurriculumTracker.GetNextLayout()` |
| Episoden auf „unsichtbaren" Maps | 19 tote Layout-GUIDs in `CurriculumConfig_Default.asset` | Referenzen entfernt (Phasen: 192–200 Layouts) |
| Kein Timeout in Phase 6 nach Neustart | `phaseMaxSteps` 6 Einträge für 7 Phasen + Prefab-MaxStep 0 | 7 Einträge + Index-Clamp (Code + Prefab) |
| Steps-Verlust beim Editor-Stopp | Editor-Trainer sichert bei Play-Stopp keinen Checkpoint | Prozedur: vor Stopp auf 200k-Export warten |

## 6. Empfehlungen für den zweiten finalen Lauf

1. **Erfolgsrate als Primärmetrik** definieren und loggen wie gehabt; Reward nur als Sekundärmetrik.
2. **Transformer-Bedingung überdenken:** Entweder (a) Hyperparameter auf das aktuelle Environment neu tunen (lr-Sweep, normalize true testen) oder (b) zusätzlich eine Bedingung mit **identischen** Hyperparametern für alle drei Architekturen fahren — dann ist der Architektur-Effekt isolierbar.
3. **Zielrichtungs-Observation** bewusst entscheiden (drin oder draußen) und dokumentieren — sie war der größte stille Unterschied zu milestone-7.
4. **Gates auch für Easy/Medium** (z. B. 25–30%), damit späte Phasen nicht „abgesessen" werden.
5. Curriculum-Persistenz, Watchdog und `phaseMaxSteps`-Länge = Phasenzahl beibehalten/prüfen.
6. Vor geplanten Stopps auf Checkpoint-Export warten; Editor-Sessions nur zur Beobachtung.
