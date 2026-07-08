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
  logo-left: image("assets/logos/dhbw.svg"),
  logo-size-ratio: "2:1" // ratio between the right logo and the left logo height (left-logo:right-logo) only the right logo is resized
)


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
// >>> AUFTEILUNG DIESES KAPITELS (ALT -> NEU):
//     "Motivation und Kontext"           -> SPLIT: 1.1 Restaurant | 1.2 Abstraktion(+Analogie) | 1.3 Generalisierung | 1.5 Forschungsluecke
//     "Problemstellung/Forschungsfrage"  -> 1.5
//     "Zielsetzung und Abgrenzung"       -> 1.6
//     "Aufbau der Arbeit"                -> 1.7
//     (NEU 1.4 Messbarkeit ist NEU zu schreiben — kein alter Text vorhanden)

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
// >>> BLEIBT KAPITEL 2 — nur Reihenfolge/Rahmung geaendert (ALT -> NEU):
//     "Maschinelles Lernen und RL"       -> 2.1
//     "Proximal Policy Optimization"     -> 2.2
//     "Wahrnehmung in RL-Agenten"        -> 2.3  (VORGEZOGEN, vor Sequenzmodellierung)
//     "Sequenzmodellierung fuer RL"      -> 2.4  (LSTM -> 2.4.2, Transformer -> 2.4.3)
//     "Unity ML-Agents Toolkit"          -> 2.5
//     (NEU 2.4.1 Gedaechtnisproblem: NEU/kurz; Motivation auch in 1.5)

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
// >>> ALT 3 -> NEU 3 (1:1, unveraendert)

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
// >>> ACHTUNG: GANZES KAPITEL WIRD ZU NEU 5 (tauscht Platz mit Systemarchitektur!)
//     "Wissenschaftliche Rahmung"        -> 5.1
//     "Agenten-Matrix/Vergleichsdesign"  -> 5.2
//     "Kontrollierte Variablen"          -> 5.3  (+ NEU 5.3.2 "YAML-Abweichungen": ZUSATZ)
//     "Evaluationsprotokoll"             -> 5.4

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
// >>> ACHTUNG: GANZES KAPITEL WIRD ZU NEU 4 (tauscht Platz mit Methodik!)
//     "Gesamtueberblick"                 -> 4.1
//     "Map-System": Datenmodell -> 4.2.1 | MapGenerator -> 4.2.2 |
//                   Prozedurale Generierung -> 4.2.3 (UMGERAHMT: Rueckgriff auf 1.4)
//     "Agent-System" (alle Unterpunkte)  -> 4.3
//     "Sensorik"                         -> 4.4  (+ explizite Wahl "warum Ray")
//     "Reward-System"                    -> 4.5
//     "Trainingsinfrastruktur"           -> 4.6

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
// >>> ALT 6 -> NEU 6 — ABER: der Transformer-PROZESS wandert nach Kap. 7!
//     "MLP-Baseline"                     -> 6.1
//     "LSTM-Memory"                      -> 6.2
//     "Transformer-Memory / Architektur" -> 6.3 (nur statische Architektur bleibt)
//        -> Unterpunkt "Rolling-Memory-Buffer"    WANDERT nach 7.6.3 (Prozess!)
//        -> Unterpunkt "Integration in ML-Agents" WANDERT nach 7.6.1 (Prozess!)
//     "Geplante Architekturen"           -> 6.4

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
// >>> ALT 7 -> NEU 7 (mit neuem Kernabschnitt 7.6):
//     "Milestones 1-2 / 3 / 4 / 5 / 6"   -> 7.1 / 7.2 / 7.3 / 7.4 / 7.5
//     "Milestone 7: Transformer-/LSTM-Integration" -> SPLIT:
//        Transformer + "Iterative Fehlerdiagnose" (Bug 1-5)
//                                          -> 7.6 (nach Problemklassen A/B/C sortiert)
//        LSTM-Teil                         -> 7.7 (bewusst knapp)
//     "Trainings-Iterationen V5-V13"     -> 7.6.5 (verdichtete Tabelle,
//                                          erweitert bis V22; Detail -> Anhang)

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
// >>> ALT 8 -> NEU 8 (nur noch FINALE Ergebnisse, keine Iterations-Doppelung):
//     "MLP-Baseline"                     -> 8.1
//     "Transformer-/LSTM-Iterationen"    -> WICHTIG: der VERLAUF (Reward-Kurven
//                                          V5-V13, Diagnose) gehoert nach 7.6,
//                                          NICHT hierher!
//     "Paarweise Architektur-Vergleiche" -> 8.2
//     "Generalisierung held-out Maps"    -> 8.3
//     "Statistische Auswertung"          -> 8.4
//     "Diskussion"                       -> 8.5

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
// >>> ALT 9 -> NEU 9:
//     "Analogie Labyrinth <-> real"  -> SPLIT: Tabelle/Rahmung nach vorn zu 1.2 |
//                                       praktische Auswertung bleibt 9.1
//     "Hardware-/Software-Anforderungen" -> 9.2
//     "Bewertungsmatrix"                 -> 9.3
//     "Limitationen der Uebertragbarkeit"-> 9.4

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
// >>> ALT 10 -> NEU 10 (1:1):
//     "Zusammenfassung"                    -> 10.1
//     "Beantwortung der Forschungsfragen"  -> 10.2
//     "Limitationen und Lessons Learned"   -> 10.3
//     "Ausblick"                           -> 10.4

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
// >>> ALT Anhang -> NEU Anhang + ZWEI ZUSAETZE:
//     + YAML-Basis mit MARKIERTEN Abweichungen je Agent (stuetzt NEU 5.3.2)
//     + vollstaendige Iterationstabelle V1-V22 mit TensorBoard-Belegen (stuetzt 7.6.5)
// ============================================================================
// - YAML-Konfigurationen (labyrinth_training.yaml,
//   labyrinth_transformer.yaml, labyrinth_lstm.yaml)
// - Reward-Tabelle (vollständig)
// - Übersicht aller bearbeiteten Issues (#2 – #134)
// - Hardware-/Software-Stack
// - TensorBoard-Screenshots (Lernkurven)
// - Repository-Struktur


