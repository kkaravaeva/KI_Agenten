# Anforderungen – Fairer und wissenschaftlicher Vergleich
Unity ML-Agents · 7 RL-Agenten · Studienarbeit

> **Grundprinzip: Nur eine Variable ändert sich — alles andere ist identisch.**

---

## A – Trainingsparameter

Alle folgenden Parameter müssen für alle 7 Agenten exakt identisch sein.

### A.1 YAML Konfiguration – identisch für alle

| Nr. | Parameter | Wert | Status |
|---|---|---|---|
| A1 | trainer_type | ppo | [ ] bestätigt |
| A2 | learning_rate | 3.0e-4 | [ ] bestätigt |
| A3 | batch_size | 512 | [ ] bestätigt |
| A4 | buffer_size | 10240 | [ ] bestätigt |
| A5 | beta | 5.0e-3 | [ ] bestätigt |
| A6 | epsilon | 0.2 | [ ] bestätigt |
| A7 | lambd | 0.95 | [ ] bestätigt |
| A8 | num_epoch | 3 | [ ] bestätigt |
| A9 | learning_rate_schedule | linear | [ ] bestätigt |
| A10 | max_steps | 2.000.000 | [ ] bestätigt |
| A11 | time_horizon | 64 | [ ] bestätigt |
| A12 | gamma | 0.99 | [ ] bestätigt |
| A13 | hidden_units | 256 | [ ] bestätigt |
| A14 | num_layers | 2 | [ ] bestätigt |
| A15 | sequence_length (LSTM + Transformer) | 8 | [ ] bestätigt |
| A16 | memory_size (LSTM + Transformer) | 128 | [ ] bestätigt |
| A17 | seed (erster Run) | 42 | [ ] bestätigt |
| A18 | Anzahl parallele Unity-Instanzen | identisch | [ ] bestätigt |

### A.2 Was sich kontrolliert unterscheiden darf

Nur diese Parameter unterscheiden sich — genau so wie es der jeweilige Vergleich erfordert:

- `memory_type: lstm` oder `transformer` (je nach Agent)
- `vis_encode_type: simple` (nur bei Kamera-Agenten)
- Sensor-Konfiguration (Ray vs. Kamera vs. Kombination)

---

## B – Reward-Struktur

Die Reward-Funktion ist für alle 7 Agenten identisch. Vor dem ersten Training werden alle Werte dokumentiert und eingefroren.

| Nr. | Reward-Komponente | Wert | Status |
|---|---|---|---|
| R1 | goalReward (Ziel erreicht) | +1.0 | [ ] bestätigt |
| R2 | lavaDeathPenalty | -1.0 | [ ] bestätigt |
| R3 | holeDeathPenalty | -1.0 | [ ] bestätigt |
| R4 | stepPenalty (pro Step) | -0.001 | [ ] bestätigt |
| R5 | Curiosity: gleich für alle (an oder aus) | **festlegen!** | [ ] bestätigt |

> ⚠️ **Wichtig:** Curiosity muss entweder für ALLE aktiviert oder für KEINEN. Selektive Aktivierung macht den Vergleich unfair.

---

## C – Sensoreinstellungen

Alle Sensoreinstellungen müssen innerhalb einer Vergleichsgruppe identisch sein.

### C.1 Ray Sensor (Agent 3, 4, 5, 6)

| Nr. | Einstellung | Wert | Status |
|---|---|---|---|
| S1 | Rays Per Direction | identisch festlegen | [ ] bestätigt |
| S2 | Max Ray Degrees | identisch festlegen | [ ] bestätigt |
| S3 | Ray Length | identisch festlegen | [ ] bestätigt |
| S4 | Detectable Tags | identisch für alle | [ ] bestätigt |
| S5 | Sensor Position am Agent | identisch | [ ] bestätigt |

### C.2 Kamera Sensor (Agent 1, 2, 5, 6)

| Nr. | Einstellung | Wert | Status |
|---|---|---|---|
| S6 | Auflösung Width | 36 | [ ] bestätigt |
| S7 | Auflösung Height | 36 | [ ] bestätigt |
| S8 | Grayscale | true | [ ] bestätigt |
| S9 | vis_encode_type (YAML) | simple | [ ] bestätigt |
| S10 | Kamera Position am Agent | identisch | [ ] bestätigt |
| S11 | Sichtfeld (FOV) | identisch | [ ] bestätigt |

### C.3 Observations (C#-Code)

| Nr. | Anforderung | Status |
|---|---|---|
| S12 | CollectObservations() identisch für alle Agenten (13 Werte) | [ ] bestätigt |
| S13 | Normalisierung identisch (Velocity / moveSpeed etc.) | [ ] bestätigt |
| S14 | moveSpeed identisch (beeinflusst normalisierte Velocity) | [ ] bestätigt |

---

## D – Maps und Evaluation

Die Map-Konfiguration ist der kritischste Faktor. Jede Abweichung macht die Generalisierungsmessung unbrauchbar.

### D.1 Map-Aufteilung

| Nr. | Anforderung | Status |
|---|---|---|
| M1 | 200-300 Maps aus 900 auswählen (repräsentative Stichprobe) | [ ] erledigt |
| M2 | 80% Training / 20% Evaluation aufteilen | [ ] erledigt |
| M3 | Evaluation Maps **VOR erstem Training** einfrieren | [ ] erledigt |
| M4 | Gleiches Train- und Eval-Set für alle 7 Agenten | [ ] erledigt |
| M5 | Schwierigkeitsgrad gleichmäßig verteilt (Easy/Medium/Hard) | [ ] erledigt |
| M6 | Evaluation Maps NIE während Training laden | [ ] erledigt |

### D.2 Evaluation-Durchführung

| Nr. | Anforderung | Status |
|---|---|---|
| E1 | 100 Test-Episoden pro Agent auf Training-Maps | [ ] erledigt |
| E2 | 100 Test-Episoden pro Agent auf Evaluation-Maps | [ ] erledigt |
| E3 | 3 Trainingsruns pro Agent (Seeds: 42, 123, 7) | [ ] erledigt |
| E4 | Ergebnisse als Mittelwert ± Standardabweichung | [ ] erledigt |
| E5 | MaxStep pro Episode identisch für alle Agenten | [ ] bestätigt |

---

## E – Dokumentation

Alles was nicht dokumentiert ist, kann nicht reproduziert und nicht verteidigt werden.

| Nr. | Anforderung | Status |
|---|---|---|
| D1 | Alle YAML-Dateien versioniert (Git) | [ ] erledigt |
| D2 | Reward-Werte im Inspector dokumentiert (Screenshot) | [ ] erledigt |
| D3 | Hardware dokumentiert (CPU, GPU, RAM) | [ ] erledigt |
| D4 | ML-Agents Version dokumentiert | [ ] erledigt |
| D5 | Unity Version dokumentiert | [ ] erledigt |
| D6 | Evaluation Maps-Liste gespeichert | [ ] erledigt |
| D7 | TensorBoard Logs für alle Runs gespeichert | [ ] erledigt |
| D8 | Trainingszeit pro Agent notiert | [ ] erledigt |
