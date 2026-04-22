# Evaluationsplan
**Wissenschaftlicher Vergleich von RL-Agenten**
Unity ML-Agents · 3D-Labyrinth · Navigation & Hindernisüberwindung

| | |
|---|---|
| **Projekt** | Unity ML-Agents Studienarbeit |
| **Agenten** | 7 (MLP Baseline + 6 Varianten) |
| **Architekturen** | MLP · LSTM · Transformer |
| **Sensoren** | Ray · Kamera · Kombination |
| **Algorithmus** | PPO (Proximal Policy Optimization) |
| **Ziel** | Navigation + Hindernisüberwindung + Generalisierung |

---

## 1. Zielsetzung

Dieser Evaluationsplan definiert vollständig und verbindlich, welche Metriken gemessen werden, wie die Messung erfolgt und wie die Ergebnisse interpretiert werden. Er dient als interne Arbeitsgrundlage für den wissenschaftlich fairen Vergleich aller 7 RL-Agenten.

Die Evaluation verfolgt drei gleichwertige Hauptziele:
- **Architekturvergleich:** Ist LSTM oder Transformer besser für Navigation und Hindernisüberwindung?
- **Sensorvergleich:** Welcher Sensortyp (Ray, Kamera, Kombination) führt zu besserer Generalisierung?
- **Generalisierung:** Funktioniert der Agent auf Maps die er nie gesehen hat?

### 1.1 Agentenübersicht

| Agent | Sensor | Architektur | Vergleichsgruppe | Besonderheit |
|---|---|---|---|---|
| **Baseline** | Ray | MLP | Referenz | Kein Gedächtnis |
| **Agent 1** | Kamera | CNN + LSTM | Kamera | Visuell + Gedächtnis |
| **Agent 2** | Kamera | CNN + Transformer | Kamera | Visuell + Attention |
| **Agent 3** | Ray | LSTM | Ray | Distanz + Gedächtnis |
| **Agent 4** | Ray | Transformer | Ray | Distanz + Attention |
| **Agent 5** | Kamera + Ray | CNN + Transformer | Fusion | Multi-Sensor + Attention |
| **Agent 6** | Kamera + Ray | CNN + LSTM | Fusion | Multi-Sensor + Gedächtnis |

---

## 2. Evaluationsebene 1 – Performance

Die Performance-Ebene misst das Endergebnis nach abgeschlossenem Training. Sie liefert die wichtigsten Kennzahlen für den direkten Agentenvergleich.

### 2.1 Erfolgsrate ⭐ (wichtigste Metrik)

```
Erfolgsrate (%) = (Episoden mit Zielerreichung / Gesamtepisoden) × 100
```

- Messung: 100 Test-Episoden pro Agent pro Mapset
- Getrennte Messung für Training-Maps und Evaluation-Maps
- Ergebnis: Mittelwert ± Standardabweichung über 3 Trainingsruns
- Mindestanforderung: Erfolgsrate > 70% auf Training-Maps

### 2.2 Durchschnittlicher Reward pro Episode

Berücksichtigt alle Reward-Komponenten: Zielerreichung, Todesstrafen und Zeitstrafe pro Step.

- Reward-Komponenten: `+1.0` Ziel · `-1.0` Lava-Tod · `-1.0` Hole-Tod · `-0.001` pro Step
- Messung: Durchschnitt über alle Test-Episoden (erfolgreiche und gescheiterte)

### 2.3 Episodenlänge

- Durchschnittliche Anzahl Steps pro Episode
- Separate Auswertung: erfolgreiche vs. gescheiterte Episoden
- Kurze Episoden = effizienter Agent

### 2.4 Schritte bis Ziel

- Nur in erfolgreichen Episoden messen
- Direkter Effizienzindikator
- Vergleich mit theoretisch kürzestem Weg (A* Pfadlänge) möglich

### 2.5 Fehlerquote und Todesursachen

| Fehlertyp | Definition | Interpretation |
|---|---|---|
| Lava-Tod | Agent läuft in Lava-Trigger | Erkennt Gefahr nicht |
| Hole-Tod | Agent fällt in Loch (KillZone) | Planungsdefizit |
| Timeout | MaxStep erreicht ohne Ziel | Verloren / ineffizient |