#pagebreak()

// ############################################################################
// ############################################################################
// ##                                                                        ##
// ##   NEUSTRUKTURIERUNG (Entwurf 2) — narrativ entlang der Kausalkette      ##
// ##   Restaurant -> Abstraktion -> Generalisierung -> Messbarkeit ->       ##
// ##   Engine -> Sensorik -> Verarbeitung -> Gedaechtnis -> LSTM/Transf.    ##
// ##                                                                        ##
// ##   HINWEIS: Dieser Block dupliziert die Kapitel-Ueberschriften von      ##
// ##   oben. Nach dem Review den ALTEN Block (oben) loeschen, damit das     ##
// ##   Dokument nur EINE Gliederung enthaelt.                               ##
// ##                                                                        ##
// ############################################################################
// ############################################################################


// ----------------------------------------------------------------------------
// MIGRATIONS-KARTE  —  welcher Inhalt aus der ALTEN Struktur wohin wandert
// (Quelle = altes Kapitel oben im File  ->  Ziel = neues Kapitel unten)
// ----------------------------------------------------------------------------
//
// --- EINLEITUNG ---
// ALT 1 "Motivation und Kontext"          -> SPLIT auf mehrere neue Abschnitte:
//        · Serviceroboter/Einsatzkontext   -> NEU 1.1 (Ausgangsszenario)
//        · reale Umgebung -> Abstraktion    -> NEU 1.2 (+ Analogie-Tab. aus ALT 9.1)
//        · Generalisierung als Anforderung  -> NEU 1.3
//        · Forschungsluecke/Arch.-Vergleich -> NEU 1.5
//        · (Messbarkeits-Argument NEU 1.4 ist neu, aus Generalisierungs-Inhalt)
// ALT 1 "Problemstellung/Forschungsfrage" -> NEU 1.5 (RQ1-4, H1-4)
// ALT 1 "Zielsetzung und Abgrenzung"      -> NEU 1.6 (1:1)
// ALT 1 "Aufbau der Arbeit"               -> NEU 1.7 (1:1)
//
// --- GRUNDLAGEN (bleibt Kapitel 2, nur Reihenfolge/Rahmung) ---
// ALT 2 "ML und Reinforcement Learning"   -> NEU 2.1 (1:1)
// ALT 2 "Proximal Policy Optimization"    -> NEU 2.2 (1:1)
// ALT 2 "Wahrnehmung in RL-Agenten"       -> NEU 2.3 (VORGEZOGEN vor Sequenzmodell.)
//        (die Sensor-Substanz speist zusaetzlich die Entscheidung in NEU 4.4)
// ALT 2 "Sequenzmodellierung fuer RL"     -> NEU 2.4
//        · LSTM-Unterkapitel                -> NEU 2.4.2
//        · Transformer-Unterkapitel         -> NEU 2.4.3
//        · (Gedaechtnisproblem NEU 2.4.1 ist neu/kurz; Motivation auch in 1.5)
// ALT 2 "Unity ML-Agents Toolkit"         -> NEU 2.5 (1:1)
//
// --- STAND DER TECHNIK ---
// ALT 3 "Stand der Technik"               -> NEU 3 (1:1)
//
// --- ACHTUNG: METHODIK (alt 4) und SYSTEMARCHITEKTUR (alt 5) TAUSCHEN ---
// ALT 5 "Gesamtueberblick"                -> NEU 4.1
// ALT 5 "Map-System / Datenmodell"        -> NEU 4.2.1
// ALT 5 "Map-System / MapGenerator"       -> NEU 4.2.2
// ALT 5 "Prozedurale Map-Generierung"     -> NEU 4.2.3 (UMGERAHMT: Rueckgriff 1.4,
//                                            "Umsetzung der Messbarkeitsbedingung")
// ALT 5 "Agent-System" (alle Unterpunkte) -> NEU 4.3
// ALT 5 "Sensorik"                        -> NEU 4.4 (+ explizite Wahl "warum Ray")
// ALT 5 "Reward-System"                   -> NEU 4.5 (1:1)
// ALT 5 "Trainingsinfrastruktur"          -> NEU 4.6 (1:1)
//
// ALT 4 "Wissenschaftliche Rahmung"       -> NEU 5.1
// ALT 4 "Agenten-Matrix/Vergleichsdesign" -> NEU 5.2
// ALT 4 "Kontrollierte Variablen"         -> NEU 5.3 (Vorspann + 5.3.1)
//        (NEU 5.3.2 "Notwendige YAML-Abweichungen" ist ZUSATZ; Quelle:
//         02_Anforderungen_Fairer_Vergleich.md, Abschnitt A.2)
// ALT 4 "Evaluationsprotokoll"            -> NEU 5.4 (Primaer/General./Statistik)
//
// --- MODELLARCHITEKTUREN ---
// ALT 6 "MLP / LSTM / Transformer / Geplante" -> NEU 6.1 / 6.2 / 6.3 / 6.4
//        ACHTUNG: der Bau-/Debugging-PROZESS des Transformers wandert nach
//        NEU 7.6; in 6.3 bleibt nur die statische ARCHITEKTUR-Beschreibung.
//
// --- UMSETZUNG ---
// ALT 7 "Milestones 1-2 / 3 / 4 / 5 / 6"  -> NEU 7.1 / 7.2 / 7.3 / 7.4 / 7.5 (1:1)
// ALT 7 "Milestone 7: Transformer-/LSTM-Integration" -> AUFTEILEN:
//        · Transformer-Teil + "Iterative Fehlerdiagnose" (Bug 1-5)
//                                           -> NEU 7.6, nach PROBLEMKLASSEN sortiert
//                                              (7.6.1 Patch, 7.6.2 A, 7.6.3 B, 7.6.4 C)
//        · LSTM-Teil                        -> NEU 7.7 (bewusst knapp)
// ALT 7 "Trainings-Iterationen V5-V13"    -> NEU 7.6.5 (verdichtete Tabelle,
//                                            erweitert bis V22; Detail -> Anhang)
//
// --- EVALUATION (nur FINALE Ergebnisse, keine Doppelung mit 7.6) ---
// ALT 8 "MLP-Baseline"                    -> NEU 8.1
// ALT 8 "Transformer-/LSTM-Iterationen"   -> WICHTIG: der ITERATIONS-VERLAUF
//        (Reward-Kurven V5-V13, Diagnose) gehoert nach NEU 7.6, NICHT hierher.
//        In Kap. 8 bleiben nur die abschliessenden Vergleichszahlen.
// ALT 8 "Paarweise Architektur-Vergleiche" -> NEU 8.2
// ALT 8 "Generalisierung held-out Maps"   -> NEU 8.3
// ALT 8 "Statistische Auswertung"         -> NEU 8.4
// ALT 8 "Diskussion"                      -> NEU 8.5
//
// --- UEBERTRAGBARKEIT ---
// ALT 9 "Analogie Labyrinth <-> real"     -> ZWEIGETEILT:
//        · die Analogie-Tabelle/Rahmung     -> nach vorn zu NEU 1.2
//        · die praktische Auswertung         -> bleibt NEU 9.1
// ALT 9 "Hardware-/Software-Anforderungen" -> NEU 9.2 (1:1)
// ALT 9 "Bewertungsmatrix"                -> NEU 9.3 (1:1)
// ALT 9 "Limitationen der Uebertragbarkeit"-> NEU 9.4 (1:1)
//
// --- FAZIT ---
// ALT 10 (alle Unterpunkte)               -> NEU 10.1-10.4 (1:1)
//
// --- ANHANG ---
// ALT Anhang                              -> NEU Anhang, ZUSAETZLICH:
//        · YAML-Basis + markierte Abweichungen (stuetzt NEU 5.3.2)
//        · vollstaendige Iterationstabelle V1-V22 m. TensorBoard (stuetzt 7.6.5)
// ----------------------------------------------------------------------------


