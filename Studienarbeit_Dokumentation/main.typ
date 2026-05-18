#import "dhbw.typ": *
#import "appendix.typ": appendix
#import "abstract.typ": abstract
#import "acronyms.typ": acronyms

#show: dhbw.with(
  title: "Studienarbeit",
  authors: (
    (name: "Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker", student-id: "1437019", course: "TIT23", course-of-studies: "Informationstechnik"),
  ),


  language: "de", // en, de
  at-dhbw: true, // true: kein Firmenname auf Titelseite, keine Vertraulichkeitserklärung
  show-confidentiality-statement: false,
  show-declaration-of-authorship: true,
  show-table-of-contents: true,
  show-acronyms: true,
  show-list-of-figures: true,
  show-list-of-tables: true,
  show-code-snippets: false,
  show-appendix: true,
  show-abstract: false,
  show-header: true,
  show-student-id: true,
  numbering-style: "1 von 1",
  numbering-alignment: center,
  abstract: abstract,
  appendix: appendix,
  acronyms: acronyms,
  university: "Dualen Hochschule Baden-Württemberg",
  university-location: "Ravensburg Campus Friedrichshafen",
  supervisor: "",
  date: datetime.today(),
  bibliography: bibliography("sources.bib"),
  logo-left: image("assets/logos/dhbw.svg"),  logo-size-ratio: "2:1" // ratio between the right logo and the left logo height (left-logo:right-logo) only the right logo is resized
)

test test
// ============================================================================
// HINWEIS: Dies ist ein erster Entwurf einer Inhaltsverzeichnis-Struktur,
// basierend auf dem aktuellen Projektstand (Stand: Milestone 7, ~Mai 2026).
// Quellen:
//   - AktuellerStand_KIArbeitshilfe.md (Gesamt-Entwicklungsstand)
//   - Forschungsplan_M6_M11.md (wissenschaftliche Rahmung)
//   - Strategie/Projekt_inhalt.md (Forschungsfrage, Scope)
//   - Dokumentation/Reward_Strategie.md
//   - Dokumentation/Transformer_Integration.md
//   - Dokumentation/LSTM_Integration.md
//   - Dokumentation/Prozedurale_Map_Generierung.md
//   - Dokumentation/Trainingsanalyse_Transformer_Milestone7.md
//   - Dokumentation/Architektur.md, ArtenSensoren.md, MlAgents.md, Actor_Critic_mit_PPO.md
// ============================================================================


// ============================================================================
// 1. EINLEITUNG
// ============================================================================
= Einleitung

== Motivation und Kontext

// - Einsatz von KI/RL in Navigationsaufgaben (Serviceroboter, Logistik,
//   autonome Lager- und Indoor-Navigation, Spiele-/Simulations-NPCs)
// - Warum 3D-Labyrinth als kontrollierte Abstraktion realer Navigationsprobleme
//   (Tabelle: Korridore ↔ Gänge, Lava ↔ Stufen/Kabel, prozedural ↔ veränderliches Layout)
// - Forschungslücke: Generalisierung über prozedurale Layouts; Architekturvergleich
//   Transformer vs. LSTM in RL-Navigation

== Problemstellung und Forschungsfrage

// - Hauptforschungsfrage:
//   "Kann ein Transformer-basierter RL-Agent in einer selbst gebauten 3D-Labyrinthwelt
//    generalisierbares Navigations- und Hindernisvermeidungsverhalten erlernen,
//    das sich auf unbekannte Map-Layouts übertragen lässt?"
// - Erweiterte Forschungsfragen (aus Forschungsplan_M6_M11):
//   RQ1 Sensortyp · RQ2 Temporal-Architektur · RQ3 Sensor-Fusion · RQ4 Real-World-Transfer
// - Hypothesen H1–H4

== Zielsetzung und Abgrenzung

