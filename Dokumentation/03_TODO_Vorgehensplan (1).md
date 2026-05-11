# TODO Liste – Technischer Vorgehensplan
Unity ML-Agents · 1-2 Wochen · Studienarbeit

> **Legende:**
> 🔴 **MUSS** – Zwingend erforderlich vor Training bzw. Abgabe
> 🟡 **SOLLTE** – Wichtig für wissenschaftliche Qualität, aber kein Blocker
> 🟢 **KANN** – Optional, verbessert die Arbeit wenn Zeit vorhanden

---

## Phase 1 – Vor dem Training 🔴

Diese Aufgaben müssen vollständig abgeschlossen sein bevor das erste Training gestartet wird.

### 1.1 YAML Konfigurationen

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 1 | `seed: 42` in `labyrinth_training.yaml` eintragen | 🔴 MUSS | [ ] |
| 2 | `seed: 42` in `labyrinth_lstm.yaml` eintragen | 🔴 MUSS | [ ] |
| 3 | `seed: 42` in `labyrinth_transformer.yaml` eintragen | 🔴 MUSS | [ ] |
| 4 | `agent1_camera_lstm.yaml` erstellen | 🔴 MUSS | [ ] |
| 5 | `agent2_camera_transformer.yaml` erstellen | 🔴 MUSS | [ ] |
| 6 | `agent5_camera_ray_transformer.yaml` erstellen | 🔴 MUSS | [ ] |
| 7 | `agent6_camera_ray_lstm.yaml` erstellen | 🔴 MUSS | [ ] |
| 8 | Alle YAMLs gegenüber prüfen: gleiche Hyperparameter? | 🔴 MUSS | [ ] |

### 1.2 Maps aufteilen

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 9 | 200-300 Maps aus 900 auswählen | 🔴 MUSS | [ ] |
| 10 | 80% als Training-Maps definieren | 🔴 MUSS | [ ] |
| 11 | 20% als Evaluation-Maps separieren und **einfrieren** | 🔴 MUSS | [ ] |
| 12 | Evaluation-Maps Liste dokumentieren und speichern | 🔴 MUSS | [ ] |
| 13 | Sicherstellen dass Eval-Maps NIE in Training-Rotation kommen | 🔴 MUSS | [ ] |

### 1.3 Unity Setup

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 14 | LSTM vollständig implementieren und testen | 🔴 MUSS | [ ] |
| 15 | MLP Baseline verifizieren (kein `memory` block in YAML) | 🔴 MUSS | [ ] |
| 16 | Reward-Werte im Inspector für alle Agenten gleich setzen | 🔴 MUSS | [ ] |
| 17 | Screenshot der Inspector-Werte als Dokumentation | 🔴 MUSS | [ ] |
| 18 | CameraSensorComponent für Agent 1, 2, 5, 6 einrichten | 🔴 MUSS | [ ] |
| 19 | Kamera: 36×36, Grayscale=true für alle Kamera-Agenten | 🔴 MUSS | [ ] |
| 20 | Ray-Sensor: gleiche Einstellungen für alle Ray-Agenten | 🔴 MUSS | [ ] |
| 21 | BehaviorName in Unity und YAML abgleichen (`LabyrinthNavigator`) | 🔴 MUSS | [ ] |

---

## Phase 2 – Training durchführen 🟡

Ray-Agenten zuerst — kein CNN nötig, schnellere Iteration und einfacheres Debugging.

### 2.1 Trainingsreihenfolge

| Nr. | Agent | YAML | Runs | Status |
|---|---|---|---|---|
| 22 | MLP Baseline (Ray + MLP) | `labyrinth_training.yaml` | 3× | [ ] |
| 23 | Agent 3 (Ray + LSTM) | `labyrinth_lstm.yaml` | 3× | [ ] |
| 24 | Agent 4 (Ray + Transformer) | `labyrinth_transformer.yaml` | 3× | [ ] |
| 25 | Agent 1 (Kamera + CNN + LSTM) | `agent1_camera_lstm.yaml` | 3× | [ ] |
| 26 | Agent 2 (Kamera + CNN + Transformer) | `agent2_camera_transformer.yaml` | 3× | [ ] |
| 27 | Agent 6 (Kamera + Ray + CNN + LSTM) | `agent6_camera_ray_lstm.yaml` | 3× | [ ] |
| 28 | Agent 5 (Kamera + Ray + CNN + Transformer) | `agent5_camera_ray_transformer.yaml` | 3× | [ ] |

### 2.2 Während des Trainings

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 29 | TensorBoard für jeden Run starten und prüfen | 🔴 MUSS | [ ] |
| 30 | Nach 500k Steps: steigt der Reward? Falls nicht → Reward debuggen | 🔴 MUSS | [ ] |
| 31 | TensorBoard Logs nach jedem Run sichern | 🔴 MUSS | [ ] |
| 32 | Trainingszeit pro Agent notieren | 🟡 SOLLTE | [ ] |
| 33 | Qualitatives Verhalten beobachten und notieren | 🟡 SOLLTE | [ ] |

---

## Phase 3 – Evaluation

Nach Abschluss aller Trainings. **Kein weiteres Training ab diesem Punkt.**

### 3.1 Evaluation-Messung

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 34 | Jeden Agenten auf 100 Training-Map-Episoden testen | 🔴 MUSS | [ ] |
| 35 | Jeden Agenten auf 100 Evaluation-Map-Episoden testen | 🔴 MUSS | [ ] |
| 36 | Erfolgsrate pro Agent berechnen | 🔴 MUSS | [ ] |
| 37 | Generalisierungslücke berechnen (Train − Eval) | 🔴 MUSS | [ ] |
| 38 | Hindernisüberwindungsrate pro Agent messen | 🔴 MUSS | [ ] |
| 39 | Fehlerquote (Lava/Hole/Timeout) pro Agent messen | 🟡 SOLLTE | [ ] |
| 40 | Mittelwert und Standardabweichung über 3 Runs berechnen | 🔴 MUSS | [ ] |

### 3.2 Auswertung und Visualisierung

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 41 | TensorBoard Kurven als PNG exportieren | 🔴 MUSS | [ ] |
| 42 | Finale Ergebnistabelle ausfüllen | 🔴 MUSS | [ ] |
| 43 | Balkendiagramm Erfolgsrate Train vs. Eval erstellen | 🟡 SOLLTE | [ ] |
| 44 | Balkendiagramm Generalisierungslücke erstellen | 🟡 SOLLTE | [ ] |
| 45 | Qualitative Analyse pro Agent schreiben | 🟡 SOLLTE | [ ] |
| 46 | Trajektorien / Heatmaps erstellen | 🟢 KANN | [ ] |

---

## Phase 4 – Optional (wenn Zeit bleibt) 🟢

Nur angehen wenn Phase 1–3 vollständig abgeschlossen sind.

| Nr. | Aufgabe | Priorität | Status |
|---|---|---|---|
| 47 | Schwierigkeitsgrade in `MapData.cs` einbauen (Easy/Medium/Hard) | 🟢 KANN | [ ] |
| 48 | Editor Script für automatisches Map-Tagging | 🟢 KANN | [ ] |
| 49 | Curriculum Learning in `MapGenerator.cs` einbauen | 🟢 KANN | [ ] |
| 50 | Curriculum YAML Konfiguration erstellen | 🟢 KANN | [ ] |
| 51 | Python Auswertungsscript für automatische Plots | 🟢 KANN | [ ] |
| 52 | Unity Position-Logger für Trajektorien einbauen | 🟢 KANN | [ ] |