// ============================================================================
// 1. EINLEITUNG  — Kausalkette als roter Faden
// ============================================================================
= Einleitung

== Ausgangsszenario: Serviceroboter im Restaurant

// - Konkreter Anker: KI-gesteuerte Serviceroboter sollen autonom navigieren
// - Warum ein reales, greifbares Szenario als Ausgangspunkt (statt abstrakt)

== Von der realen Umgebung zur testbaren Abstraktion

// - Uebersetzung realer Umgebung in eine vergleichbare, abstrahierte Welt
//   -> testbar ohne physischen Roboter
// - Analogie-Tabelle: Korridor <-> Gang, Lava <-> Stufe/Kabel,
//   prozedurales Layout <-> veraenderliche Umgebung
//   (aus altem Kap. "Uebertragbarkeit" nach vorn gezogen)

== Generalisierung als zentrale Anforderung

// - Jedes Restaurant sieht anders aus -> Agent muss generalisieren,
//   nicht einen Grundriss auswendig lernen
// - Das ist die zentrale Anforderung, nicht bloss Memorierung

== Messbarkeit von Generalisierung

// - TRAGENDES ARGUMENT 1:
//   Generalisierung ist nur nachweisbar auf Layouts, die im Training NIE
//   vorkamen -> setzt systematisch erzeugbare Layouts (prozedurale
//   Map-Generierung) UND ein zurueckgehaltenes, ungesehenes Test-Set voraus
// - Map-Generierung ist damit Bedingung der Messbarkeit, kein Feature