// - Pflichtumfang (Scope): 3D-Labyrinth, 5 Maps, Ray-Sensorik, Lava/Hole/Sackgassen,
//   Transformer als Kernmodell, MLP-Baseline, mind. 1 Ablationsstudie,
//   Generalisierungstest, reproduzierbares Repo, Bericht + Video-Demos
// - Optionale Erweiterungen (umgesetzt): prozedurale Map-Generierung, Curriculum Learning,
//   LSTM-Vergleich, Multi-Area-Training
// - Was diese Arbeit NICHT leistet: Sim-to-Real Transfer, Multi-Agent-Setup, dynamische Hindernisse

== Aufbau der Arbeit

// - Kurze Übersicht der Kapitel


// ============================================================================
// 2. THEORETISCHE GRUNDLAGEN
// ============================================================================
= Theoretische Grundlagen

== Maschinelles Lernen und Reinforcement Learning

// - Einordnung: KI ⊃ ML ⊃ RL
// - Abgrenzung supervised / unsupervised / reinforcement learning
// - Markov-Entscheidungsprozesse (MDP): Zustände, Aktionen, Übergänge, Reward,
//   Discount-Faktor γ
// - Policy, Value-Function, Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)

// - Actor-Critic-Framework: Policy-Netz (Actor) + Value-Netz (Critic)
// - Schulman et al. (2017): Clipping-Mechanismus (ε = 0.2)
// - GAE (Generalized Advantage Estimation): λ = 0.95
// - Vorteil gegenüber Vanilla Policy Gradient (Stabilität)
// - Quelle: Dokumentation/Actor_Critic_mit_PPO.md

== Sequenzmodellierung für RL

=== Long Short-Term Memory (LSTM)

// - Hochreiter & Schmidhuber (1997)
// - Gates: Forget / Input / Output
// - Implizites Gedächtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmäßig verfügbar (use_recurrent: true)

=== Transformer-Architektur

// - Vaswani et al. (2017): Attention is All You Need
// - Self-Attention, Multi-Head-Attention, Positional Encoding
// - Anwendung im RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2020)
// - Vor- und Nachteile gegenüber LSTM
// - Quelle: Dokumentation/Transformer_Integration.md, Dokumentation/LSTM_Integration.md

== Wahrnehmung in RL-Agenten

// - Sensortypen: Ray-Sensoren, Kamera (CNN), Vector-Observations
// - Beobachtungsräume und Normalisierung
// - Quelle: Dokumentation/ArtenSensoren.md

== Unity ML-Agents Toolkit

// - Architektur: Unity-Environment ↔ Python-Trainer (gRPC)
// - Komponenten: Agent, Behavior Parameters, Decision Requester, Sensor Components
// - Trainings-Workflow: YAML-Config, ONNX-Export, TensorBoard-Integration
// - Version 0.30.0 (Release-Stand des Projekts)
// - Quelle: Dokumentation/MlAgents.md


// ============================================================================
// 3. STAND DER TECHNIK / VERWANDTE ARBEITEN
// ============================================================================
= Stand der Technik

// - Klassische Pathfinding-Algorithmen (A*, Dijkstra) vs. RL-Navigation
// - RL-basierte Navigation: DeepMind Atari (Mnih et al. 2015), AlphaGo,
//   Habitat / AI2-THOR (Embodied AI), CARLA (autonomes Fahren)
// - Memory-augmented RL: Differentiable Neural Computer, GTrXL
// - Curriculum Learning in RL (Bengio 2009)
// - Procedural Content Generation für RL-Training (Justesen et al. 2018)


// ============================================================================
// 4. METHODIK UND EXPERIMENTELLES DESIGN
// ============================================================================
= Methodik

== Wissenschaftliche Rahmung

// - Forschungsfragen RQ1–RQ4
// - Hypothesen H1–H4 (Multi-Sensor-Vorteil, Transformer-bei-Kamera,
//   Ray-Konvergenz, Beste-Gesamtkonfiguration)