### 2.6 Hindernisüberwindungsrate ⭐

```
Hindernisrate (%) = (Episoden mit mind. 1 Hindernisüberwindung / Gesamt) × 100
```

- Implementierung: Unity loggt ob Agent Hindernis-Trigger auslöst
- Getrennte Messung von der Erfolgsrate
- Kernkompetenz laut Aufgabenstellung

---

## 3. Evaluationsebene 2 – Lernverhalten

### 3.1 Reward-Kurve (TensorBoard)

- **TensorBoard Pfad:** `Environment/Cumulative Reward`
- Fragen: Steigt der Reward? Ab wann? Wie stabil?
- Export: TensorBoard CSV für spätere Auswertung
- Alle 7 Kurven überlagert in einem Diagramm

### 3.2 Konvergenzgeschwindigkeit

- Definition Konvergenz: Reward-Änderung < 2% über letzte 200.000 Steps
- Messung: Steps bis 80% der finalen Performance erreicht
- Erwartung: MLP konvergiert früh aber niedrig, Transformer später aber höher

### 3.3 Trainingsstabilität

- Metrik: Standardabweichung des Rewards über letzte 200.000 Steps
- LSTM: tendenziell stabiler als Transformer
- Sehr hohes Policy Loss = Hinweis auf Instabilität

### 3.4 Exploration vs. Exploitation (Entropy)

- **TensorBoard Pfad:** `Policy/Entropy`
- Hohe Entropy am Anfang = Agent erkundet aktiv ✅
- Niedrige Entropy am Ende = stabile Strategie ✅
- Durchgehend hohe Entropy = keine klare Strategie ❌

### 3.5 TensorBoard Metriken – Übersicht

| Metrik | TensorBoard Pfad | Was sie zeigt |
|---|---|---|
| **Cumulative Reward** | Environment/Cumulative Reward | Hauptlernkurve — Pflicht |
| Episode Length | Environment/Episode Length | Effizienz |
| Policy Loss | Losses/Policy Loss | Trainingsstabilität |
| Value Loss | Losses/Value Loss | Reward-Schätzung |
| Entropy | Policy/Entropy | Exploration |
| Learning Rate | Policy/Learning Rate | Lernratenabfall |

---

## 4. Evaluationsebene 3 – Generalisierung ⭐

Die Generalisierungsebene ist der wissenschaftlich wichtigste Teil. Sie zeigt ob der Agent tatsächlich navigieren gelernt hat oder die Training-Maps auswendig kennt.

### 4.1 Train vs. Test Split

| Kategorie | Beschreibung | Umfang |
|---|---|---|
| **Training Maps** | Werden während Training gesehen | 80% aller Maps |
| **Evaluation Maps** | Werden NIE beim Training gesehen | 20% aller Maps |

- Gleiches Evaluation-Testset für alle 7 Agenten
- Evaluation Maps **vor Trainingsstart einfrieren**
- 100 Test-Episoden pro Agent nach Training

### 4.2 Generalisierungslücke

```
Generalisierungslücke (%) = Erfolgsrate (Training) - Erfolgsrate (Evaluation)
```

| Lückengröße | Bewertung | Bedeutung |
|---|---|---|
| < 10% | Sehr gut | Agent generalisiert zuverlässig |
| 10 – 25% | Akzeptabel | Leichtes Overfitting |
| > 25% | Kritisch | Maps auswendig gelernt |

### 4.3 Erwartete Ergebnisse

- Transformer generalisiert besser als LSTM (größeres Kontextfenster)
- Ray-Sensor generalisiert besser als Kamera (keine Textur-Abhängigkeit)
- MLP Baseline zeigt größte Generalisierungslücke
- Fusion-Agenten abhängig von Datenlage

---

## 5. Evaluationsebene 4 – Effizienz & Stabilität

### 5.1 Trainingszeit

- Messung: Wanduhrzeit vom Start bis Abschluss
- Hardware dokumentieren: CPU, GPU, RAM, OS
- Anzahl paralleler Unity-Instanzen dokumentieren

### 5.2 Sample Efficiency

- Steps bis 70% Erfolgsrate erreicht
- Steps bis 80% Erfolgsrate erreicht
- Steps bis finale Performance konvergiert