== Offene Fragen und Forschungsfrage

// - Abgeleitete offene Fragen (in dieser Reihenfolge):
//     (a) Wie lassen sich KI-Agenten in einer 3D-Welt implementieren,
//         welche Herausforderungen bringt die Game-Engine mit?
//     (b) Welche Sensorik bildet reale Wahrnehmung ab -> warum Ray-basiert?
//     (c) Wie verarbeitet der Agent Informationen zu Entscheidungen?
//     (d) Sackgassen: ein gedaechtnisloser Agent laeuft reaktiv gegen die
//         Wand -> Gedaechtnis noetig
// - Hauptforschungsfrage:
//   "Kann ein Transformer-basierter RL-Agent in einer selbst gebauten
//    3D-Labyrinthwelt generalisierbares Navigations- und Hindernis-
//    vermeidungsverhalten erlernen, das sich auf unbekannte Map-Layouts
//    uebertragen laesst?"
// - Erweiterte Forschungsfragen RQ1-RQ4, Hypothesen H1-H4

== Zielsetzung und Abgrenzung

// - Pflichtumfang: 3D-Labyrinth, 5 Maps, Ray-Sensorik, Lava/Hole/Sackgassen,
//   Transformer als Kernmodell, MLP-Baseline, >= 1 Ablationsstudie,
//   Generalisierungstest, reproduzierbares Repo, Bericht + Video-Demos
// - Optionale, umgesetzte Erweiterungen: prozedurale Map-Generierung,
//   Curriculum Learning, LSTM-Vergleich, Multi-Area-Training
// - NICHT geleistet: Sim-to-Real, Multi-Agent, dynamische Hindernisse

== Aufbau der Arbeit

// - Kurze Uebersicht der Kapitel


// ============================================================================
// 2. THEORETISCHE GRUNDLAGEN  — als Werkzeugkasten, geordnet nach den Fragen
// ============================================================================
= Theoretische Grundlagen

== Maschinelles Lernen und Reinforcement Learning

// - Einordnung KI ⊃ ML ⊃ RL; supervised / unsupervised / reinforcement
// - Markov-Entscheidungsprozesse (MDP), Policy, Value-/Q-Function
// - On-Policy vs. Off-Policy

== Proximal Policy Optimization (PPO)

// - Actor-Critic-Framework (Actor-Netz + Critic-Netz)
// - Schulman et al. (2017): Clipping (ε = 0.2), GAE (λ = 0.95)
// - Vorteil ggue. Vanilla Policy Gradient (Stabilitaet)

== Wahrnehmung in RL-Agenten

// - Sensortypen: Ray-Sensoren, Kamera (CNN), Vector-Observations
// - Beobachtungsraeume und Normalisierung
// - (liefert die Substanz fuer die Sensor-Entscheidung in 4.4)