== Agenten-Matrix und Vergleichsdesign

// - Tabellarische Übersicht der Agenten-Konfigurationen:
//     Baseline (Ray + MLP)
//     A3 Ray + LSTM        A4 Ray + Transformer
//     A1 Kamera+CNN+LSTM   A2 Kamera+CNN+Transformer
//     A6 Multi+CNN+LSTM    A5 Multi+CNN+Transformer
// - Paarweise Vergleiche: Architektur innerhalb je Sensorgruppe,
//   Sensortyp-übergreifend, gegen MLP-Baseline

== Kontrollierte Variablen

// - Identische Hyperparameter über alle Agenten:
//   Trainingsschritte, Reward-Struktur, Map-Algorithmus, PPO-Parameter,
//   5 unabhängige Seeds (42, 123, 456, 789, 1337)

== Evaluationsprotokoll

=== Primärmetriken
// - Erfolgsrate (Success Rate über letzte 100 Episoden)
// - Konvergenzgeschwindigkeit (Steps bis 80 % Erfolgsrate)
// - Kollisionsrate (Anteil Episoden mit Lava-/Hole-Tod)
// - Mean Episodenlänge
// - Cumulative Reward (TensorBoard)

=== Generalisierungsmetriken
// - Held-out Maps (3 fixe Eval-Maps, nie im Training gesehen)
// - Overfitting-Index = Trainings-Erfolgsrate − Generalisierungs-Erfolgsrate

=== Statistische Auswertung
// - Mann-Whitney U Test (nicht-parametrisch)
// - Bonferroni-Korrektur (α' = 0.005 bei 10 paarweisen Vergleichen)
// - Cliff's Delta als Effektgröße
// - 95 % Bootstrap-Konfidenzintervalle


// ============================================================================
// 5. SYSTEMARCHITEKTUR UND UMGEBUNG
// ============================================================================
= Systemarchitektur

== Gesamtüberblick

// - Komponentendiagramm: Unity-Editor / Build ↔ Python-Trainer ↔ TensorBoard
// - Code-Layout: Assets/Scripts/{Map, Agent, Camera}, training/, config/, results/
// - Quelle: Dokumentation/Architektur.md

== Map-System

=== Datenmodell
// - CellType-Enum (Empty, Floor, Wall, Obstacle, Goal, SpawnPoint)
// - MapData (ScriptableObject, flaches Array, GetCell/SetCell)

=== MapGenerator (Runtime)
// - Layout-basierte Generierung mit Prefab-Mapping
// - Spawn-/Goal-/Obstacle-Platzierung dynamisch zur Laufzeit
// - BFS-Pfadvalidierung (Lösbarkeit garantiert)
// - Konfigurierbare Modi: SpawnPlacementMode, GoalPlacementMode,
//   ObstaclePlacementMode (Random vs. Predefined)
// - MapSelectionMode: Fixed / Random / Sequential / Curriculum
// - Multi-Area-Setup (4–10 parallele TrainingAreas)
// - Tile-Pool (Performance-Optimierung)

=== Prozedurale Map-Generierung
// - RoomCorridorGraph: 2-Tile-Korridore, Wand-Saum, BORDER-Pufferzone
// - ObstacleClusterPlacer: Cluster aus Lava/Hole/Platform
// - SemanticPathfinder: Lösbarkeitscheck mit Sprung-/Plattform-Semantik
// - Schwierigkeitsgrade (Trivial → TrivialCorr → TrivialBranch → TrivialHole
//   → TrivialHazard → Easy → Medium → Hard)
// - Quelle: Dokumentation/Prozedurale_Map_Generierung.md

== Agent-System

=== Aktionsraum
// - 3 Branches: Bewegung (idle/vor/zurück), Rotation (idle/links/rechts), Sprung
// - Agent-relative Bewegung (V11-Refactoring): konsistentes Bezugssystem für
//   Sensorik, Zielvektor und Aktionen

