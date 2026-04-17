# Forschungsplan: Sensor- und Architekturvergleich in RL-basierter Labyrinth-Navigation
## Milestones 6–11

**Projekt:** KI-Agenten — Unity ML-Agents Labyrinth  
**Team:** Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker  
**Engine:** Unity 2021.3 · Framework: ML-Agents · Algorithmus: PPO  
**Stand (Ausgangslage):** Milestone 5 abgeschlossen — MLP-Baseline trainiert, Reward-System stabil, 5 statische Maps vorhanden

---

## Inhaltsverzeichnis

1. [Motivation & Kontext](#1-motivation--kontext)
2. [Wissenschaftliche Rahmung](#2-wissenschaftliche-rahmung)
3. [Experimentelles Design](#3-experimentelles-design)
4. [Evaluationsprotokoll](#4-evaluationsprotokoll)
5. [Architektur-Übersicht](#5-architektur-übersicht)
6. [Milestone 6 — Map-System & Experiment-Umgebung](#6-milestone-6--map-system--experiment-umgebung)
7. [Milestone 7 — Transformer-Architektur & Ray-Agenten](#7-milestone-7--transformer-architektur--ray-agenten)
8. [Milestone 8 — Kamerasensor-Integration](#8-milestone-8--kamerasensor-integration)
9. [Milestone 9 — CNN-Architektur & Kamera-Agenten](#9-milestone-9--cnn-architektur--kamera-agenten)
10. [Milestone 10 — Multi-Sensor Fusion & vollständige Trainingsmatrix](#10-milestone-10--multi-sensor-fusion--vollständige-trainingsmatrix)
11. [Milestone 11 — Wissenschaftliche Auswertung & Dokumentation](#11-milestone-11--wissenschaftliche-auswertung--dokumentation)
12. [GitHub Issues Übersicht](#12-github-issues-übersicht)
13. [Risiken & Gegenmaßnahmen](#13-risiken--gegenmaßnahmen)
14. [Real-World-Transfer](#14-real-world-transfer)

---

## 1. Motivation & Kontext

### Ausgangssituation

Nach Abschluss von Milestone 5 besitzt das Projekt:
- Eine funktionierende Unity-Labyrinthwelt mit 5 statischen Maps
- Einen RL-Agenten mit Ray-basierter Wahrnehmung (VectorSensor + RayPerceptionSensor3D)
- 13 manuelle Observations (Velocity, isGrounded, Zielrichtung, Boden-Sensor)
- Ein stabiles Reward-System (+1 Ziel, -1 Tod, Step-Penalty)
- Eine trainierte **MLP-Baseline** als Referenzpunkt

### Erweiterungsmotivation

Die bisherige Arbeit beantwortet noch nicht, wie sich unterschiedliche **Wahrnehmungsmodalitäten** (Ray vs. Kamera) und **Temporal-Architekturen** (LSTM vs. Transformer) auf das Lernverhalten auswirken. Genau das ist der Kern des Forschungsvorhabens in M6–M11:

> *Wie beeinflussen Sensortyp und Netzwerkarchitektur das Lern- und Navigationsverhalten eines RL-Agenten in einer komplexen, prozedural generierten Labyrinthwelt?*

### Bezug zu realen Anwendungen

Das Labyrinth-Szenario ist eine kontrollierte Abstraktion realer Navigationsprobleme:

| Labyrinth | Reales Szenario |
|-----------|-----------------|
| Korridore & Wände | Gänge in Restaurants, Lagern, Krankenhäusern |
| Lava / Holes | Treppen, nasse Böden, Schächte |
| Prozedurales Layout | Täglich veränderte Umgebung (umgeräumte Möbel, neue Hindernisse) |
| Goal-Navigation | Tisch anfahren (Kellnerroboter), Regal ansteuern (Logistik) |
| Episodenende | Abgeschlossene Lieferfahrt |

Ein Serviceroboter (z.B. in einem Restaurant) benötigt genau diese Fähigkeiten: Navigation in engen Gängen, Hinderniserkennung, Anpassung an veränderte Layouts. Die Frage, welche Sensor-/Architektur-Konfiguration am besten verallgemeinert, ist direkt auf diese Anwendung übertragbar.

---

## 2. Wissenschaftliche Rahmung

### 2.1 Forschungsfragen

**RQ1 — Sensortyp:**
> Welchen Einfluss hat der Sensortyp (Ray / Kamera / kombiniert) auf Lerngeschwindigkeit und Erfolgsrate in einem prozeduralen Labyrinth-Navigationsproblem?

**RQ2 — Temporal-Architektur:**
> Wie unterscheiden sich LSTM und Transformer in ihrer Fähigkeit, temporale Abhängigkeiten bei unterschiedlichen Sensoreingaben zu nutzen?

**RQ3 — Sensor-Fusion:**
> Verbessert die Kombination mehrerer Sensortypen (Multi-Sensor) die Robustheit und Generalisierung auf unbekannten Maps im Vergleich zu Einzelsensor-Agenten?

**RQ4 — Praktische Übertragbarkeit:**
> Welche Sensor-Architektur-Konfiguration eignet sich unter Berücksichtigung von Leistung, Hardwareaufwand und Latenz am besten für den Transfer auf reale Navigationsprobleme?

### 2.2 Hypothesen

**H1 (Multi-Sensor-Vorteil):**
Multi-Sensor-Agenten (A5, A6) erzielen höhere Erfolgsraten auf held-out Maps als Einzelsensor-Agenten, weil sie redundante und komplementäre Information aus zwei Modalitäten nutzen können.

**H2 (Transformer bei Kamera):**
Transformer-Agenten übertreffen LSTM-Agenten stärker bei Kamera-Observations als bei Ray-Observations, da Pixel-Sequenzen komplexere zeitliche Strukturen aufweisen, von denen der Attention-Mechanismus stärker profitiert.

**H3 (Ray-Konvergenz):**
Ray-only-Agenten (A3, A4) konvergieren schneller als Kamera-Agenten (A1, A2), generalisieren jedoch schlechter auf prozedural generierte Maps, da Ray-Sensoren strukturell auf die spezifischen Tag-Konfigurationen der Trainingsumgebung ausgerichtet sind.

**H4 (Beste Gesamtkonfiguration):**
CNN+Transformer mit kombiniertem Sensor (A5) erzielt die höchste Erfolgsrate auf held-out Maps und ist damit die robusteste Konfiguration für komplexe Navigationsaufgaben.

### 2.3 Theoretischer Hintergrund

#### Reinforcement Learning mit PPO
Das Projekt verwendet **Proximal Policy Optimization (PPO)** im Actor-Critic-Framework. Der Actor wählt Aktionen (Policy), der Critic bewertet Zustände (Value Function). PPO begrenzt Policy-Updates durch Clipping (ε=0.2), was Trainingsinstabilität verhindert. Grundlage: Schulman et al. (2017).

#### LSTM für sequentielle Entscheidungen
**Long Short-Term Memory** (Hochreiter & Schmidhuber, 1997) verarbeitet Sequenzen durch Gates (Forget, Input, Output), die selektiv Information über Zeitschritte weitergeben. In ML-Agents verfügbar über `use_recurrent: true`. Vorteil: Implizites Gedächtnis ohne expliziten Sequenz-Buffer. Nachteil: Kein paralleles Training über Sequenzpositionen, begrenzte Langzeitabhängigkeiten.

#### Transformer für RL
**Transformer-Encoder** (Vaswani et al., 2017) nutzen Self-Attention, um über eine gesamte Sequenz vergangener Observations zu attendieren. Im RL-Kontext ermöglicht das zeitliche Mustererkennung: "Ich laufe seit 3 Steps auf Lava zu" → früher Reaktion. Relevant: Chen et al. (2021) Decision Transformer, Parisotto et al. (2020) GTrXL.

#### CNN für visuelle Observations
**Convolutional Neural Networks** (LeCun et al., 1998) extrahieren hierarchische Features aus Pixel-Daten. In ML-Agents aktiviert der CameraSensor automatisch CNN-Schichten (Nature-CNN nach Mnih et al., 2015: 3 Conv-Layer + FC). Custom CNNs erlauben mehr Kontrolle über Architektur und ermöglichen transparente wissenschaftliche Dokumentation.

---

## 3. Experimentelles Design

### 3.1 Agenten-Matrix

| Agent | Sensor | Visual Encoder | Temporal | Vergleichsgruppe |
|-------|--------|----------------|----------|------------------|
| **Baseline** | Ray (VectorSensor) | — | MLP | Referenz (M5) |
| **A3** | Ray | — | LSTM | Ray-Gruppe |
| **A4** | Ray | — | Transformer | Ray-Gruppe |
| **A1** | Kamera | CNN | LSTM | Kamera-Gruppe |
| **A2** | Kamera | CNN | Transformer | Kamera-Gruppe |
| **A6** | Kamera + Ray | CNN | LSTM | Multi-Sensor |
| **A5** | Kamera + Ray | CNN | Transformer | Multi-Sensor |

**Begründung der Reihenfolge:**
Ray-Agenten zuerst (M7), da sie auf der bestehenden Infrastruktur aufbauen. Kamera-Agenten danach (M8–M9), da sie neue Unity-Komponenten und CNN erfordern. Multi-Sensor zuletzt (M10), da sie beides kombinieren.

**Warum kein CNN für Ray-Sensoren?**
Ray-Sensoren liefern 1D-Float-Vektoren (13 Werte). CNN-Architekturen sind für 2D-Strukturen (Pixel-Gitter) ausgelegt — auf 1D-Daten hätte ein Conv1D keinen Mehrwert gegenüber einem FC-Layer. LSTM und Transformer können direkt auf den Float-Vektor angewendet werden.

### 3.2 Paarweise Vergleiche

**Vergleich i — Architektur innerhalb Ray-Gruppe:**
`A3 (Ray+LSTM)` vs. `A4 (Ray+Transformer)` → RQ2 für niedrig-dimensionale Observations

**Vergleich ii — Architektur innerhalb Kamera-Gruppe:**
`A1 (Kamera+CNN+LSTM)` vs. `A2 (Kamera+CNN+Transformer)` → RQ2 für visuelle Observations

**Vergleich iii — Architektur innerhalb Multi-Sensor-Gruppe:**
`A6 (Multi+CNN+LSTM)` vs. `A5 (Multi+CNN+Transformer)` → RQ2 für kombinierte Observations

**Vergleich iv — Sensor-Typ (beste Konfiguration je Gruppe):**
`Bester Ray-Agent` vs. `Bester Kamera-Agent` vs. `Bester Multi-Sensor-Agent` → RQ1 & RQ3

**Vergleich v — Gegen Baseline:**
Alle Agenten vs. MLP-Baseline → Mehrwert temporaler Architekturen

### 3.3 Kontrollierte Variablen

Um Konfundierung zu vermeiden, werden folgende Parameter für alle Agenten **identisch** gehalten:

- Trainingsschritte: **5.000.000 Steps**
- Reward-Struktur: +1 (Ziel), −1 (Tod), −0.001/Step (Zeitstrafe)
- Map-Algorithmus: Recursive Backtracking (Haupttraining)
- Evaluation: 3 fixe held-out Maps (geseedete Seeds, nie im Training gesehen)
- RL-Algorithmus: PPO
- Kernhyperparameter: lr=3e-4, gamma=0.99, epsilon=0.2, lambd=0.95
- Wiederholungen: **5 unabhängige Runs** pro Konfiguration (Seeds: 42, 123, 456, 789, 1337)

---

## 4. Evaluationsprotokoll

*Dieses Protokoll ist bindend für alle Experimente in M7–M10. Es wird in M6.3 final festgelegt und darf danach nicht mehr geändert werden (Schutz vor nachträglicher Metrik-Auswahl).*

### 4.1 Primärmetriken

| Metrik | Definition | Messzeitpunkt |
|--------|-----------|---------------|
| **Erfolgsrate** | Anteil Episoden mit Goal-Erreichen in den letzten 100 Episoden | Am Ende jedes Runs |
| **Konvergenzgeschwindigkeit** | Steps bis erstmaliges Erreichen von 80% Erfolgsrate | Während Training |
| **Kollisionsrate** | Anteil Episoden die durch Lava/Hole enden | Am Ende jedes Runs |
| **Mean Episodenlänge** | Durchschnittliche Schritte pro Episode (letzte 100) | Am Ende jedes Runs |
| **Cumulative Reward** | TensorBoard `cumulative_reward`-Kurve | Kontinuierlich |

### 4.2 Generalisierungsmetriken (held-out Maps)

Nach Abschluss des Trainings werden alle Agenten auf den 3 held-out Maps evaluiert (je 100 Episoden):
- **Generalisierungs-Erfolgsrate:** Erfolgsrate auf unbekannten Maps
- **Overfitting-Index:** Trainings-Erfolgsrate − Generalisierungs-Erfolgsrate

### 4.3 Statistische Auswertung

- **Test:** Mann-Whitney U (nicht-parametrisch, da RL-Rewards nicht normalverteilt)
- **Korrektur:** Bonferroni für multiple Vergleiche (10 paarweise Tests → α' = 0.005)
- **Effektgröße:** Cliff's Delta (nicht-parametrisches Pendant zu Cohen's d)
- **Konfidenzintervalle:** 95% Bootstrap-CI auf allen aggregierten Metriken
- **Visualisierung:** Lernkurven mit CI-Band, Boxplots Erfolgsrate, Heatmap Generalisierung

### 4.4 Test-Map-Suite (held-out)

Drei fixe Evaluation-Maps werden in M6.3 generiert und eingecheckt:
- `eval_map_maze_seed999.asset` — Recursive Backtracking
- `eval_map_cave_seed999.asset` — Cellular Automata
- `eval_map_room_seed999.asset` — Room-Placement

Kein Agent wird während des Trainings auf diesen Maps evaluiert. Sie sind ausschließlich für den abschließenden Generalisierungstest.

---

## 5. Architektur-Übersicht

### 5.1 Ray-only Agenten (A3, A4)

```
RayPerceptionSensor3D  →  Float-Vektor (automatisch)
VectorSensor           →  [13 Floats: velocity, grounded, goal-dir, ground-sensor]
                                    ↓
                          [Concat → Observation-Vektor]
                                    ↓
                     ┌─────────────┴─────────────┐
                  LSTM (A3)              Transformer (A4)
               memory_size=128          seq_len=8, d_model=64
                     └─────────────┬─────────────┘
                                    ↓
                            Actor / Critic (PPO)
```

### 5.2 Kamera-Agenten (A1, A2)

```
CameraSensor (84×84, Graustufen, Stack=4)  →  Pixel-Tensor [4, 84, 84]
                                                        ↓
                                               LabyrinthCNN (Nature-CNN)
                                               3× Conv + FC → [256]
                                                        ↓
                                     ┌──────────────────┴──────────────────┐
                                  LSTM (A1)                       Transformer (A2)
                               memory_size=128                seq_len=8, d_input=256
                                     └──────────────────┬──────────────────┘
                                                        ↓
                                                Actor / Critic (PPO)
```

### 5.3 Multi-Sensor Agenten (A5, A6) — Late Fusion

```
CameraSensor (84×84, Graustufen, Stack=4)       VectorSensor [13]
              ↓                                        ↓
     LabyrinthCNN → [256]                     (direkt weiterleiten)
              ↓                                        ↓
         LayerNorm                               LayerNorm
              └──────────────────┬────────────────────┘
                                 ↓
                        Concat → FC(269→256)       ← Gemeinsamer Latent-Vektor
                                 ↓
                  ┌──────────────┴──────────────┐
               LSTM (A6)              Transformer (A5)
               memory_size=128        seq_len=8, d_model=256
                  └──────────────┬──────────────┘
                                 ↓
                         Actor / Critic (PPO)
```

**Begründung Late Fusion:**
Early Fusion (direkte Pixel+Float-Konkatenation) würde eine extreme dimensionale Imbalance erzeugen (28224 Pixel-Werte vs. 13 Float-Werte). Late Fusion projiziert beide Modalitäten zuerst in einen gleichgroßen Latent-Raum, bevor sie konkateniert werden. LayerNorm verhindert, dass eine Modalität die Gradienten dominiert.

### 5.4 Transformer-Konfiguration (Referenz)

```python
class TransformerEncoder(nn.Module):
    """
    Input:  [batch, seq_len, obs_size]  z.B. [512, 8, 13] für Ray
                                         oder [512, 8, 256] für CNN-Output
    Output: [batch, 128]
    """
    def __init__(self, obs_size, d_model=64, nhead=4, num_layers=2, seq_len=8):
        super().__init__()
        self.embedding   = nn.Linear(obs_size, d_model)
        self.pos_enc     = nn.Embedding(seq_len, d_model)  # gelernte Positional Encoding
        encoder_layer    = nn.TransformerEncoderLayer(
            d_model=d_model, nhead=nhead,
            dim_feedforward=128, dropout=0.1, batch_first=True
        )
        self.transformer = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.output_proj = nn.Linear(d_model, 128)

    def forward(self, obs_sequence):
        B, T, _ = obs_sequence.shape
        positions = torch.arange(T, device=obs_sequence.device)
        x = self.embedding(obs_sequence) + self.pos_enc(positions)
        x = self.transformer(x)
        return self.output_proj(x[:, -1, :])  # letzter Token = aktuelle Entscheidung
```

### 5.5 CNN-Konfiguration (Referenz — Nature-CNN nach Mnih et al. 2015)

```python
class LabyrinthCNN(nn.Module):
    """
    Input:  [batch, stack, H, W]  z.B. [512, 4, 84, 84]
    Output: [batch, 256]
    """
    def __init__(self):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(4, 32, kernel_size=8, stride=4),   # → [32, 20, 20]
            nn.ReLU(),
            nn.Conv2d(32, 64, kernel_size=4, stride=2),  # → [64, 9, 9]
            nn.ReLU(),
            nn.Conv2d(64, 64, kernel_size=3, stride=1),  # → [64, 7, 7]
            nn.ReLU(),
            nn.Flatten(),
        )
        self.fc = nn.Linear(64 * 7 * 7, 256)

    def forward(self, x):
        return F.relu(self.fc(self.conv(x)))
```

---

## 6. Milestone 6 — Map-System & Experiment-Umgebung

**Ziel:** Vollautomatische prozedurale Map-Generierung einführen, Spawn/Obstacle-Logik für faire Experimente reparieren, und das Evaluationsprotokoll als bindendes Dokument festlegen — alles *bevor* das erste neue Modell trainiert wird.

**Warum zuerst?** Ohne reproduzierbare, faire Trainingsumgebung sind alle nachfolgenden Ergebnisse nicht vergleichbar. M6 ist das Fundament des gesamten Experiments.

### Issues

#### #110 — M6.1: Prozeduralen MapGenerator mit 3 Algorithmen implementieren

**Kernaufgabe:** `MapSelectionMode.Procedural` im bestehenden `MapGenerator` implementieren. Statt ein `MapData`-Asset zu laden, wird ein leeres `MapData`-Objekt zur Laufzeit befüllt (s. `Dokumentation/ProceduralMapGeneration.md`).

**Algorithmen:**

*1. Recursive Backtracking (Primärer Trainings-Algorithmus)*
- Tiefensuche durch das Grid → erzeugt echte Labyrinth-Korridore mit garantierter Lösbarkeit
- Vorteil: Kein BFS-Check nötig, direkt lösbar by design
- Einsatz: Haupttraining aller Agenten

*2. Cellular Automata (Eval-Map-Variante)*
- Zufälliges Rauschen → mehrfache Glättungs-Iterationen → organische, höhlenartige Layouts
- Erfordert abschließende BFS-Validierung
- Einsatz: Eine der 3 held-out Evaluation-Maps

*3. Room-Placement + MST Corridor Connection (Eval-Map-Variante)*
- Räume zufällig platzieren, per Minimum Spanning Tree verbinden
- Klassischer Dungeon-Ansatz mit strukturierten Bereichen
- Einsatz: Eine der 3 held-out Evaluation-Maps

**Technische Details:**
- Seed-Parameter für deterministische Reproduzierbarkeit
- BFS-Lösbarkeitscheck nach jeder Generierung (`HasWalkablePath` bereits vorhanden)
- Mindestabstand Spawn ↔ Goal: > 40% der Map-Diagonale
- Performance-Ziel: Generierung < 100ms pro Map

#### #111 — M6.2: Obstacle- und Goal-Spawn-Logik für faire Experimente überarbeiten

**Kontext:** Issues #106 (Obstacle-Sinn unklar) und #108 (Goal-Spawn-Logik) haben Probleme identifiziert, die Konfundierungsvariablen erzeugen.

**Obstacle-Logik (#106):**
- Obstacles (Lava, Holes) sollen als konfigurierbare "Challenges" dienen: Mindest-/Maximalanzahl pro Map als Inspector-Parameter
- Obstacle-Dichte als explizite Schwierigkeitsgrad-Variable dokumentieren
- Platzierungsstrategie: Zufällig auf Floor-Zellen, jedoch nicht auf kritischem Pfad (Spawn→Goal)

**Goal-Spawn-Logik (#108):**
- Goal darf nie direkt neben Spawn spawnen (Mindestabstand konfigurierbar)
- Goal-Position variiert nach jeder Episode (bereits implementiert, aber mit Bugs)
- BFS-Erreichbarkeit nach Goal-Platzierung verifizieren (bereits vorhanden, sicherstellen dass aktiv)
- Kein "unmöglicher" Episodenstart möglich

#### #112 — M6.3: Evaluationsprotokoll & Reproduzierbarkeits-Framework definieren

**Kernaufgabe:** Das in Abschnitt 4 dieses Dokuments beschriebene Evaluationsprotokoll als eigenständiges Markdown-Dokument (`Dokumentation/Evaluationsprotokoll.md`) im Repo festhalten.

**Inhalt des Protokolls:**
- Alle Metriken (Primär + Generalisierung) mit exakter Definition
- Statistische Testmethoden (Mann-Whitney U, Bonferroni, Cliff's Delta)
- Seed-Liste für alle 5 Runs
- 3 held-out Evaluation-Maps generieren und als Assets einchecken
- TensorBoard-Logging für alle Metriken verifizieren
- Ordnerstruktur für Results: `results/agentX/runY/`

**Wichtig:** Dieses Issue muss *abgeschlossen* sein bevor M7 beginnt. Das Protokoll darf danach nicht mehr geändert werden.

---

## 7. Milestone 7 — Transformer-Architektur & Ray-Agenten

**Ziel:** Den Transformer als Custom Policy in ML-Agents integrieren und die erste vollständige Vergleichsgruppe (A3: Ray+LSTM vs. A4: Ray+Transformer) trainieren und auswerten.

**Warum Ray-Agenten zuerst?** Sie bauen auf der bestehenden Sensor-Infrastruktur auf — keine neuen Unity-Komponenten nötig. Der Transformer kann isoliert von CNN-Komplexität validiert werden.

### Issues

#### #113 — M7.1: Custom Transformer Policy implementieren (BufferSensor + PyTorch)

**Unity-Seite (C#):**
`BufferSensorComponent` zu `LabyrinthAgent.cs` hinzufügen:
- Observable Size: 13 (Observation-Vektor-Größe)
- Max Num Observables: 8 (Sequenzfenster = 8 vergangene Timesteps)
- `Initialize()` und `CollectObservations()` erweitern (Code-Referenz: `Dokumentation/Transformer_Integration.md`)

**Python-Seite:**
- `training/transformer_policy.py` — `TransformerEncoder`-Klasse (s. Abschnitt 5.4)
- Integration in ML-Agents Custom Policy API
- `config/labyrinth_transformer.yaml` erstellen (sequence_length=8, memory_size=64)

**Validierung vor vollem Training:**
- Unit-Test mit Dummy-Input: `[batch=2, seq=8, obs=13]` → Forward-Pass ohne Fehler
- Kurztraining (100k Steps): Reward-Signal steigt an → Training funktioniert
- TensorBoard: Keine NaN in Loss/Gradienten

#### #114 — M7.2: Ray-Agenten trainieren: LSTM (A3) & Transformer (A4)

**Agent 3 — Ray + LSTM:**
- Sensor: Bestehender VectorSensor (13 obs) + RayPerceptionSensor3D
- Architektur: ML-Agents built-in LSTM (`use_recurrent: true`, `memory_size: 128`)
- Konfiguration: `config/agent3_ray_lstm.yaml`

**Agent 4 — Ray + Transformer:**
- Sensor: VectorSensor (13 obs) + BufferSensor (Sequenz, aus M7.1)
- Architektur: Custom TransformerEncoder aus M7.1
- Konfiguration: `config/agent4_ray_transformer.yaml`

**Trainingsparameter (laut Protokoll M6.3):**
- 5.000.000 Steps · 5 Runs · Seeds: 42, 123, 456, 789, 1337
- Prozedurale Maps (Recursive Backtracking)
- Checkpoints alle 500k Steps

#### #115 — M7.3: Zwischenauswertung Ray-Gruppe: A3 vs. A4

**Quantitative Analyse:**
- Erfolgsrate: Mean ± 95% Bootstrap-CI, Mann-Whitney U Test
- Konvergenzgeschwindigkeit: Steps bis 80% Erfolgsrate
- Reward-Kurvenvergleich mit CI-Band
- Kollisionsrate auf held-out Maps

**Qualitative Analyse:**
- Verhaltensmuster im Replay: Navigiert ein Modell vorausschauender?
- Lernkurven-Charakteristik: Wer lernt schneller/stabiler?

**Dokumentation:**
- Auswertungs-Notebook: `analysis/ray_group_comparison.ipynb`
- Zwischenfazit (½ Seite): Stützen die Daten H2 und H3?
- Hinweise für Hyperparameter-Anpassungen in M9/M10 falls nötig

---

## 8. Milestone 8 — Kamerasensor-Integration

**Ziel:** Den CameraSensor als zweite Wahrnehmungsmodalität in Unity einrichten und erste Trainingsläufe zur Verifikation der CNN-Pipeline durchführen.

**Warum als eigener Milestone?** Der CameraSensor erfordert neue Unity-Komponenten (RenderTexture, Camera-Child-Objekt, Inspector-Konfiguration) und ändert den Observation-Typ fundamental von Float-Vektor zu Pixel-Tensor. Diese Infrastruktur muss stabil stehen bevor Custom-CNN und vollständige Trainingsdurchläufe stattfinden.

### Issues

#### #116 — M8.1: CameraSensor in Unity einrichten (Prefab, RenderTexture, Stacking)

**Unity-Konfiguration:**
- Child-Objekt "AgentCamera" am Agent-GameObject erstellen
- `CameraComponent` + `CameraSensorComponent` hinzufügen
- Kameraposition: Leicht über dem Agenten, Blick in Bewegungsrichtung (Ego-Perspektive)

**Parameter (wissenschaftlich begründet):**

| Parameter | Wert | Begründung |
|-----------|------|-----------|
| Auflösung | 84×84 px | ML-Agents Standard; DQN-Benchmark (Mnih et al. 2015) |
| Farbmodus | Grayscale (1 Kanal) | Labyrinth hat keine farbrelevante Information; reduziert CNN-Komplexität; vergleichbar mit Ray (keine Farb-Info) |
| Observation Stacks | 4 | Bewegungserkennung ohne explizites Gedächtnis; analog zu DQN Frame-Stacking |
| Kamerawinkel | Richtung vorwärts, leicht nach unten | Boden (Lava/Holes) sichtbar; Korridor-Struktur erkennbar |

**Agenten-Varianten-Management:**
- Separate Agent-Prefabs für: Ray-only, Kamera-only, Kamera+Ray
- Oder: Inspector-Flag für Sensor-Konfiguration (flexibler, weniger Prefab-Duplikation)

**Designentscheidung dokumentieren:** Warum 84×84 statt 64×64 oder 128×128? Warum Grayscale statt RGB?

#### #117 — M8.2: Kamera-Agenten initial trainieren & CNN-Funktion verifizieren

**Ziel:** Verifikation, nicht vollständiges Training. Sicherstellen dass der komplette Pipeline (CameraSensor → CNN → LSTM/Transformer → PPO) fehlerfrei funktioniert.

**Built-in CNN (ML-Agents Default):**
Bei Verwendung von CameraSensor fügt ML-Agents automatisch Nature-CNN-Schichten ein. Das ist die Ausgangskonfiguration für den Verifikationsrun.

**Kurztraining (500k Steps je Agent):**
- A1 (Kamera+LSTM): Reward-Kurve steigt nach ~200k Steps → CNN lernt
- A2 (Kamera+Transformer): Reward-Kurve steigt nach ~200k Steps
- TensorBoard: Keine NaN in Loss/Gradienten (explizit prüfen!)

**Messungen für M9-Planung:**
- Trainingszeit pro Step (CPU vs. GPU) → Basis für Zeitplanung
- Peak Memory Usage
- Falls Trainingszeit kritisch: Auflösung auf 64×64 testen (dokumentieren!)

---

## 9. Milestone 9 — CNN-Architektur & Kamera-Agenten

**Ziel:** Custom CNN-Policy implementieren (mehr Kontrolle als Default-CNN), und A1 (CNN+LSTM) sowie A2 (CNN+Transformer) vollständig trainieren. Zweite Vergleichsgruppe des Experiments abschließen.

### Issues

#### #118 — M9.1: Custom CNN Policy implementieren (PyTorch, ONNX-Export)

**Architektur:** Nature-CNN nach Mnih et al. (2015) — bewährte Referenzarchitektur für RL auf Pixel-Input, wissenschaftlich gut dokumentiert.

```
Input [4, 84, 84] → Conv(32, 8×8, stride=4) → ReLU → [32, 20, 20]
                  → Conv(64, 4×4, stride=2) → ReLU → [64, 9, 9]
                  → Conv(64, 3×3, stride=1) → ReLU → [64, 7, 7]
                  → Flatten → FC(3136 → 256) → ReLU → Output [256]
```

**Begründung Custom vs. Default:**
Das ML-Agents Default-CNN ist eine Black Box — Parameter nicht dokumentiert, keine Kontrolle über Architektur. Ein Custom CNN erlaubt transparente Dokumentation für den Bericht und ermöglicht spätere Ablationen (Tiefe, Kernel-Größe).

**Dateien:**
- `training/cnn_encoder.py` — `LabyrinthCNN`-Klasse
- In `transformer_policy.py` importieren und als Visual Encoder einsetzen
- ONNX-Export für Unity-Deployment (Barracuda 2.0.0 kompatibel)

#### #119 — M9.2: Kamera-Agenten vollständig trainieren: CNN+LSTM (A1) & CNN+Transformer (A2)

**Agent 1 — Kamera + CNN + LSTM:**
- Visual: LabyrinthCNN (M9.1) → [256]
- Temporal: LSTM (memory_size=128, sequence_length=8)
- Konfiguration: `config/agent1_camera_lstm.yaml`

**Agent 2 — Kamera + CNN + Transformer:**
- Visual: LabyrinthCNN (M9.1) → [256]
- Temporal: TransformerEncoder (d_input=256, angepasst)
- Konfiguration: `config/agent2_camera_transformer.yaml`

**Trainingsparameter:** 5.000.000 Steps · 5 Runs · Seeds identisch zu M7

**Trainingszeit-Hinweis:** CNN erhöht Step-Zeit signifikant (~5–10× gegenüber Ray-only). Bei CPU-Training: Auflösung ggf. auf 64×64 reduzieren und dokumentieren.

#### #120 — M9.3: Kamera-Gruppe auswerten: A1 (CNN+LSTM) vs. A2 (CNN+Transformer)

**Kamera-interner Vergleich:**
Gleiche Auswertungsmethodik wie M7.3 — Erfolgsrate, Konvergenz, Mann-Whitney U, Cliff's Delta.

**Gruppenübergreifender Vergleich (erste Übersicht):**
Ray-Gruppe (A3+A4) vs. Kamera-Gruppe (A1+A2) — explorativer Vergleich, Caveat dokumentieren: Innerhalb der Gruppen gibt es noch Architekturunterschiede, daher ist dies ein Gruppenmedian-Vergleich, kein sauberer Sensor-Vergleich.

**Notebook:** `analysis/camera_group_comparison.ipynb`

**Zwischenfazit:** Stützen die Daten H2 (Transformer > LSTM bei Kamera) stärker als bei Ray?

---

## 10. Milestone 10 — Multi-Sensor Fusion & vollständige Trainingsmatrix

**Ziel:** Die Multi-Sensor-Agenten A5 und A6 implementieren und trainieren. Anschließend sicherstellen, dass alle 7 Konfigurationen vollständige, konsistente Trainingsdaten haben — bevor die finale Auswertung beginnt.

### Issues

#### #121 — M10.1: Multi-Sensor Fusion Architektur implementieren

**Late Fusion Pipeline** (s. Abschnitt 5.3):

```
Schritt 1: Modalitäten projizieren
  CameraSensor → LabyrinthCNN → [256] → LayerNorm
  VectorSensor → [13] → LayerNorm

Schritt 2: Zusammenführen
  Concat([256], [13]) → [269] → FC(269→256) → ReLU → Gemeinsamer Latent-Vektor [256]

Schritt 3: Temporal
  [256] → LSTM (A6) oder Transformer (A5) → Actor/Critic
```

**Gradient-Balance:** Sicherstellen dass beide Modalitäten gleichwertig zu Gradienten beitragen. LayerNorm vor Konkatenation ist kritisch — ohne sie kann der CNN-Output (256 Dimensionen) die 13 Ray-Dimensionen überlagern.

**Dateien:**
- `training/fusion_policy.py` — `MultiSensorFusionPolicy`
- Importiert `LabyrinthCNN` (M9.1) und `TransformerEncoder` (M7.1)
- YAML-Konfigurationen: `config/agent5_fusion_transformer.yaml`, `config/agent6_fusion_lstm.yaml`

**Architektur-Diagramm** in Dokumentation (für Bericht verwendbar).

#### #122 — M10.2: Multi-Sensor Agenten trainieren: CNN+LSTM (A6) & CNN+Transformer (A5)

**Agent 6 — Kamera + Ray + CNN + LSTM:**
- Konfiguration: `config/agent6_fusion_lstm.yaml`

**Agent 5 — Kamera + Ray + CNN + Transformer:**
- Konfiguration: `config/agent5_fusion_transformer.yaml`

**Trainingsparameter:** 5.000.000 Steps · 5 Runs · Seeds identisch zu allen anderen Agenten

#### #123 — M10.3: Vollständige Trainingsmatrix abschließen & Daten-Konsistenz prüfen

**Qualitäts-Gate:** Dieses Issue ist die formale Bestätigung dass alle Experimente vollständig und konsistent sind, bevor M11 beginnt.

**Vollständigkeits-Checkliste:**

| Agent | Sensor | Architektur | 5 Runs ✓ | Checkpoints ✓ | Held-out Eval ✓ |
|-------|--------|-------------|-----------|----------------|-----------------|
| Baseline | Ray | MLP | M5 | — | — |
| A3 | Ray | LSTM | M7.2 | M7.2 | M7.2 |
| A4 | Ray | Transformer | M7.2 | M7.2 | M7.2 |
| A1 | Kamera | CNN+LSTM | M9.2 | M9.2 | M9.2 |
| A2 | Kamera | CNN+Transformer | M9.2 | M9.2 | M9.2 |
| A6 | Multi | CNN+LSTM | M10.2 | M10.2 | M10.2 |
| A5 | Multi | CNN+Transformer | M10.2 | M10.2 | M10.2 |

**Results-Ordnerstruktur:**
```
results/
├── baseline/
│   └── run1/ run2/ ... run5/
├── agent1_camera_lstm/
│   └── run1/ run2/ ... run5/
├── agent2_camera_transformer/
│   └── ...
├── agent3_ray_lstm/
│   └── ...
├── agent4_ray_transformer/
│   └── ...
├── agent5_fusion_transformer/
│   └── ...
└── agent6_fusion_lstm/
    └── ...
```

**Abschluss-Dokument:** `training_log.md` — Protokoll aller Runs (Datum, Seed, finale Erfolgsrate, eventuelle Anomalien).

---

## 11. Milestone 11 — Wissenschaftliche Auswertung & Dokumentation

**Ziel:** Alle Ergebnisse systematisch auswerten, die Forschungsfragen beantworten, Real-World-Transfer analysieren und einen vollständigen Abschlussbericht erstellen.

### Issues

#### #124 — M11.1: Quantitative Auswertung aller Agenten nach Evaluationsprotokoll

**Auswertungsebenen:**

*Ebene 1 — Paarweise Architektur-Vergleiche (RQ2):*
- A3 vs. A4 · A1 vs. A2 · A6 vs. A5
- Erfolgsrate, Konvergenz, Kollisionsrate
- Mann-Whitney U + Bonferroni + Cliff's Delta

*Ebene 2 — Sensor-Gruppen-Vergleiche (RQ1):*
- Beste Konfiguration je Gruppe: Ray vs. Kamera vs. Multi-Sensor
- Alternativ: Gruppenmedian mit dokumentiertem Caveat

*Ebene 3 — Generalisierung auf held-out Maps (RQ3):*
- Alle Agenten auf 3 held-out Maps (je 100 Episoden)
- Overfitting-Index pro Agent
- Multi-Sensor-Generalisierungsvorteil prüfen (H1)

*Ebene 4 — Vergleich mit MLP-Baseline:*
- Jeder Agent sollte Baseline übertreffen
- Falls nicht: Trainings-Issue oder Architektur-Problem → dokumentieren, nicht ignorieren

**Outputs:**
- Haupt-Ergebnistabelle (alle Metriken × alle Agenten) — direkt für Bericht verwendbar
- Lernkurven-Plot (alle 7 Konfigurationen in einem Bild, CI-Band)
- Boxplots Erfolgsrate (je Gruppe, + Baseline)
- Heatmap Generalisierungs-Erfolgsrate (Agent × held-out Map)

**Notebook:** `analysis/full_comparison.ipynb`

#### #125 — M11.2: Real-World-Transfer-Analyse (Labyrinth → Serviceroboter)

**Analogie-Tabelle (s. Abschnitt 1)** erweitern um Hardware- und Software-Anforderungen.

**Hardware-Anforderungen je Sensor-Konfiguration:**

| Konfiguration | Sensor-Hardware | Processing | Kosten-Index |
|---------------|-----------------|-----------|--------------|
| Ray-only (A3, A4) | Ultraschall / LiDAR | CPU-tauglich | niedrig |
| Kamera (A1, A2) | RGB-Kamera | GPU empfohlen | mittel |
| Multi-Sensor (A5, A6) | Kamera + LiDAR | GPU + hoher Datendurchsatz | hoch |

**Software-Latenz:**
- LSTM: O(n) sequentielle Berechnung, niedrige Latenz
- Transformer: O(seq²) Attention, höhere Latenz bei langen Sequenzen
- Bei Echtzeit-Anforderungen (z.B. 10Hz Navigation): Transformer-Latenz konkret messen

**Bewertungsmatrix** (empirisch ausfüllen nach M11.1):

| Kriterium | Gewicht | A3 | A4 | A1 | A2 | A6 | A5 |
|-----------|---------|----|----|----|----|----|----|
| Erfolgsrate (Training) | 30% | | | | | | |
| Generalisierung (held-out) | 25% | | | | | | |
| Hardware-Kosten | 20% | | | | | | |
| Inferenz-Latenz | 15% | | | | | | |
| Kollisionsrobustheit | 10% | | | | | | |

**Limitations:**
- Das Labyrinth-Modell abstrahiert: statische Hindernisse, keine Menschen, keine 3D-Komplexität
- Sim-to-Real Gap: Unity-Physik ≠ reale Roboter-Physik
- Transferempfehlung nur qualitativ, nicht experimentell validiert

#### #126 — M11.3: Wissenschaftlichen Abschlussbericht verfassen & Repository finalisieren

**Berichts-Struktur:**

```
1. Einleitung
   1.1 Motivation & Problemstellung
   1.2 Forschungsfragen (RQ1–RQ4)
   1.3 Aufbau der Arbeit

2. Theoretischer Hintergrund
   2.1 Reinforcement Learning & PPO
   2.2 Sensormodalitäten in RL (Ray, Kamera, Multi-Sensor)
   2.3 LSTM für sequentielle Entscheidungsfindung
   2.4 Transformer für RL (Vaswani 2017, Chen 2021, GTrXL)
   2.5 CNN für visuelle Observation-Verarbeitung
   2.6 Verwandte Arbeiten

3. Methodik
   3.1 Labyrinth-Umgebung & Unity ML-Agents
   3.2 Prozedurale Map-Generierung
   3.3 Experimentelles Design (Agenten-Matrix)
   3.4 Architektur-Details (CNN, LSTM, Transformer, Fusion)
   3.5 Evaluationsprotokoll & Statistische Methoden

4. Ergebnisse
   4.1 Paarweise Architektur-Vergleiche (RQ2)
   4.2 Sensor-Gruppen-Vergleich (RQ1)
   4.3 Generalisierung auf held-out Maps (RQ3)
   4.4 Vergleich mit MLP-Baseline

5. Diskussion
   5.1 Hypothesen-Bewertung (H1–H4)
   5.2 Real-World-Transfer-Analyse (RQ4)
   5.3 Limitationen & Bedrohungen der Validität

6. Fazit
   6.1 Beantwortung RQ1–RQ4 (je 2–3 Sätze)
   6.2 Ausblick: Curriculum Learning, dynamische Hindernisse, Multi-Agent

Literaturverzeichnis
Anhang (YAML-Konfigurationen, Trainings-Log)
```

**Repository-Finalisierung:**
- README aktualisieren: Setup-Guide, Trainings-Anleitung, Ergebnis-Übersicht
- `results/` vollständig und strukturiert (s. M10.3)
- Alle YAML-Konfigurationen kommentiert
- Video-Demos: Je 1 Replay pro Agent auf einer held-out Map (7 Videos)
- Kein uncommitted State, keine Debug-Scripts

---

## 12. GitHub Issues Übersicht

| Issue | Milestone | Titel | Typ |
|-------|-----------|-------|-----|
| [#110](https://github.com/kkaravaeva/KI_Agenten/issues/110) | M6 | Prozeduralen MapGenerator mit 3 Algorithmen implementieren | Implementierung |
| [#111](https://github.com/kkaravaeva/KI_Agenten/issues/111) | M6 | Obstacle- und Goal-Spawn-Logik überarbeiten | Bugfix/Refactor |
| [#112](https://github.com/kkaravaeva/KI_Agenten/issues/112) | M6 | Evaluationsprotokoll & Reproduzierbarkeits-Framework definieren | Dokumentation |
| [#113](https://github.com/kkaravaeva/KI_Agenten/issues/113) | M7 | Custom Transformer Policy implementieren | Implementierung |
| [#114](https://github.com/kkaravaeva/KI_Agenten/issues/114) | M7 | Ray-Agenten trainieren: LSTM (A3) & Transformer (A4) | Training |
| [#115](https://github.com/kkaravaeva/KI_Agenten/issues/115) | M7 | Zwischenauswertung Ray-Gruppe: A3 vs. A4 | Auswertung |
| [#116](https://github.com/kkaravaeva/KI_Agenten/issues/116) | M8 | CameraSensor in Unity einrichten | Implementierung |
| [#117](https://github.com/kkaravaeva/KI_Agenten/issues/117) | M8 | Kamera-Agenten initial trainieren & CNN verifizieren | Training/Verifikation |
| [#118](https://github.com/kkaravaeva/KI_Agenten/issues/118) | M9 | Custom CNN Policy implementieren | Implementierung |
| [#119](https://github.com/kkaravaeva/KI_Agenten/issues/119) | M9 | Kamera-Agenten vollständig trainieren: A1 & A2 | Training |
| [#120](https://github.com/kkaravaeva/KI_Agenten/issues/120) | M9 | Kamera-Gruppe auswerten: A1 vs. A2 | Auswertung |
| [#121](https://github.com/kkaravaeva/KI_Agenten/issues/121) | M10 | Multi-Sensor Fusion Architektur implementieren | Implementierung |
| [#122](https://github.com/kkaravaeva/KI_Agenten/issues/122) | M10 | Multi-Sensor Agenten trainieren: A5 & A6 | Training |
| [#123](https://github.com/kkaravaeva/KI_Agenten/issues/123) | M10 | Vollständige Trainingsmatrix abschließen | QA/Gate |
| [#124](https://github.com/kkaravaeva/KI_Agenten/issues/124) | M11 | Quantitative Auswertung aller Agenten | Auswertung |
| [#125](https://github.com/kkaravaeva/KI_Agenten/issues/125) | M11 | Real-World-Transfer-Analyse | Analyse |
| [#126](https://github.com/kkaravaeva/KI_Agenten/issues/126) | M11 | Abschlussbericht & Repository finalisieren | Dokumentation |

**Abhängigkeiten:**
```
M6.3 (Protokoll) muss abgeschlossen sein vor M7.2 (erstes Training)
M7.1 (Transformer) muss abgeschlossen sein vor M7.2
M8.1 (CameraSensor) muss abgeschlossen sein vor M8.2
M9.1 (Custom CNN) muss abgeschlossen sein vor M9.2
M7.1 + M9.1 müssen abgeschlossen sein vor M10.1
M10.3 (Gate) muss abgeschlossen sein vor M11.1
```

---

## 13. Risiken & Gegenmaßnahmen

| Risiko | Wahrscheinlichkeit | Auswirkung | Gegenmaßnahme |
|--------|-------------------|------------|---------------|
| CNN-Training zu langsam auf CPU | Hoch | Hoch | Auflösung auf 64×64 reduzieren (dokumentieren); GPU-Zugang klären |
| Transformer-Integration in ML-Agents schlägt fehl | Mittel | Hoch | Frühzeitiger Kurztest (100k Steps) in M7.1; Fallback: GTrXL via `use_recurrent` |
| NaN in Transformer-Gradienten (bekanntes RL-Problem) | Mittel | Mittel | Gradient Clipping aktivieren (max_grad_norm=0.5); Learning Rate reduzieren |
| Multi-Sensor-Fusion divergiert (Modalitäts-Imbalance) | Mittel | Mittel | LayerNorm vor Concat; separate Learning Rate für CNN |
| 35 Trainingsruns überschreiten verfügbare Zeit | Mittel | Hoch | Paralleltraining auf mehreren Maschinen; Runs verteilen im Team |
| Held-out Maps zu leicht/schwer → Decken-/Bodeneffekt | Niedrig | Mittel | Schwierigkeitsgrad beim Generieren prüfen; ggf. neue Maps in M6.3 |
| Prozedurale Maps nicht reproduzierbar (Seed-Problem Windows) | Niedrig | Hoch | Seed-Test frühzeitig in M6.3 verifizieren |

---

## 14. Real-World-Transfer

### Szenario: Serviceroboter in einem Restaurant

Ein Kellnerroboter navigiert durch ein Restaurant mit Tischen, Stühlen, Gästen und wechselndem Layout. Er muss:
1. Von der Küche zu einem Zieltisch navigieren
2. Hindernissen (Stühle, Menschen) ausweichen
3. Sich täglich an neue Layouts anpassen (Tische werden umgestellt)
4. Engstellen passieren ohne anzustoßen

**Labyrinth → Restaurant Mapping:**

| Labyrinth-Element | Restaurant-Entsprechung | Sensor-Anforderung |
|-------------------|------------------------|-------------------|
| Korridore | Gänge zwischen Tischreihen | Ray (Distanz) oder Kamera (visuell) |
| Wände | Fest verbaute Trennwände, Theke | Ray (zuverlässig) |
| Lava/Holes | Stufen, Kabel am Boden | Boden-Sensor (Ray) / Kamera |
| Ziel | Tisch-Nummer | Kamera (visuell erkennbar) oder GPS/QR |
| Prozedurales Layout | Täglich veränderte Bestuhlung | Generalisierung aus Training |
| Episodenende | Erfolgreiche Bestellung übergeben | Reward-Signal analog |

### Empfehlungsmatrix (nach M11.1 ausfüllen)

| Konfiguration | Stärken | Schwächen | Empfohlen für |
|---------------|---------|-----------|---------------|
| A3 (Ray+LSTM) | Schnell, günstig, robust | Kein visuelles Verständnis | Einfache Strukturen, bekannte Layouts |
| A4 (Ray+Transformer) | Besseres Langzeitgedächtnis | Höhere Latenz | Komplexe Routen, viele Abzweigungen |
| A1 (Kamera+CNN+LSTM) | Visuelles Erkennen von Zielen | Lichtabhängig, GPU nötig | Visuell markierte Ziele |
| A2 (Kamera+CNN+Transformer) | Beste visuelle Mustererkennung | Höchste Rechenanforderung | Premium-Setup mit GPU |
| A5 (Multi+CNN+Transformer) | Redundanz, beste Robustheit | Teuerste Hardware | Kritische Umgebungen, hohe Sicherheitsanforderung |
| A6 (Multi+CNN+LSTM) | Guter Kompromiss | Komplexe Integration | Produktionseinsatz mit Kostenlimit |

### Nicht übertragbare Aspekte (Limitations)

- **3D-Komplexität:** Das Labyrinth ist im Wesentlichen 2D — reale Navigation hat Höhenunterschiede, Rampen, unterschiedliche Bodenbeläge
- **Dynamische Hindernisse:** Menschen bewegen sich — im Labyrinth sind alle Hindernisse statisch (außer optionalen Erweiterungen)
- **Sim-to-Real Gap:** Unity-Physik ≠ reale Roboter-Physik (Schlupf, Trägheit, Sensorlatenz)
- **Sensorrauschen:** Reale Kameras und LiDARs haben Rauschen, Lens-Distortion, Reflexionen — die Simulation ist idealisiert
- **Energieverbrauch:** Nicht modelliert — relevant für batteriebetriebene Serviceroboter

---

*Dokument erstellt: 2026-04-16 | Basierend auf: AktuellerStand_KIArbeitshilfe.md, Dokumentation/Transformer_Integration.md, Dokumentation/ProceduralMapGeneration.md, GitHub Issues #110–#126*