== Sequenzmodellierung und Gedaechtnis in RL

=== Das Gedaechtnisproblem reaktiver Agenten

// - TRAGENDES ARGUMENT 2 (KURZ, konzeptionell, 1 Absatz):
//   Ein gedaechtnisloser Agent kann nicht wissen, aus welcher Richtung er
//   kam -> reaktives Anlaufen gegen die naechste Wand in Sackgassen
// - Motiviert, warum ueberhaupt sequenzfaehige Architekturen noetig sind
// - Querverweis auf 1.5 (Frage) und 7.6.4 (empirischer Beleg)

=== Long Short-Term Memory (LSTM)

// - Hochreiter & Schmidhuber (1997); Forget-/Input-/Output-Gates
// - Implizites Gedaechtnis ohne expliziten Sequenz-Buffer
// - In ML-Agents standardmaessig verfuegbar (use_recurrent: true)

=== Transformer-Architektur

// - Vaswani et al. (2017); Self-/Multi-Head-Attention, Positional Encoding
// - RL-Kontext: Decision Transformer (Chen 2021), GTrXL (Parisotto 2020)
// - Vor-/Nachteile ggue. LSTM NEUTRAL beschreiben (keine Wertung vorwegnehmen)

== Unity ML-Agents Toolkit

// - Architektur: Unity-Environment <-> Python-Trainer (gRPC)
// - Komponenten: Agent, Behavior Parameters, Decision Requester, Sensoren
// - Workflow: YAML-Config, ONNX-Export, TensorBoard; Version 0.30.0


// ============================================================================
// 3. STAND DER TECHNIK
// ============================================================================
= Stand der Technik

// - Klassisches Pathfinding (A*, Dijkstra) vs. RL-Navigation
// - RL-Navigation: DeepMind Atari (Mnih 2015), Habitat/AI2-THOR, CARLA
// - Memory-augmented RL: DNC, GTrXL
// - Curriculum Learning (Bengio 2009)
// - Procedural Content Generation fuer RL (Justesen et al. 2018)


// ============================================================================
// 4. SYSTEMARCHITEKTUR UND UMGEBUNG  — erst die Welt bauen (vor Methodik)
// ============================================================================
= Systemarchitektur und Umgebung

== Gesamtueberblick

// - Komponentendiagramm: Unity-Editor/Build <-> Python-Trainer <-> TensorBoard
// - Code-Layout: Assets/Scripts/{Map, Agent, Camera}, training/, config/, results/

== Map-System

=== Datenmodell

// - CellType-Enum (Empty, Floor, Wall, Obstacle, Goal, SpawnPoint)
// - MapData (ScriptableObject, flaches Array, GetCell/SetCell)

=== MapGenerator (Runtime)

// - Layout-basierte Generierung mit Prefab-Mapping
// - Spawn-/Goal-/Obstacle-Platzierung dynamisch; BFS-Pfadvalidierung
// - Modi: SpawnPlacement / GoalPlacement / ObstaclePlacement,
//   MapSelectionMode (Fixed/Random/Sequential/Curriculum)
// - Multi-Area-Setup (4-10 parallele TrainingAreas), Tile-Pool

=== Prozedurale Generierung als Umsetzung der Messbarkeitsbedingung

// - UMGERAHMT: Rueckgriff auf 1.4 — hier wird die geforderte Bedingung baulich
//   eingeloest (nicht als "Feature")
// - RoomCorridorGraph (2-Tile-Korridore, Wand-Saum, BORDER-Puffer)
// - ObstacleClusterPlacer (Cluster aus Lava/Hole/Platform)
// - SemanticPathfinder (Loesbarkeitscheck mit Sprung-/Plattform-Semantik)
// - Schwierigkeitsgrade (Trivial -> ... -> Hard)

== Agent-System

=== Aktionsraum

// - 3 Branches: Bewegung, Rotation, Sprung; agent-relative Bewegung (V11)

=== Observation-Space

// - VectorSensor (14 Floats); RayPerceptionSensor3D (11 Rays x 2 Frames x ...)

=== Bewegungs- und Sprungphysik

// - Rigidbody (MovePosition/MoveRotation/AddForce); Sprungkalibrierung
// - Wall-Climb-Guard, maxUpwardVelocity-Cap (V11/V12)

=== Third-Person-Kamera

// - Smooth-Follow in LateUpdate, lokaler Agent-Raum

== Sensorik — und die begruendete Wahl der Ray-Wahrnehmung