=== Observation-Space
// - VectorSensor (14 Floats):
//     · Eigengeschwindigkeit lokal (3)
//     · isGrounded (1)
//     · Zielrichtung lokal (3)
//     · Boden-Sensor (3 × 2 = 6)
//     · normalisierte Distanz zum Goal (1)  [V12: PBRS-Observation]
// - RayPerceptionSensor3D (automatisch, 11 Rays × 2 Frames × 6 Tags + 2 Werte)

=== Bewegungs- und Sprungphysik
// - Rigidbody-basiert mit MovePosition / MoveRotation / AddForce
// - Sprungkalibrierung: 1-Zellen-Lücke überspringbar, 2-Zellen nicht
// - Wall-Climb-Guard und maxUpwardVelocity-Cap (V11/V12-Fix)

=== Third-Person-Kamera
// - Smooth-Follow in LateUpdate, in lokalem Agent-Raum
// - Quelle: ThirdPersonCamera.cs

== Sensorik

// - Horizontaler RayPerceptionSensor: 11 Rays, 120°, 12 Zellen Reichweite,
//   Stacked = 2 für implizite Bewegungserkennung
// - 6 Detectable Tags: Wall, Obstacle, Lava, Hole, Goal, Bridge
// - Manueller Boden-Sensor: 3 Raycasts (unter, +1, +2 in Bewegungsrichtung)
//   mit Typ-Codes (Floor +1, Bridge +0.5, Hole −0.5, Lava −1, Abgrund −1.5)

== Reward-System

// - Formale Reward-Funktion:
//     R = goalReward · 𝟙[Ziel] + lavaPen · 𝟙[Lava] + holePen · 𝟙[Hole]
//         + timeoutPen · 𝟙[Timeout] + stepPenalty · T + R_PBRS
// - Aktuelle Werte (V13): goalReward = +30, lava/hole = −1, timeout = −5,
//   stepPenalty = −0.001 (curriculum-aware MaxStep)
// - PBRS (Potential-Based Reward Shaping): F = (prevDist − γ · currDist) · scale
// - Curiosity-Modul (V13, strength = 0.05) für Exploration in Lava-Phasen
// - Quelle: Dokumentation/Reward_Strategie.md

== Trainingsinfrastruktur

// - Python venv (mlagents 0.30.0, PyTorch 2.0.1+cu118)
// - Patch-Skript (training/patch_mlagents.py) für Custom-Policies
// - Multi-Area-Training (4–16 Areas pro Unity-Instanz)
// - Headless-Parallelisierung (6 Unity-Instanzen × 16 Areas = 96 Agents)
// - Hardware: RTX 3050 Laptop GPU, Ryzen 5 5625U


// ============================================================================
// 6. MODELLARCHITEKTUREN
// ============================================================================
= Modellarchitekturen

== MLP-Baseline

// - Standard ML-Agents Setup: 2 Hidden-Layer, 256 Units
// - Direkt auf konkatenierten Observation-Vektor
// - Trainingsergebnis Milestone 5: mlp_baseline_v2 erreicht +0.81 Reward
//   (2 Mio. Steps, 10 parallele Agents)

== LSTM-Memory (Custom Policy)

// - hidden_size = 64, num_layers = 1, batch_first = True
// - 82 432 Parameter
// - Patch-Strategie: additive elif-Blöcke in mlagents NetworkBody
// - Output-Shape [batch·seq_len, output_size] — GAE-kompatibel
// - Quelle: Dokumentation/LSTM_Integration.md

== Transformer-Memory (Custom Policy)

=== Architektur
// - d_model = 256, nhead = 4, num_layers = 2
// - Gelerntes Positional Encoding via nn.Embedding + register_buffer
// - Manuelle MultiheadAttention (Workaround: PyTorch-2.0-CUDA-Segfault)
// - batch_first = False (Workaround: ONNX-Export-Bug)
// - ~1 070 000 Parameter