### 5.3 Reproduzierbarkeit (3 Runs)

- **Run 1:** Seed 42
- **Run 2:** Seed 123
- **Run 3:** Seed 7
- Ergebnis: Mittelwert ± Standardabweichung

| Agent | Run 1 | Run 2 | Run 3 | Mittelwert | Std.-Abw. |
|---|---|---|---|---|---|
| MLP Baseline | | | | | |
| Agent 1 | | | | | |
| Agent 2 | | | | | |
| Agent 3 | | | | | |
| Agent 4 | | | | | |
| Agent 5 | | | | | |
| Agent 6 | | | | | |

---

## 6. Wissenschaftliche Vergleichsfragen

### 6.1 Architekturvergleich

| Nr. | Vergleich | Forschungsfrage |
|---|---|---|
| F1 | Agent 1 vs. 2 (Kamera) | Bringt Transformer bei Bilddaten besseres Gedächtnis als LSTM? |
| F2 | Agent 3 vs. 4 (Ray) | Ist Transformer-Attention bei Distanzdaten besser als LSTM? |
| F3 | Agent 5 vs. 6 (Fusion) | Welche Architektur profitiert stärker von Multi-Sensor-Fusion? |

### 6.2 Sensorvergleich

| Nr. | Vergleich | Forschungsfrage |
|---|---|---|
| F4 | Agent 1+2 vs. 3+4 | Kamera oder Ray: welcher Sensor führt zu besserer Generalisierung? |
| F5 | Agent 3+4 vs. 5+6 | Verbessert ein zweiter Sensor die Performance signifikant? |

### 6.3 Gedächtnisvergleich

| Nr. | Vergleich | Forschungsfrage |
|---|---|---|
| F6 | Baseline vs. alle anderen | Bringt Gedächtnis messbare Verbesserung gegenüber MLP? |
| F7 | LSTM vs. Transformer | Generalisiert Attention besser als rekurrentes Gedächtnis? |

---

## 7. Visualisierung

### Pflicht (TensorBoard)
- Reward-Kurven aller 7 Agenten überlagert
- Episode Length aller 7 Agenten überlagert
- Policy Loss und Entropy je Agent
- Export als PNG

### Sehr empfohlen (Python/Excel)
- Balkendiagramm: Erfolgsrate Training vs. Evaluation
- Balkendiagramm: Generalisierungslücke pro Agent
- Liniendiagramm: Konvergenzgeschwindigkeit
- Fehlerverteilung: Lava / Hole / Timeout pro Agent

### Optional (Trajektorien & Heatmaps)
- Unity loggt Agentposition alle N Steps
- Python plottet Bewegungspfade
- Heatmap: welche Bereiche wie häufig besucht

---

## 8. Qualitative Analyse

### Was zu beschreiben ist
- Typische Verhaltensstrategien jedes Agenten
- Häufige Fehler und Schwächenmuster
- Umgang mit Hindernissen
- Reaktion auf Sackgassen
- Unterschiede bekannte vs. unbekannte Maps

### Erwartete Verhaltensunterschiede

| Agententyp | Erwartetes Verhalten |
|---|---|
| MLP Baseline | Reaktiv, dreht im Kreis, kein Gedächtnis |
| LSTM-Agenten | Stabil, kurzes Gedächtnis, kann steckenbleiben |
| Transformer | Flexibler, längeres Kontextfenster, anfangs instabil |
| Kamera-Agenten | Reagiert auf visuelle Reize, Probleme bei unbekannten Layouts |
| Ray-Agenten | Präzise Hinderniserkennung, kein visuelles Verständnis |
| Fusion-Agenten | Kombination beider Stärken, aber langsameres Training |

---

## 9. Finale Ergebnistabelle (Vorlage)

| Agent | Erfolg Train | Erfolg Eval | Gen.-Lücke | Hindernis-Rate | Ø Steps | Konvergenz |
|---|---|---|---|---|---|---|
| MLP Baseline | | | | | | |
| Agent 1 | | | | | | |
| Agent 2 | | | | | | |
| Agent 3 | | | | | | |
| Agent 4 | | | | | | |
| Agent 5 | | | | | | |
| Agent 6 | | | | | | |