// - ENTSCHEIDUNG SICHTBAR MACHEN: warum Ray statt (nur) Kamera fuer die
//   Basis-Vergleichsgruppe -> CPU-tauglich, robust, direkt interpretierbar
// - Horizontaler RayPerceptionSensor: 11 Rays, 120°, 12 Zellen, Stacked = 2
// - 6 Detectable Tags: Wall, Obstacle, Lava, Hole, Goal, Bridge
// - Manueller Boden-Sensor: 3 Raycasts mit Typ-Codes

== Reward-System

// - Formale Reward-Funktion (goalReward, lava/hole/timeout, stepPenalty, PBRS)
// - Aktuelle Werte + PBRS (F = (prevDist − γ·currDist)·scale) + Curiosity
// - Quelle: Reward_Strategie.md

== Trainingsinfrastruktur

// - Python venv (mlagents 0.30.0, PyTorch 2.0.1+cu118)
// - Patch-Skript (training/patch_mlagents.py) fuer Custom-Policies
// - Multi-Area-/Headless-Parallelisierung; Hardware (RTX 3050, Ryzen 5 5625U)


// ============================================================================
// 5. METHODIK UND EXPERIMENTELLES DESIGN  — nach dem System
// ============================================================================
= Methodik und experimentelles Design

== Wissenschaftliche Rahmung

// - Forschungsfragen RQ1-RQ4, Hypothesen H1-H4

== Agenten-Matrix und Vergleichsdesign

// - Baseline (Ray + MLP)
//   A3 Ray+LSTM        A4 Ray+Transformer
//   A1 Kamera+CNN+LSTM A2 Kamera+CNN+Transformer
//   A6 Multi+CNN+LSTM  A5 Multi+CNN+Transformer
// - Paarweise Vergleiche innerhalb/ueber Sensorgruppen und gegen MLP

== Kontrollierte Variablen und begruendete Abweichungen

// - VORSPANN (Grundprinzip): pro Vergleich aendert sich nur EINE Variable,
//   alles andere ist eingefroren -> Messgrundlage fuer die Unterabschnitte.
//   (frueheres 5.3.1 hier in den Fliesstext-Vorspann verschoben)

=== Identische Parameter

// - PPO-Kern identisch fuer alle Agenten: learning_rate 3e-4, batch_size 512,
//   buffer_size, beta, epsilon 0.2, lambd 0.95, num_epoch, max_steps,
//   time_horizon, gamma, hidden_units 256, num_layers 2
// - Reward-Struktur identisch und VOR dem Training eingefroren
//   (inkl. Curiosity: fuer ALLE an oder fuer KEINEN)
// - Sensor-Basis und Seeds identisch

=== Notwendige YAML-Abweichungen und ihre Begruendung

// - DEINE FRAGE / EXPLIZIT: die YAMLs sind NICHT zu 100% identisch — und das
//   ist korrekt, nicht unfair.
// - Kontrolliert abweichende Parameter:
//     · memory_type: lstm | transformer  (je nach Agent)
//     · vis_encode_type: simple           (nur bei Kamera-Agenten)
//     · Sensor-Konfiguration              (Ray vs. Kamera vs. Kombination)
// - Begruendung: diese Parameter sind KONSTITUTIV fuer den Vergleichs-
//   gegenstand selbst — man kann Transformer vs. LSTM nicht vergleichen,
//   ohne memory_type zu aendern. Eine erzwungene 100%-Identitaet waere
//   nicht "fairer", sondern sinnlos.
// - Quelle: 02_Anforderungen_Fairer_Vergleich.md (Abschnitt A.2)

== Evaluationsprotokoll

=== Primaermetriken
// - Erfolgsrate (letzte 100 Episoden), Konvergenzgeschwindigkeit,
//   Kollisionsrate, Mean Episodenlaenge, Cumulative Reward

=== Generalisierungsmetriken
// - Held-out Maps (nie im Training gesehen); Overfitting-Index
//   = Trainings-Erfolgsrate − Generalisierungs-Erfolgsrate
// - (jetzt verstaendlich, weil Map-System in 4.2 bereits erklaert)

=== Statistische Auswertung
// - Mann-Whitney U, Bonferroni (α' = 0.005), Cliff's Delta,
//   95%-Bootstrap-Konfidenzintervalle


// ============================================================================
// 6. MODELLARCHITEKTUREN  — die konkrete Antwort auf die Frage aus 2.4
// ============================================================================
= Modellarchitekturen

== MLP-Baseline

// - Standard ML-Agents: 2 Hidden-Layer, 256 Units, direkt auf Observation
// - mlp_baseline_v2: +0.81 Reward (2 Mio. Steps, 10 Agents)

== LSTM-Memory (Custom Policy)