=== Rolling-Memory-Buffer (Fix v2)
// - Problem: Inference (seq_len=1) ≠ Training (seq_len=8) → PPO-Ratio inkonsistent
// - Lösung: memory-Tensor speichert letzte 7 MLP-Encodings;
//   Inference rekonstruiert vollständige 8-Step-Sequenz
// - Konsequenz: konsistente Log-Probs, gültige PPO-Ratio

=== Integration in ML-Agents
// - venv-Patch statt Fork (geringerer Wartungsaufwand)
// - Patch-Skript idempotent + --undo-Option
// - Quelle: Dokumentation/Transformer_Integration.md

== Geplante Architekturen (M8–M10)

=== CNN-Encoder (Nature-CNN)
// - Mnih et al. (2015): 3 Conv-Layer + FC → [256]
// - Input: [4, 84, 84] (Stack=4, Grayscale)

=== Multi-Sensor Late Fusion
// - CNN-Output (256) + VectorSensor (14) → LayerNorm → Concat → FC → [256]
// - LayerNorm gegen Modalitäts-Imbalance


// ============================================================================
// 7. UMSETZUNG NACH MEILENSTEINEN
// ============================================================================
= Umsetzung

== Milestones 1–2: Map-System und Mehrere Layouts

// - Datenmodell (CellType, MapData, MapGenerator)
// - 5 manuell entworfene Layouts (25×30 und 18×30)
// - Custom Editor (MapGeneratorEditor) mit Preview-Buttons
// - Issues #2, #3, #4, #19, #20, #39–#44

== Milestone 3: Agent-Grundsystem

// - LabyrinthAgent.cs: Initialize / OnEpisodeBegin / CollectObservations /
//   OnActionReceived / Heuristic
// - RayPerceptionSensor3D-Konfiguration (11 Rays, 120°)
// - Boden-Sensor (manuelle Raycasts)
// - Sprungkalibrierung (jumpForce 3.5, moveSpeed 2)
// - Issues #21–#36

== Milestone 4: Hindernisse und Todeslogik

// - Tag-basierter Ansatz: Lava, Hole, Bridge, KillZone (keine neuen CellTypes)
// - Lava-Prefab als IsTrigger-Plate (flach, kalibrierte Trigger-Höhe)
// - Hole-Mechanik: HoleSurface-Layer, Physics-Matrix-Trick, KillZone unter der Map
// - Zentrale Reward-Vergabe in LabyrinthAgent.OnTriggerEnter
// - Konfigurierbare Penalties: lavaDeathPenalty, holeDeathPenalty
// - Issues #82–#88

== Milestone 5: Reward-System und erstes Training

// - Reward-Strategie (Reward_Strategie.md): goalReward, deathPenalty,
//   stepPenalty, MaxStep = 2500
// - YAML-Konfiguration (config/labyrinth_training.yaml)
// - Multi-Area-Setup (4–10 parallele Areas)
// - TensorBoard-Integration verifiziert
// - mlp_baseline_v1 (CPU) und mlp_baseline_v2 (GPU, 2 Mio. Steps, +0.81 Reward)
// - Bekannte Limitierung v2: Obstacles waren auf 0 gesetzt → Modell trainierte
//   ohne Hindernisse
// - Issues #93–#99

== Milestone 6: Prozedurale Generierung und Curriculum

// - Variable Grid-Größe mit 2-Tile-Pufferzone (BORDER = 2)
// - Terminal-Korridore (echte Sackgassen mit Hole am Ende)
// - Adaptive Korridorlängen, Coverage-Check, Multi-Cluster-Bug-Fix
// - Drei Schwierigkeitsgrade (Easy/Medium/Hard) per DifficultySettings.Factory
// - Curriculum-System: CurriculumConfig (ScriptableObject) +
//   CurriculumTracker (static), synchronisierter Phasenwechsel
// - Issues #127, #133, #134

== Milestone 7: Transformer- und LSTM-Integration

// - Custom Transformer Policy via venv-Patch (Issue #113)
// - Custom LSTM Policy als direkte Baseline (Issue #131)
// - Trivial-Layouts (7×7 ohne Hindernisse) + erweiterte Trivial-Familie
//   (TrivialCorr, TrivialBranch, TrivialHole, TrivialHazard)
// - Curriculum-Erweiterung auf 8 Phasen (Trivial → ... → Hard)

=== Iterative Fehlerdiagnose und Fixes

// - Bug 1: PPO-Ratio-Inkonsistenz Transformer (Inference seq=1, Training seq=8)
//          Fix: Rolling Memory Buffer
// - Bug 2: Sparse Reward (Agent fand Goal in 1 Mio. Steps nie)
//          Fix: Trivial-Phase + PBRS-Shaping + Distanz-Observation
// - Wall-Climb (Bug 3): PhysX-Depenetration schleudert Agent nach oben
//          Fix: Wall-Climb-Guard + maxUpwardVelocity-Cap
// - Eck-Heuristik (Bug 4): nur 4 Trivial-Konfigurationen → Memorierung
//          Fix: zufällige Goal-Platzierung in Trivial-Maps
// - Goal-Collider halb im Boden (Bug 5)
//          Fix: y-Offset 0.5 in MapGenerator.CellToWorld für Goal
// - Quelle: Dokumentation/Trainingsanalyse_Transformer_Milestone7.md

=== Trainings-Iterationen V5–V13

// - V5: kein Causal Mask → kein Lernen
// - V6: Beta zu hoch, Entropy fällt nicht
// - V7: Value Loss kollabiert (Buffer zu klein)
// - V8: größerer Buffer (40960), Time Horizon 256
// - V9: 8.7 Mio. Steps, Plateau bei Reward 8.9, Episode Length 1199 (Timeout-Stagnation)
// - V10: goalReward 10, stepPenalty −0.005, Success-Rate-Logging
// - V11: Agent-relative Bewegung + Dreh-Action, sequence_length 8 → 16
// - V12: timeoutPenalty −2, Lava-Adrenalin-Reward (Diminishing Returns)
// - V13: γ = 0.997, goalReward 30, Curiosity-Modul, curriculum-aware MaxStep


// ============================================================================
// 8. EVALUATION UND ERGEBNISSE
// ============================================================================
= Evaluation

// HINWEIS: Stand Mai 2026 sind die finalen vollständigen Trainingsläufe
// für die Vergleichsmatrix (5 Mio. Steps × 5 Seeds × 7 Agenten) noch
// nicht abgeschlossen. Dieses Kapitel enthält die bisherigen Zwischenergebnisse
// und wird im weiteren Projektverlauf ergänzt.

== MLP-Baseline (Milestone 5)

// - 2 Mio. Steps, 10 Agents, RTX 3050
// - Reward-Konvergenz von −2.4 → +0.81 nach ~1.4 Mio. Steps
// - Vergleich v1 (CPU, 4 Agents) vs. v2 (GPU, 10 Agents)
// - Trainingsdauer ~1h 44min

== Transformer- und LSTM-Iterationen (Milestone 7)

// - Reward-Verläufe V5–V13 mit Diagnose
// - Quantitative Diagnose: Entropy, Policy Loss, Value Loss, Reward, Episode Length
// - Beobachtung: Erfolgreiches Lernen auf Trivial → TrivialHole
//   Stagnation bei TrivialHazard und Easy-Maps (Diagnose: Discount-Faktor +
//   PBRS-Pathologie + Avoidance-Transfer)

== Paarweise Architektur-Vergleiche

=== Ray-Gruppe: LSTM (A3) vs. Transformer (A4)
// - geplant nach Milestone 7