// - hidden_size 64, num_layers 1; ~82k Parameter
// - Patch-Strategie: additive elif-Bloecke in mlagents NetworkBody
// - Output-Shape GAE-kompatibel

== Transformer-Memory (Custom Policy)

// - d_model 256, nhead 4, num_layers 2; gelerntes Positional Encoding
// - manuelle MultiheadAttention, batch_first = False; ~1,07 Mio. Parameter
// - (Bau-/Debugging-Prozess: siehe 7.6)

== Geplante Architekturen (M8-M10)

// - CNN-Encoder (Nature-CNN, Mnih 2015): 3 Conv + FC -> [256]
// - Multi-Sensor Late Fusion: CNN(256) + Vector(14) -> LayerNorm -> Concat -> FC


// ============================================================================
// 7. UMSETZUNG NACH MEILENSTEINEN  (mit Kernabschnitt 7.6)
// ============================================================================
= Umsetzung

== Milestones 1-2: Map-System und mehrere Layouts

// - Datenmodell; 5 manuell entworfene Layouts; Custom Editor (Preview)
// - Issues #2, #3, #4, #19, #20, #39-#44

== Milestone 3: Agent-Grundsystem

// - LabyrinthAgent.cs (Initialize/OnEpisodeBegin/CollectObservations/...)
// - RayPerceptionSensor3D, Boden-Sensor, Sprungkalibrierung; Issues #21-#36

== Milestone 4: Hindernisse und Todeslogik

// - Tag-basiert: Lava, Hole, Bridge, KillZone; Lava-Trigger-Plate
// - Hole-Mechanik (HoleSurface-Layer, KillZone); zentrale Reward-Vergabe
// - Issues #82-#88

== Milestone 5: Reward-System und erstes Training

// - Reward-Strategie, YAML-Config, Multi-Area, TensorBoard verifiziert
// - mlp_baseline_v1/v2; Limitierung v2 (Obstacles = 0); Issues #93-#99

== Milestone 6: Prozedurale Generierung und Curriculum

// - Variable Grid-Groesse (BORDER = 2), Terminal-Korridore (echte Sackgassen)
// - Easy/Medium/Hard (DifficultySettings.Factory)
// - Curriculum (CurriculumConfig + CurriculumTracker); Issues #127, #133, #134

== Transformer-Integration: von V1 bis zum lauffaehigen Modell

// - KERNLEISTUNG, prominent: der 22-fach dokumentierte, messgetriebene
//   Integrationsprozess. Nach PROBLEMKLASSEN geordnet (nicht rein chronologisch),
//   die Chronologie lebt in der verdichteten Tabelle (7.6.5).

=== Warum kein Fork: der venv-Patch-Ansatz

// - additive elif-Bloecke im mlagents NetworkBody statt Fork
// - Patch-Skript idempotent + --undo; Argument: Wartbarkeit

=== Problemklasse A - Framework-/Engine-Workarounds

// - manuelle MultiheadAttention (Workaround PyTorch-2.0-CUDA-Segfault)
// - batch_first = False (Workaround ONNX-Export-Bug)

=== Problemklasse B - Inference/Training-Konsistenz

// - PPO-Ratio-Inkonsistenz: Inference (seq=1) != Training (seq=8)
// - Loesung: Rolling-Memory-Buffer (letzte 7 MLP-Encodings) -> konsistente
//   Log-Probs, gueltige PPO-Ratio

=== Problemklasse C - Reward-/Curriculum-Pathologien

// - Sparse Reward (Goal in 1 Mio. Steps nie gefunden) -> Trivial-Phase + PBRS
//   + Distanz-Observation
// - Wall-Climb (PhysX-Depenetration) -> Guard + maxUpwardVelocity-Cap
// - Eck-Heuristik/Memorierung -> zufaellige Goal-Platzierung
// - PBRS farmbar; Discount-Faktor entscheidend

=== Iterationsuebersicht V1-V22 (verdichtete Tabelle)

// - Tabelle: Version | Hypothese/Aenderung | Kennzahl-Wirkung (belegt) | Erkenntnis
// - vollstaendige Tabelle + Einzel-Kennzahlen (TensorBoard-Belege) im Anhang
// - Auszug bekannter Iterationen:
//     V5  kein Causal Mask -> kein Lernen
//     V6  Beta zu hoch, Entropy faellt nicht
//     V7  Value Loss kollabiert (Buffer zu klein)
//     V8  Buffer 40960, Time Horizon 256
//     V9  8.7 Mio. Steps, Plateau Reward 8.9 (Timeout-Stagnation)
//     V10 goalReward 10, stepPenalty −0.005, Success-Rate-Logging
//     V11 agent-relative Bewegung + Dreh-Action, seq_length 8 -> 16
//     V12 timeoutPenalty −2, Lava-Adrenalin-Reward
//     V13 γ = 0.997, goalReward 30, Curiosity-Modul, curriculum-aware MaxStep
//     ... bis V22 (spaetere Iterationen ggf. nur auf Branch milestone-7)