=== Kamera-Gruppe: LSTM (A1) vs. Transformer (A2)
// - geplant Milestone 9

=== Multi-Sensor-Gruppe: LSTM (A6) vs. Transformer (A5)
// - geplant Milestone 10

== Generalisierung auf held-out Maps

// - 3 unabhängige Evaluations-Maps (Recursive Backtracking, Cellular Automata,
//   Room-Placement)
// - Erfolgsrate, Kollisionsrate, Overfitting-Index pro Agent

== Statistische Auswertung

// - Mann-Whitney U + Bonferroni
// - Cliff's Delta
// - Bootstrap-Konfidenzintervalle
// - Lernkurven-Plots mit CI-Band

== Diskussion

// - Bewertung der Hypothesen H1–H4
// - Welche Architektur lernt schneller, welche generalisiert besser?
// - Beobachtetes Verhalten (Wall-Hugging, Lava-Avoidance, PBRS-Artefakte)


// ============================================================================
// 9. ÜBERTRAGBARKEIT UND PRAKTISCHE ANWENDBARKEIT
// ============================================================================
= Übertragbarkeit und praktische Anwendbarkeit

== Analogie Labyrinth ↔ reale Navigationsszenarien

// - Generische Szenarien (Serviceroboter, Lager-/Indoor-Logistik, Spiele-NPCs)
// - Mapping-Tabelle: Korridor → Gang, Lava → Stufe/Kabel, prozedurales Layout
//   → veränderliches Umgebungs-Layout

== Hardware- und Software-Anforderungen

// - Ray-only: Ultraschall/LiDAR, CPU-tauglich, niedrige Kosten
// - Kamera: RGB-Kamera, GPU empfohlen, mittlere Kosten
// - Multi-Sensor: höchste Robustheit, höchste Kosten

== Bewertungsmatrix

// - Kriterien × Gewichte × Agenten
// - Empfehlung je Einsatzszenario

== Limitationen der Übertragbarkeit

// - 2D-Abstraktion, statische Hindernisse, Sim-to-Real-Gap, idealisierte Sensorik


// ============================================================================
// 10. FAZIT UND AUSBLICK
// ============================================================================
= Fazit und Ausblick

== Zusammenfassung

// - Was wurde gebaut: 3D-Labyrinth, prozedurale Generierung, Curriculum,
//   Custom-LSTM, Custom-Transformer, Multi-Area-Training, vollständige
//   Evaluations-Pipeline

== Beantwortung der Forschungsfragen

// - RQ1 Sensortyp
// - RQ2 Temporal-Architektur
// - RQ3 Sensor-Fusion
// - RQ4 Praktische Übertragbarkeit

== Limitationen und Lessons Learned

// - PPO + Transformer: Inference/Training-Konsistenz nicht trivial
// - PBRS: nützlich, aber farmbar; Discount-Faktor entscheidend
// - Curriculum Learning: Phasenwechsel sind Stress-Test für gelernte Policies
// - Reward Engineering: kleine Werte mit großem Einfluss

== Ausblick

// - Vollständige Trainingsmatrix (5 Mio. Steps × 5 Seeds × 7 Agenten)
// - CNN-Pfad und Multi-Sensor-Fusion (M8–M10)
// - Dynamische Hindernisse, kooperatives Multi-Agent-Setup
// - Sim-to-Real-Transfer auf physischen Roboter


// ============================================================================
// ANHANG (in appendix.typ verschoben)
// ============================================================================
// - YAML-Konfigurationen (labyrinth_training.yaml,
//   labyrinth_transformer.yaml, labyrinth_lstm.yaml)
// - Reward-Tabelle (vollständig)
// - Übersicht aller bearbeiteten Issues (#2 – #134)
// - Hardware-/Software-Stack
// - TensorBoard-Screenshots (Lernkurven)
// - Repository-Struktur