== LSTM-Integration (direkte Baseline)

// - BEWUSST KNAPP: LSTM weitgehend ueber use_recurrent verfuegbar
// - Die Aufwands-Asymmetrie (Transformer 22 Iterationen vs. LSTM Baseline)
//   ist selbst ein Befund und wird benannt


// ============================================================================
// 8. EVALUATION UND ERGEBNISSE  — nur FINALE Vergleiche (keine Doppelung mit 7.6)
// ============================================================================
= Evaluation

// HINWEIS: finale vollstaendige Laeufe (5 Mio. Steps x 5 Seeds x 7 Agenten)
// ggf. noch nicht abgeschlossen -> Zwischenergebnisse kennzeichnen.

== MLP-Baseline

// - 2 Mio. Steps, Reward −2.4 -> +0.81; v1 (CPU) vs. v2 (GPU); ~1h44min

== Paarweise Architektur-Vergleiche

=== Ray-Gruppe: LSTM (A3) vs. Transformer (A4)
=== Kamera-Gruppe: LSTM (A1) vs. Transformer (A2)
=== Multi-Sensor-Gruppe: LSTM (A6) vs. Transformer (A5)

== Generalisierung auf held-out Maps

// - 3 unabhaengige Eval-Maps; Erfolgs-/Kollisionsrate, Overfitting-Index

== Statistische Auswertung

// - Mann-Whitney U + Bonferroni, Cliff's Delta, Bootstrap-CI, Lernkurven mit CI-Band

== Diskussion

// - Bewertung H1-H4; welche Architektur lernt schneller / generalisiert besser
// - Beobachtetes Verhalten (Wall-Hugging, Lava-Avoidance, PBRS-Artefakte)


// ============================================================================
// 9. UEBERTRAGBARKEIT UND PRAKTISCHE ANWENDBARKEIT  (verweist zurueck auf 1.1/1.2)
// ============================================================================
= Uebertragbarkeit und praktische Anwendbarkeit

== Analogie Labyrinth <-> reale Navigationsszenarien

// - Rueckgriff auf die Rahmung aus 1.1/1.2 (nicht neu einfuehren, auswerten)
// - Serviceroboter, Lager-/Indoor-Logistik, Spiele-NPCs

== Hardware- und Software-Anforderungen

// - Ray-only (CPU, niedrige Kosten) / Kamera (GPU) / Multi-Sensor (robust, teuer)

== Bewertungsmatrix

// - Kriterien x Gewichte x Agenten; Empfehlung je Einsatzszenario

== Limitationen der Uebertragbarkeit

// - 2D-Abstraktion, statische Hindernisse, Sim-to-Real-Gap, idealisierte Sensorik


// ============================================================================
// 10. FAZIT UND AUSBLICK
// ============================================================================
= Fazit und Ausblick

== Zusammenfassung

// - Gebaut: 3D-Labyrinth, prozedurale Generierung, Curriculum, Custom-LSTM,
//   Custom-Transformer, Multi-Area, vollstaendige Evaluations-Pipeline

== Beantwortung der Forschungsfragen

// - RQ1 Sensortyp, RQ2 Temporal-Architektur, RQ3 Sensor-Fusion,
//   RQ4 praktische Uebertragbarkeit

== Limitationen und Lessons Learned

// - PPO + Transformer: Inference/Training-Konsistenz nicht trivial
// - PBRS nuetzlich aber farmbar; Discount-Faktor entscheidend
// - Curriculum: Phasenwechsel als Stress-Test; Reward Engineering sensibel

== Ausblick

// - Vollstaendige Trainingsmatrix; CNN-/Multi-Sensor-Pfad (M8-M10)
// - Dynamische Hindernisse, Multi-Agent, Sim-to-Real


// ============================================================================
// ANHANG (in appendix.typ)
// ============================================================================
// - YAML-Konfigurationen: identische Basis + je Agent MARKIERTE Abweichungen
//   (stuetzt 5.3.2 "Notwendige YAML-Abweichungen")
// - Vollstaendige Iterationstabelle V1-V22 mit TensorBoard-Belegen
//   (stuetzt 7.6.5)
// - Reward-Tabelle (vollstaendig)
// - Uebersicht aller bearbeiteten Issues (#2 - #134)
// - Hardware-/Software-Stack
// - Repository-Struktur
