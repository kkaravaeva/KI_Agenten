# SSOT — Single Source of Truth: Ist-Zustand des Systems

Extrahiert ausschließlich aus: (1) ausführbarem C#-Code, (2) serialisierten Unity-Assets (.prefab/.unity/.asset, ProjectSettings, Packages/manifest.json), (3) config/*.yaml, (4) Trainings-Tooling (training/, Root-Skripte), (5) results/ als Lauf-Inventar. Markdown-/Typst-Dokumentation und Code-Kommentare wurden **nicht** als Beleg verwendet. Inspector-Werte in Prefabs/Szenen überschreiben Script-Defaults; bei Abweichung sind beide erfasst und der effektive Wert markiert.

Statusvokabular je Eintrag: **BELEGT** (mit Fundstelle Datei:Zeile bzw. Asset+Property bzw. Datei+YAML-Key) / **NICHT VORHANDEN** / **NICHT AUFLÖSBAR**. Einträge ohne expliziten Status sind BELEGT mit der angegebenen Fundstelle.

---

## 0. Metadaten

| Größe | Wert |
|---|---|
| Extraktionsdatum | 2026-07-10 |
| Branch | `ModelTrainingComparsion` |
| Commit (HEAD) | `b30761140377bd9bd030b9c0409bcc9cad8e2078` (2026-07-09 21:20 +0200) |
| Working Tree (git status) | Modifiziert: `ProjectSettings/EditorBuildSettings.asset`, `ProjectSettings/Packages/com.unity.testtools.codecoverage/Settings.json`, `training/hourly_analysis.py`. Untracked: `Analyse/final_v3/`, `Dokumentation/Runbook_Headless_Training.md`, **`training/watchdog_final_v3.py`** (Watchdog ist nicht committet) |
| Lokale Branches | Messe2, Messestand, Milestone-3-Agent-Grundsystem, ModelTrainingComparsion*, claude/funny-feynman, documentation, main, milestone-4-hindernisse-und-interaktion, milestone-5-reward-system-training, milestone-7 |
| Remote-Branches (origin) | AlexanderBernecker, EkaterinaKaravaeva, HEAD→main, Messe2, Messestand, Milestone-1,2, Milestone-3-Agent-Grundsystem, Milestone-3-—-Agent-Grundsystem, ModelTrainingComparsion, documentation, main, milestone-4-hindernisse-und-interaktion, milestone-5-reward-system-training, milestone-7 |
| .gitignore (relevant) | `results` (Z. 109), `results/**/*.pt` (Z. 107), `venv`/`venv_mlagents/` (Z. 113–114), `Training_Archive/` (Z. 119) → **results/ ist Datenträger-Inventar, nicht Git-versioniert** |

Erhebungsmethode: 7 parallele Extraktionsdomänen (Sensorik/Aktionen, Rewards, Map/Curriculum/Editor, Szenen/Prefabs, YAML, Tooling/Policies, results), anschließend Konsolidierung mit Kreuz-Stichproben (Abschnitt „Abschluss (a)“).

---

## 1. Versions-Stack

**Unity:** 6000.2.6f1 (`ProjectSettings/ProjectVersion.txt:1`; Revision cc51a95c0300, Z. 2).

**Unity-Pakete** (`Packages/manifest.json`; Auswahl der Nicht-Modul-Pakete):

| Paket | Version | Zeile |
|---|---|---|
| com.unity.ml-agents | **2.0.2** | 9 (bestätigt in `Packages/packages-lock.json`, depth 0, source registry) |
| com.unity.ai.navigation | 2.0.9 | 3 |
| com.unity.collab-proxy | 2.9.3 | 4 |
| com.unity.feature.development | 1.0.2 | 5 |
| com.unity.ide.rider / .visualstudio / .vscode | 3.0.37 / 2.0.23 / 1.2.5 | 6–8 |
| com.unity.multiplayer.center | 1.0.0 | 10 |
| com.unity.test-framework | 1.6.0 | 11 |
| com.unity.timeline | 1.8.9 | 12 |
| com.unity.ugui | 2.0.0 | 13 |
| com.unity.visualscripting | 1.9.7 | 14 |

**Python-Abhängigkeiten:** Manifeste (requirements*.txt, pyproject.toml, environment.yml, Pipfile) im Repo: **NICHT VORHANDEN** (Glob repo-weit leer). Belegbar sind:

| Quelle | Beleg | Werte |
|---|---|---|
| Export-/Setup-venv (Soll) | `training/setup_and_export.ps1:26–28` | `torch==1.8.1+cpu`, `torchvision==0.9.1+cpu`, `mlagents==0.30.0`, `protobuf==3.20.3`, `onnx==1.13.0` |
| Tatsächliche Läufe (Ist) | `results/<run>/run_logs/training_status.json → metadata` (23 Runs) | `mlagents_version: 0.30.0` und `stats_format_version: 0.3.0` in allen 23; `torch_version: 2.0.1+cu118` (21 Runs) bzw. `2.0.1+cpu` (mlp_baseline_v1, test_run) |
| Trainings-venv | Pfad `C:\Users\Finnl\mlagents-31008` (`training/patch_mlagents.py:31`, `training/watchdog_final_v3.py:30`, `training/start_training.py:29–33`) | Paket-/Python-Stand: **NICHT AUFLÖSBAR** (liegt außerhalb des Repos; kein venv im Repo vorhanden) |

---

## 2. Beobachtungsraum

Quelle Vektor-Beobachtungen: `Assets/Scripts/Agent/LabyrinthAgent.cs`, `CollectObservations` (Z. 291–430). Es gibt genau **eine** ML-Agents-Agent-Klasse im Projekt (`LabyrinthAgent : Agent`, Z. 8; 767 Zeilen). Zwei Modi über `v24CompatMode` (Deklaration Z. 81, Script-Default `false`; **Prefab-Wert `1`**, Agent.prefab; in der Vergleichsszene per Override auf `0`, s. u.).

### 2.1 Vektor-Beobachtungen (Standardmodus, Reihenfolge im Vektor)

| # | Inhalt | Dim | Wertebereich/Normierung | Beleg |
|---|---|---|---|---|
| 1–18 | Boden-Sensor: 9 Abwärts-Rays × (Typ-Code, normierte Distanz) | 18 | Typ-Code ∈ {−1.5, −1, −0.5, 0, 0.5, 1}; Distanz = `hit.distance / groundSensorRange` ∈ [0,1]; Miss = (−1.5, 1) | Z. 314–338 |
| 19–21 | Eigengeschwindigkeit lokal: `InverseTransformDirection(rb.linearVelocity) / moveSpeed` | 3 | **ungeclampt**; y max +`maxUpwardVelocity`/`moveSpeed` (Kappung Z. 583–584), y nach unten unbegrenzt (freier Fall), x/z ohne Code-Limit | Z. 348–351 |
| — | `if (v24CompatMode) return;` → V24-Modus endet hier bei **21** | — | — | Z. 355 |
| 22 | `isGrounded` | 1 | {0, 1} | Z. 358 |
| 23 | Zieldistanz: `Vector3.Distance(Agent, Goal) / maxObservationDistance` | 1 | **ungeclampt**; > 1 sobald Ist-Distanz > 20 Einheiten (kein `Mathf.Clamp`) | Z. 361–364 |
| 24–26 | Zielrichtung lokal: `InverseTransformDirection(normalisierter Differenzvektor)`; (0,0,0) ohne Goal | 3 | Komponenten ∈ [−1,1] (Einheitsvektor) | Z. 371–381 |
| 27–30 | 4 Wand-Raycasts: `wallHit.distance / wallRaycastRange`, Miss = 1 | 4 | [0,1] | Z. 397–407 |
| 31 | Line-of-Sight zum Ziel | 1 | {0, 1} | Z. 413–429 |

**Summenrechnung Vektor:** 18 + 3 + 1 + 1 + 3 + 4 + 1 = **31** (Standardmodus). **v24CompatMode:** 18 + 3 = **21** (Abbruch Z. 355).

### 2.2 Boden-Sensor (Detail)

Exakt **9** Rays: Array `checkOffsets` mit 9 Einträgen (Z. 294–305), Schleife über `checkOffsets.Length` (Z. 314). Ursprung `transform.position + Offset + up·groundSensorHeight` (0.5, Z. 22), Richtung `down`, maxDistance `groundSensorRange` (2.0, Z. 21). Ohne LayerMask/Trigger-Parameter (Unity-Default). Offsets (lokal): zero; forward·1; forward·2; forward·0.7±right·0.7; ±right·1; forward·1.41±right·1.41.

Typ-Codes (Z. 321–325, Miss Z. 337–338): `Floor` = 1 · `Bridge` = 0.5 · Default/unbehandelter Tag (z. B. Wall, Goal, Platform-Tag) = 0 · `Hole` = −0.5 · `Lava` = −1 · kein Treffer = −1.5 (Distanz 1).

### 2.3 Wand-Raycasts und Line-of-Sight

4 horizontale Rays (vorne/hinten/links/rechts implizit über Richtungsarray), Höhe `wallRaycastHeight` (0.5, Z. 71), Länge `wallRaycastRange` (3.0, Z. 70), `Physics.DefaultRaycastLayers` + `QueryTriggerInteraction.Ignore` (Z. 397–398). LoS: Ray von `Agent + up·0.5` (hartkodiert 0.5, Z. 417) Richtung Ziel, maxDistance = Ist-Distanz, LoS = kein Treffer oder erster Treffer mit Tag `Goal` (Z. 420–424).

### 2.4 Ray-Sensor (ML-Agents-Komponente, nur im Prefab — im Code NICHT VORHANDEN)

`Assets/Prefabs/Agent/Agent.prefab`, RayPerceptionSensorComponent3D (genau 1, Z. 254–273): SensorName `RayPerceptionSensor`; **DetectableTags geordnet: [Wall, Obstacle, Lava, Hole, Goal, Bridge]**; RaysPerDirection **5** (Z. 262); MaxRayDegrees **60** (Z. 263); SphereCastRadius **0.25**; RayLength **12**; RayLayerMask Bits 4294967291 = alle Layer außer 2/Ignore Raycast; ObservationStacks **2** (Z. 269); Start-/EndVerticalOffset je **0.25**.

**Dimensionsrechnung Ray:** (Tags + 2) × (2·RaysPerDirection + 1) × Stacks = (6+2) × (2·5+1) × 2 = 8 × 11 × 2 = **176**.

### 2.5 Stacking und Gesamtgrößen

`NumStackedVectorObservations` = **1** (Agent.prefab, BehaviorParameters-Block Z. 154–183); Stacking existiert nur im Ray-Sensor (Stacks 2, in 176 enthalten). Keine Kamera-/Grid-Sensoren (Grep Assets/Scripts negativ — NICHT VORHANDEN).

| Konfiguration | Vektor | Ray | Policy-Input gesamt |
|---|---|---|---|
| Vergleichsszene `Training Area.unity` (v24CompatMode=0, VectorObservationSize-Override 31) | 31 | 176 | **207** |
| Prefab-Basis (v24CompatMode=1, VectorObservationSize 21) | 21 | 176 | **197** |
| Sensor_Test.unity (Override VectorObservationSize=13) | Code liefert 21/31 → **inkonsistent zum Override** | 176 | — (siehe Abschluss (a) Check 9) |

`maxObservationDistance`: BELEGT, Feld Z. 67 (Default 20, Prefab 20 — identisch).

---

## 3. Aktionsraum

Quelle: `LabyrinthAgent.OnActionReceived` (Z. 432–561) + `Agent.prefab` BehaviorParameters.

- **ActionSpec:** 0 Continuous; **BranchSizes [3, 3, 3]** (Agent.prefab Z. 154–183, Hex `030000000300000003000000`). Kein Szenen-Override auf BranchSizes (repo-weit geprüft).
- Gelesen werden `DiscreteActions[0..2]` (Z. 522–524).

| Branch | Größe (Prefab) | Im Code verarbeitete Werte | Wirkung | Bedingung | Beleg |
|---|---|---|---|---|---|
| 0 Bewegung | 3 | 0 = nichts; 1 = vorwärts; 2 = rückwärts (`MovePosition`, `moveSpeed·fixedDeltaTime`; Richtung aus bereits gedrehter Rotation desselben Frames) | translatorisch | `movementFrozen == false` (Z. 520) | Z. 543–553 |
| 1 Drehung | 3 | 0 = nichts; 1 = links; 2 = rechts (`MoveRotation`, ±`turnSpeed·fixedDeltaTime`, nur Y) | rotatorisch | dito | Z. 527–539 |
| 2 Sprung | 3 | **nur Wert 1** behandelt: `AddForce(up·jumpForce, Impulse)`; Werte 0 und 2 = No-Op (kein Code-Pfad) | Sprung | `isGrounded == true`; danach `isGrounded=false`, `jumpsThisEpisode++` | Z. 555–560 |

- Werte ≥ 3 (Branch 0/1) bzw. ≠ 1 (Branch 2) sind im Code unbehandelt → wirken wie „nichts“.
- Vertikalkappung: `rb.linearVelocity.y > maxUpwardVelocity` → auf `maxUpwardVelocity` gesetzt (`FixedUpdate`, Z. 583–584). Keine Kappung nach unten.
- **DecisionRequester** (nur Prefab, im Code NICHT VORHANDEN — kein `RequestDecision()`-Aufruf projektweit): DecisionPeriod **5**, TakeActionsBetweenDecisions **1** (Agent.prefab Z. 196–197). Mechanische Folge: `OnActionReceived` läuft **jeden** Academy-Step (Aktion wird zwischen Entscheidungen wiederholt); neue Entscheidungen alle 5 Steps.
- `Heuristic()` (Z. 563–577): W=[0]:1, S=[0]:2, A=[1]:1, D=[1]:2, Space=[2]:1.
- `movementFrozen`-Guard blockiert nur Bewegung; der Reward-/Trackingblock davor läuft weiter (Z. 435–520). `competitionMode` überspringt den Reward-Block (Z. 435).

---

## 4. Agent-Physik

Serialisierte Prefab-Werte überschreiben Script-Defaults; Effektivwert der Vergleichsszene = Prefab-Wert (die Szene `Training Area.unity` überschreibt keine Physik-Felder — vollständige propertyPath-Inventur, s. §8).

| Parameter | Script-Default (LabyrinthAgent.cs) | Prefab-Wert (Agent.prefab) | Effektiv (Vergleichsszene) | Szenen-Override Transformer_Test_V2/Competition (aktive Area) |
|---|---|---|---|---|
| moveSpeed | 5 (Z. 11) | 5 | **5** | — („(10)“-Area inaktiv: 3) |
| turnSpeed | 180 (Z. 12) | 180 | **180** | — |
| jumpForce | 9.0 (Z. 15) | **10.5** (Z. 216) | **10.5** | 6 |
| maxUpwardVelocity | 7.0 (Z. 52) | **8** (Z. 231) | **8** | 5 |
| groundCheckDistance | 0.15 (Z. 18) | 0.15 | 0.15 | — |
| groundSensorRange / ‑Height | 2.0 / 0.5 (Z. 21–22) | 2 / 0.5 | 2 / 0.5 | — |
| maxObservationDistance | 20 (Z. 67) | 20 | 20 | — |
| wallRaycastRange / ‑Height | 3.0 / 0.5 (Z. 70–71) | 3 / 0.5 | 3 / 0.5 | — |
| wallClimbMaxY | 5.0 (Z. 50) | 5 | 5 | 5 („(3)“-Area inaktiv: 3) |
| v24CompatMode | false (Z. 81) | **1** | **0 (Szenen-Override, alle 27 Areas)** | — (dort effektiv 1 bzw. Prefab) |
| MaxStep (serialisiert) | — | **0** (agentParameters.maxStep 0 / MaxStep 0) | 0, wird **zur Laufzeit** pro Episode aus `phaseMaxSteps` gesetzt (Z. 267–282) | dito |
| phaseMaxSteps | {600, 1200, 1200, 1200, 1200, 1500, 2000, 2500} (Z. 61) | identisch (Z. 234, LE-Hex dekodiert) | **identisch** | [0–4]=400, [5]=1200, [7]=3000 ([6]=2000) |
| testOverrideMaxSteps | 0 (Z. 64) | 0 | 0 | — (Transformer_Modell_Test: 2000) |

**Rigidbody** (Agent.prefab Z. 139–153): Mass 1, Drag 0.5, AngularDrag 0.05, UseGravity 1, Constraints 80 = FreezeRotation X+Z (Y-Rotation und Positionen frei), Interpolate None, CollisionDetection Discrete. **CapsuleCollider** (Z. 125–137): Radius 0.25, Höhe 1, Y-Achse, Center (0,0,0), kein Trigger. Agent-Root: Tag `Untagged`, Layer 0; Kind „Capsule“ nur visuell (Scale 0.5). GroundCheck-Kindobjekt: **NICHT VORHANDEN** — Bodenkontakt per Einzel-Raycast, Länge 0.5 + `groundCheckDistance` = 0.65, akzeptierte Tags Floor/Bridge/Platform/Goal, jeden FixedUpdate (LabyrinthAgent.cs:581, 588–607).

**Globale Physik/Zeit:** Fixed Timestep 0.02, Max Allowed Timestep 0.33333334, TimeScale 1 (`ProjectSettings/TimeManager.asset:6–8`); Gravitation (0, −9.81, 0), BounceThreshold 2, DefaultContactOffset 0.01, DefaultSolverIterations 6 (`ProjectSettings/DynamicsManager.asset:7–12`).

---

## 5. Reward-Funktion

Sämtliche Vergabe in `LabyrinthAgent.cs` (Grep `AddReward|SetReward` über Assets/: nur diese Datei; `SetReward`/`EpisodeInterrupted`: NICHT VORHANDEN). Alle Reward-Felder sind serialisiert → prefab-überschreibbar; **Prefab-Werte = Script-Defaults** (Agent.prefab Z. 198–241, identisch), die Vergleichsszene überschreibt keine Reward-Felder. Frequenzbezug: `OnActionReceived` läuft jeden Academy-Step (TakeActionsBetweenDecisions=1, §3).

| Term | Wert (Default = Prefab) | Deklaration | Vergabe | Auslöser | Frequenz |
|---|---|---|---|---|---|
| Ziel erreicht | +30 | Z. 28 | Z. 655 | `OnTriggerEnter` Tag `Goal` | 1×/Episode, danach `EndEpisode()` (Z. 657) |
| Lava-Tod | −3 | Z. 31 | Z. 671 | `OnTriggerEnter` Tag `Lava` | 1×/Episode + `EndEpisode()` (Z. 673) |
| Loch-/Sturz-Tod | −3 | Z. 32 | Z. 687 | `OnTriggerEnter` Tag `KillZone` | 1×/Episode + `EndEpisode()` (Z. 689) |
| Timeout | −10 | Z. 35 | Z. 443 | `StepCount ≥ MaxStep−1` ∧ nicht terminal (Z. 440) | 1×/Episode; **kein** eigener `EndEpisode()` — Ende über MaxStep-Mechanik des Frameworks |
| Step-Penalty | −0.002 | Z. 47 | Z. 438 | bedingungslos in `OnActionReceived` | pro Step |
| PBRS-Shaping | `(previousDistance − pbrsGamma·currentDistance) · distanceShapingScale`; Scale 0.01 (Z. 55), **pbrsGamma 1.0** (Z. 56) | Z. 55–56 | Z. 450–451 | Luftlinien-3D-Distanz zum Ziel (Z. 449), unnormiert; Init bei Episodenbeginn = Spawn-Goal-Distanz (Z. 285–287) | pro Step; bei γ=1 exakte Potentialdifferenz |
| Line-of-Sight | +0.005 | Z. 74 | Z. 459 | `hasLineOfSight` (Stand der letzten Observation) | **pro Step ohne Guard/Cooldown** (mechanisch beliebig oft je Episode) |
| Wall-Climb | −1 | Z. 51 | Z. 465 | `y > spawnY + wallClimbMaxY` (Z. 463) | **pro Step solange Bedingung wahr** (kein Edge-Trigger) |
| Lava-Sprungversuch | degressiv: 1.5 → 0.375 (·¼) → 0.1875 (·⅛) → 0 ab Versuch 4 | Basis Z. 38; Staffel Z. 712–718 | Z. 477 | Edge-Trigger Eintritt „über Lava“ (`!isGrounded` ∧ Down-Ray → Tag Lava ∧ Distanz > 0.3, Z. 471, 694–701) | pro Ereignis, max. 3 belohnte/Episode (Zähler-Reset Z. 237) |
| Lava-Überquerung | +8.0 | Z. 39 | Z. 485 | `wasAboveLava ∧ !currentlyAboveLava ∧ (isGrounded ∨ episodeEndedByTerminal)` (Z. 481–482) | pro Ereignis, unbegrenzt/Episode. Der Landungs-Zweig verlangt Zonen-Austritt **und** `isGrounded` im selben `OnActionReceived`-Step (Zustandsvergleich nur zwischen aufeinanderfolgenden Aufrufen, `wasAboveLava`-Fortschreibung Z. 498); verlässt der Agent die Zone airborne, wird die spätere Landung nicht mehr zugeordnet. **Pfad `episodeEndedByTerminal` ist strukturell unerreichbar**: Flag wird nur unmittelbar vor `EndEpisode()` gesetzt (Z. 653/669/685) und `OnEpisodeBegin` setzt `wasAboveLava`/Flag vor dem nächsten `OnActionReceived` zurück (Z. 238, 241) |
| Loch-Überflug | −1 | Z. 44 | Z. 509 | Edge-Trigger Eintritt „über Loch“ (analog Lava, Tag `Hole`, Z. 504, 703–710) | pro Ereignis wiederholbar; kein Überquerungs-Bonus für Löcher (NICHT VORHANDEN) |

**Terminierung:** `EndEpisode()` nur bei Goal/Lava/KillZone (Z. 657/673/689). MaxStep wird pro Episode gesetzt: `testOverrideMaxSteps` falls > 0, sonst `phaseMaxSteps[min(Phase, 7)]` (Z. 267–282). Sturz-Erkennung ausschließlich über die KillZone-Triggerbox (kein y-Schwellen-Check im Agent).

**NICHT VORHANDEN:** Wand-/Obstacle-Kollisionsstrafe (kein `OnCollisionEnter` projektweit), „Kollisionsrate“-Zähler/-Metrik, curriculum-abhängige Reward-Skalierung (phasenabhängig ist nur MaxStep), Brücken-Reward.

**Rand-Eigenschaften (Code-Struktur):** `hasLineOfSight` wird in `OnEpisodeBegin` nicht zurückgesetzt (fehlt in Reset-Liste Z. 235–246) → Wert der Vorepisode gilt bis zur nächsten Observation; im v24CompatMode wird LoS nie berechnet (Return Z. 355) → bleibt auf letztem Stand (initial false).

**TensorBoard-Seitenkanäle** (`Academy.Instance.StatsRecorder`, Prefix `{BehaviorName}/`, Z. 132, 179–229; einmalig Z. 489–494): SuccessRate, RollingSuccessRate (Fenster 50, Z. 113), EpisodeLength, StepsToGoal, DistanceAtTimeout, CurriculumPhase, DeathByLava/Hole/Timeout, LavaJumpAttempts, LavaCrossings, HoleOverflights, JumpsPerEpisode, WallClimbHits, PBRSRewardSum, LineOfSightRewardSum, EndDistanceToGoal, DistanceProgress, `Curriculum/EpisodeInPhase`, `Curriculum/GateSuccessRate`, FirstLavaCrossingAtStep (static-Guard je Behavior, Z. 126).

**Abweichender Stand (nicht Vergleichslauf):** Szenen-Overrides der aktiven Area in Transformer_Test_V2/Competition: stepPenalty −0.005, lavaDeathPenalty −2, lavaAttemptBaseReward 0.3 (+ Physik/phaseMaxSteps, §4).

---

## 6. Map-System

### 6.1 CellType-Enum (`Assets/Scripts/Map/CellType.cs:1–12`, implizite Werte 0–8)

`Empty=0, Floor=1, Wall=2, Obstacle=3, Goal=4, SpawnPoint=5, Lava=6, Hole=7, Platform=8`. **„Bridge“ als CellType: NICHT VORHANDEN.**

### 6.2 CellType ↔ Prefab ↔ Tag

Tile-Mapping `MapGenerator.BuildPrefabMap()` (MapGenerator.cs:149–162); Prefab-Referenzen aus `TrainingArea.prefab` (MapGenerator-Komponente); Tags/Collider aus den Prefab-Assets:

| CellType | Prefab-Feld → Asset | Tag des Prefabs | Layer | Collider | Bemerkung |
|---|---|---|---|---|---|
| Floor, Obstacle, Goal-Tile, SpawnPoint-Tile | `floorPrefab` → Floor.prefab (Mapping Z. 153–156) | `Floor` | 7 (Ground) | Box, kein Trigger | Obstacle/Goal/Spawn teilen das Floor-Prefab |
| Wall | `wallPrefab` → Wall.prefab (Z. 157) | `Wall` | 0 | Box | Scale (1, **7**, 1) → Wandhöhe 7 |
| Lava | `lavaPrefab` → Lava_Placeholder.prefab (Z. 158) | `Lava` | 0 | Box **isTrigger=1**, Size (1,2,1), Center (0,1.5,0); mit Prefab-Scale (1,0.1,1) effektiv (1·1, 2·0.1, 1·1) = 0.2 hoch, Zentrum +0.15 | Todes-Trigger |
| Hole | `holePrefab` → Hole_Placeholder.prefab (Z. 159) | `Hole` | 7 | Box **isTrigger=1** | Agent fällt durch (kein Reward am Hole-Trigger; Tod via KillZone) |
| Platform | `platformPrefab` → Platform.prefab (Z. 160) | **`Floor`** | 7 | Box, kein Trigger | Platform-Prefab trägt Tag Floor → Sensoren lesen „Floor“; Y-Offset 0.75 aus `cellHeightOffsets` (GenerateMap Z. 231–233; PlatformPlacer.cs:14) |
| Empty | kein Prefab | — | — | — | übersprungen (Z. 229) |
| Marker (kein Tile) | `goalPrefab` → Goal.prefab, `spawnPointPrefab` → SpawnPoint.prefab (`SpawnMarkers()` Z. 400–418) | Goal: `Goal` (Sphere-Trigger r 0.5) / SpawnPoint: Untagged, kein Collider | 0 / 7 | Goal-Marker liefert `currentGoalTransform` (Z. 416) |

Tags im Projekt (`ProjectSettings/TagManager.asset:6–15`): Wall, Obstacle, Goal, Floor, Lava, Hole, Bridge, KillZone, Platform. Layer: 6=KillZone, 7=Ground (Z. 16–24). **Zur Laufzeit ohne Träger:** `Obstacle` (kein Prefab trägt ihn; `obstaclePrefabs[]`-Feld MapGenerator.cs:50 ist deklariert, aber nirgends verwendet und im Prefab leer), `Platform` (Prefab trägt Floor), `Bridge` (nur Bridge_Placeholder.prefab, das ausschließlich in Sensor_Test.unity referenziert ist — nicht im MapGenerator). Folge: die Ray-Sensor-Kanäle Obstacle/Bridge und die Boden-Sensor-/GroundCheck-Pfade für Bridge/Platform-Tags sind im Trainingsbetrieb tote Pfade (Belege §2.2/§2.4).

### 6.3 Laufzeit-Pipeline (kein prozedurales Generieren zur Laufzeit)

`ProceduralLayoutGenerator.GenerateLayout` wird nur aus Editor-Code aufgerufen (CurriculumV2Builder.cs:44, MapGeneratorEditor.cs:183). Laufzeit = Instanziieren gebackener `MapData`-Assets: `Start()`→`GenerateRuntimeMap()` (MapGenerator.cs:114–117, 179–184) bzw. `LabyrinthAgent.OnEpisodeBegin` (LabyrinthAgent.cs:250). Ablauf `GenerateMap` (195–244): Validierung → `EnsureMapRoot/TilePool/KillZone` + `ClearMap` (Pooling statt Destroy, TilePool.cs:27–57) → Spawn-/Goal-Zellwahl → Tile-Instanziierung (`cellSize` 1, Z. 61; Platform-Y 0.75) → Marker → KillZone-Repositionierung → `OnMapGenerated`.

**Spawn/Ziel:** In den Layouts als Zellwerte **gebacken** (`CellType.SpawnPoint`/`Goal` im `cells`-Array; MapData.cs:7–9 — keine separaten Positionsfelder). Effektive Modi laut TrainingArea.prefab: `spawnPlacementMode = 1` = **PredefinedSpawnPoints**, `goalPlacementMode = 1` = **PredefinedGoalSpawnPoints** (Enum-Reihenfolge MapGenerator.cs:21–31; Script-Defaults wären je 0 = Random…, Z. 64/69 — Prefab überschreibt). Damit: Spawn = zufällige gebackene SpawnPoint-Zelle (Z. 442–451); Fallbacks: Floor ohne Lava/Hole in 8er-Nachbarschaft (456–464, `HasDangerousNeighbour` 486–498) → Floor beliebig (466–476) → (−1,−1)/`Vector3.zero` (478–482, 315–323). Goal = zufällige gebackene Goal-Zelle ≠ Spawn (508–517); keine vorhanden → dauerhafter Moduswechsel auf RandomGoalCells (519–524; dann zufällige begehbare Zelle 526–542). **Keine Distanzanforderung, keine Prozentregeln zur Laufzeit — NICHT VORHANDEN.** Zufall: `UnityEngine.Random`, kein Seed zur Laufzeit; Layout-Wahl je nach Modus (`selectionMode` Prefab = 2 = **Sequential**, Enum Z. 8–13 — greift nur im Standard-Modus; im Curriculum-Modus liefert `CurriculumTracker.GetNextLayout()` Round-Robin, s. §7). Laufzeit-Hindernisplatzierung und Laufzeit-Lösbarkeitsprüfung: **NICHT VORHANDEN**.

### 6.4 Generierungs-Pipeline (Editor-Zeit)

`ProceduralLayoutGenerator.GenerateLayout` (Z. 5–55): je Layout max. **10 Versuche** mit `seed + attempt` (Z. 20, 23): Topologie (`RoomCorridorGraph`) → Grid → Räume → Korridore (2 Tiles breit, Z. 521–538) → Wände (Empty neben Begehbarem, Z. 434–464) → Spawn+Goal (547–555) → **Coverage-Gate ≥ 15 %** begehbare Zellen innerhalb Rand 2 (482–494) → Hindernis-Cluster → Plattformen → `SemanticPathfinder.HasPath`-Gate (Z. 43); alle Versuche gescheitert → `fallbackLayouts[0]` oder null (49–54).

Topologie-Konstanten (`RoomCorridorGraph.cs`): BORDER **2** (Z. 54); MIN_CORRIDOR_LEN **4** (Z. 70); Grid = Basisgröße + 2·BORDER (81–82); StartRoom 3–5×3–5, GoalRoom 3×3, DeadEnd 1–3×1–3 (84–86); Korridor L1 max 16 (108), Ast max `max(8, 18−2·Tiefe)` (164); Äste je Tiefe 2–4/1–3/1–2 (161–163); **Goal = entferntester Raum (Manhattan), mit 25 % Wahrscheinlichkeit der zweitentfernteste** (123–128); Verwurf bei < 2 Nicht-Ziel-Ästen (139–148); Raumabstand Halbgrößen+2 (423–429); Seed: `System.Random(seed)` (75). Difficulty-Größen (`DifficultyLevel.cs:29–96`): Easy 15–20×18–25, Medium 20–28×25–35, Hard 25–37×30–45 (+ Wahrscheinlichkeitsparameter ebd.).

Hindernis-Cluster (`ObstacleClusterPlacer.cs`; **Zufall via `UnityEngine.Random`, nicht seed-deterministisch**: Z. 33, 42, 76, 116, 186): Terminal-Korridor → Hole 2×2 am Ende (18–24, 94–108, 210–230); Goal-Korridor → genau 1 Lava-Cluster, Tiefe 3 mit Wahrscheinlichkeit `GoalLavaDepth3Chance`, sonst 50/50 Tiefe 1/2, Breite 2, `hasPlatform` bei Tiefe > 1 (60–89); DeadEnd-Korridor → nichts/Hole/Lava 1–2 nach Wahrscheinlichkeiten (40–56, 114–128); Loop-Korridor → 50 % Lava Tiefe 1 (30–39, 130–143). Platform = zentrales Cluster-Tile, Höhe 0.75 (PlatformPlacer.cs:14, 30–32).

Trivial-Familie (direkte Konstruktion, Early-Return Z. 9–16): `Trivial` 7×7, Wandring, Spawn rotierend 4 Ecken (`seed % 4`), Goal-RNG `System.Random(seed ^ 0x5F3759DF)` (59–87, 468); `TrivialCorr/Branch/Hole/Hazard` über `BuildTrivialBase` (102–355): Hauptsegment 4–9, Breite 1–2, Ast 3–6, border 1; Hole 2×2 am Astende (378–385); Hazard + 2 Lava-Zellen quer (402–403).

### 6.5 Pathfinder-Begehbarkeit

`SemanticPathfinder` (BFS, Queue+HashSet, 4er-Nachbarschaft; SemanticPathfinder.cs:17–33): begehbar = Floor, SpawnPoint, Goal, **Obstacle**, Platform (Z. 67–72); Hole nie (74–75); **Lava: Cluster-Tiefe 1 begehbar („überspringbar“), Tiefe > 1 nur mit `hasPlatform`, sonst nicht; Lava ohne Cluster-Zuordnung nicht + Warnung** (77–78, 85–99, Cluster-Box 103–132). Keine explizite Sprung-/Höhenmechanik im BFS. — `MapFeasibilityValidator` (Editor, MapFeasibilityValidator.cs): eigener BFS mit expliziter Sprungkante über genau 1 Lava-Zelle (160–166, 189–194), begehbar Floor/SpawnPoint/Goal/Obstacle/Platform (180–187). — `validate_maps.py` (Root, ohne Unity): parst `Assets/Layouts/**/*.asset` binär (Z. 14, 39–62), begehbar {Floor, Spawn, Goal, Obstacle, Platform} (Z. 27), BFS mit Sprung über genau eine Lava-Zelle (140–150).

### 6.6 KillZone

Vollständig Laufzeit-erzeugt: `EnsureKillZone()` (MapGenerator.cs:165–175) — GameObject „KillZone“, Tag `KillZone` (171), BoxCollider isTrigger (172–173); Layer wird nicht gesetzt (bleibt 0; Layer 6 „KillZone“ ist definiert, aber ungenutzt). `RepositionKillZone()` (420–433): localPosition **y = −20** unter Map-Zentrum (427–428), Größe (mapW, 1, mapH) (430). Als Szenen-/Prefab-Objekt: **NICHT VORHANDEN** (repo-weiter Grep: nur TagManager).

### 6.7 `noRuntimeObstacles`

BELEGT als Feld (`MapData.cs:19`, Default false, `[NonSerialized]` Z. 18), gesetzt in ProceduralLayoutGenerator.cs:65, 142, 195, 251, 311 — **von keinem Code gelesen** (repo-weit) und nicht serialisiert → im aktuellen Codefluss wirkungslos.

---

## 7. Curriculum

Laufzeitklasse: statischer `CurriculumTracker` (+ `CurriculumConfig`-Asset); aktiv nur bei `trainingMode == Curriculum` (MapGenerator.cs:110–111; TrainingArea.prefab: trainingMode 1 = Curriculum, Enum CurriculumConfig.cs:4).

### 7.1 Phasen — Ist-Stand `Assets/CurriculumConfig_Default.asset` (Z. 16–1347; deckungsgleich mit der Schreiblogik CurriculumV2Builder.cs:91–106)

| Phase | difficulty | Layouts im Asset | Pool auf Platte (gezählt, ohne .meta) | threshold (Episodes) | minSuccessRate | phaseMaxSteps (Agent) |
|---|---|---|---|---|---|---|
| 0 | 0 Trivial | 100 | `Assets/Layouts/Procedural/Layout_P_Trivial_*` = 100 | 500 | 0.40 | 600 |
| 1 | 1 TrivialCorr | 100 | `Layout_P_TrivialCorr_*` = 100 | 1800 | 0.30 | 1200 |
| 2 | 3 TrivialHole | 150 | `Layout_P_TrivialHole_*` = 150 | 1500 | 0.30 | 1200 |
| 3 | 8 TrivialLava | 200 | `Assets/Layouts/Lava/Layout_Lava_*` = 200 | 2000 | 0.30 | 1200 |
| 4 | 4 TrivialHazard | 150 | `Layout_P_TrivialHazard_*` = 150 | 1500 | 0.30 | 1200 |
| 5 | 5 Easy | 196 | `Layout_P_Easy_*` = 196 | 8000 | 0.25 | 1500 |
| 6 | 6 Medium | 199 | `Layout_P_Medium_*` = 199 | 12000 | 0.20 | 2000 |
| 7 | 7 Hard | 192 | `Layout_P_Hard_*` = 192 | 20000 | 0 (kein Gate) | 2500 |

Globalwerte (Asset Z. 1343–1347): `loopPhases: 1`, `loopStartPhaseIndex: 5`, `initialPhaseIndex: 0`, `successWindow: 200`, `hardCapFactor: 3`. ThresholdType überall Episodes (0). phaseMaxSteps aus LabyrinthAgent (§4).

### 7.2 Mechanik (`CurriculumTracker.cs`)

- **Layout-Vergabe:** Round-Robin `layouts[currentLayoutIndexInPhase % layouts.Length]` (Z. 166), Index +1 pro Episode (178). Alle Areas eines Prozesses teilen den statischen Zustand (eine Phase, ein Fenster für alle 27 Areas).
- **Aufstieg** (`CheckPhaseAdvance`, 193–238): threshold erreicht (Episodes/Steps, 199–201) UND — falls minSuccessRate > 0 — Rolling-Fenster über `max(10, successWindow)` Episodenergebnisse aller Agenten voll UND Rate ≥ minSuccessRate (54–64, 208–223); Notaufstieg bei `threshold × hardCapFactor` (223). Fenster wird bei Phasenwechsel geleert (233–234) und nicht persistiert (16–19).
- **Nach letzter Phase:** ohne Loop Verbleib (195–196); mit Loop Rücksprung auf `loopStartPhaseIndex` (225–226) → Ist: Hard→Easy (Index 5), endlos.
- **Persistenz:** JSON `curriculum_state_{workerTag}.json` in `Application.persistentDataPath`; workerTag = Wert hinter CLI-Arg `--mlagents-port`, sonst „shared“ (70–83) → **eine State-Datei je Env-Prozess**. Felder: phaseIndex, layoutIndexInPhase, episodeCountInPhase, stepCountInPhase (28–35). Laden in `Initialize` (96, 101–120; ungültiger Index verworfen 108), Speichern bei jedem `GetNextLayout` (180) und Phasenwechsel (235), atomar via .tmp (133–136). **Folge: Prozess-Neustart/`--resume` setzt die Phase nicht zurück, solange die State-Datei existiert**; `initialPhaseIndex` greift nur ohne geladenen State. `ResetOnDomainReload` nullt nur den statischen In-Memory-Zustand (37–49). Das Erfolgsfenster startet nach Neustart leer.
- **Erfolgs-Meldekette:** Goal-Trigger → `lastEpisodeWasSuccess` (LabyrinthAgent.cs:654) → nächstes `OnEpisodeBegin` → `NotifyEpisodeResult` ab 2. Episode (233–234); Steps via `NotifyStep()` in `OnActionReceived` (435–437).

### 7.3 Pools, Builder, Sonderbestände

- Gesamtbestand `Assets/Layouts/`: 1392 .asset rekursiv; davon `Procedural/` 1187, `Lava/` 200, Wurzel `Layout_01–05` (5).
- **Nicht im aktiven Curriculum:** `Layout_P_TrivialBranch_*` = 100 (im Repo vorhanden, vom Curriculum-Asset nicht referenziert; nur über MapGeneratorEditor-Filter ladbar); `Assets/Layouts/Layout_01–05.asset` (nur per GUID in Szenen Training_MultiArea/MapGenerator_Test/SampleScene); `Assets/MapData/MapData_Training_01–05.asset` = 5 (**vollständig unreferenziert**).
- **Eval-/Test-/Holdout-Layout-Sets: NICHT VORHANDEN** (Suche eval/test/holdout unter Assets: keine Layout-Ordner/-Assets).
- `CurriculumV2Builder` (Menü `Training/Curriculum v2 bauen (Hole+Hazard+Gates)`, Z. 20): erzeugt fehlende TrivialHole/TrivialHazard bis 150 (Z. 18, 23–38), **Seeds deterministisch** `42000 + difficulty·1000 + i·7` (40, 44); schreibt die 8-Phasen-Struktur + Globalwerte (91–106).
- `LavaMapGenerator` (Menü `Tools/Training/Lava-Maps generieren…`, Z. 20): 200 Lava-Layouts aus deterministischem Parameterraster (Größen 8–14×6–12, Lava-Positionsanteile, 5 Spawn-Höhen, Double-Lava ab w≥10; Z. 35–86, 209–231); schreibt `loopStartPhaseIndex = 6` (Z. 18) — abweichend vom V2Builder (5); **Asset-Ist = 5**.
- `CurriculumPhasePrepender` (Menü `Tools/Curriculum/Prepend Trivial Goal Phase`): fügt Phase 0 (Trivial, 500, kein Gate) vor Bestand ein, Guard gegen Doppel-Einfügen (38–66).
- `MapGeneratorEditor`: Batch-Generierung 1–1000 Layouts, **Seed zufällig** `Random.Range(0, 999999) + i·7` (172, 183–184), Namensschema `Layout_P_<Difficulty>_NNN` (151, 188).
- TrainingArea.prefab trägt zusätzlich eine statische `mapLayouts`-Liste mit **1106 Referenzen** (Standard-Modus-Pool; im Curriculum-Modus ungenutzt) sowie `curriculumConfig` → `CurriculumConfig_Default.asset` (GUID f8d978147d4e62d4e994dc574d20eff2). Zweites Asset `CurriculumConfig_Show.asset` (6 Phasen, difficulty 0,1,8,5,6,7) wird nur von Transformer_Test_V2/Competition referenziert.

---

## 8. Szenen

**EditorBuildSettings** (`ProjectSettings/EditorBuildSettings.asset:7–19`, Working-Tree-Stand — Datei lokal modifiziert): Training_MultiArea (enabled 0), Transformer_Test_V2 (0), Competition (0), **`Assets/Scenes/Training Area.unity` (enabled 1)**. In HEAD war stattdessen Transformer_Test_V2 der einzige aktive Eintrag (git-Diff).

Zählmethode: Grep auf Prefab-GUIDs (TrainingArea 3c8701e5…, Agent 89282d29…) + vollständige `m_Modifications`-Inventur. In keiner Szene existieren direkte (nicht-Prefab-)Agenten/BehaviorParameters; nirgends Overrides auf Stacks/BranchSizes/DecisionPeriod/RayPerception (Ausnahmen in Tabelle). KillZone-Objekte: in keiner Szene.

| Szene | Areas | Agenten | BehaviorNames | VectorObs eff. | Sonstige relevante Overrides / Besonderheiten |
|---|---|---|---|---|---|
| **Training Area** (Build ✓; = Modellvergleich) | **27** (3 Spalten × 9 Zeilen; x ∈ {0, 80, 160}, z 0…640, Raster 80) | 27 | **MLP_Navigator ×9, LSTM_Navigator ×9, Transformer_Navigator ×9** | **31** (Override, alle 27) | v24CompatMode → 0 (alle 27); je Area added `HumanAgentVisual`; Kamera mit `ModelComparisonCameraController`; 3 Labels. **Keine** Model-/BehaviorType-/MaxStep-/Reward-/Physik-Overrides → Prefab-Basis |
| Training_MultiArea | 10 | 10 | LabyrinthNavigator | 21 | keine Wert-Overrides (nur Name/Transform) |
| Transformer_Test_V2 (HEAD-Build-Szene) | 16 (nur 1 aktiv, 15× m_IsActive 0) | 16 | LabyrinthNavigator | 31 (Override, alle 16) | aktive Area: trainingMode 0, `CurriculumConfig_Show`, m_Model → `lstm_curiosity.onnx`, BehaviorType 2 (InferenceOnly), jumpForce 6, maxUpwardVelocity 5, stepPenalty −0.005, lavaDeathPenalty −2, lavaAttemptBaseReward 0.3, phaseMaxSteps[0–4]=400/[5]=1200/[7]=3000 |
| Competition | 1 | 1 | LabyrinthNavigator | 31 | wie ttv2-aktive Area (Szenen-Duplikat, gleiche Instanz-ID) **plus m_Enabled=0 auf BehaviorParameters und LabyrinthAgent** |
| MLP_Training | 1 | 1 | LabyrinthNavigator | 21 | m_Model None, BehaviorType 0 |
| Transformer_Test | 1 | 1 | LabyrinthNavigator | 21 | m_Model None |
| Transformer_Modell_Test | 1 | 1 | LabyrinthNavigator | 21 | trainingMode 0, selectionMode 0 (Fixed), eigener mapLayouts-Pool (203), testOverrideMaxSteps 2000, kein Model |
| MapGenerator_Test | 0 | 1 (direkte Agent-Prefab-Instanz) | LabyrinthNavigator | 21 | **MaxStep-Override 2500**, szeneneigener MapGenerator |
| Sensor_Test | 0 | 1 (direkt) | LabyrinthNavigator | **13** (Override) | Testaufbau inkl. Bridge_Placeholder; Override passt nicht zur Code-Dimension (Abschluss (a) Check 9) |
| SampleScene, LayoutGenerator_Test, KI, KI_Agenten_Unity | 0 | 0 | — | — | KI: gebackenes Labyrinth ohne Agent; KI_Agenten_Unity: MapGenerator-Altversion ohne Agent |

Effektive Werte je Vergleichs-Agent (aus Prefab + Szenen-Override): VectorObs 31, Stacks 1, Branches [3,3,3], DecisionPeriod 5, TakeActionsBetweenDecisions 1, MaxStep 0 (läuft über phaseMaxSteps), m_Model None, BehaviorType Default, Physik/Rewards = Prefab (§4/§5). Eine Szene namens „ModelComparison…“: **NICHT VORHANDEN** — die Vergleichsszene ist die vom `ModelComparisonSceneBuilder` (Menü `Tools/ModelComparison/Build Model Comparison Scene`, ModelComparisonSceneBuilder.cs:62) erzeugte `Training Area.unity` (Builder setzt: Kopie von Training_MultiArea Z. 23–24/69–87; 27 Instanzen SPACING 80 Z. 29–60; BehaviorName Z. 125; Model null Z. 126; BehaviorType Default Z. 127; **VectorObservationSize 31 Z. 134**; v24CompatMode false Z. 145; trainingMode Curriculum + CurriculumConfig_Default Z. 158–160).

**ONNX-Bestand** `Assets/ML-Agents/Models/`: LabyrinthNavigator, mlp_baseline_v2_final, lstm_curiosity (einziges in Szenen referenziertes Modell: ttv2 + Competition), lstm_curiosity_backup, Transformer_v24, Transformer_v24_opset18_backup. In Trainings-/Vergleichsszenen ist kein Modell gesetzt (m_Model None).

---

## 9. Trainer-Konfigurationsmatrix (config/*.yaml)

Alle 10 Dateien: `trainer_type: ppo` (kein anderer Wert). In **keiner** Datei vorhanden: `default_settings`, `environment_parameters` (→ Curriculum ist ausschließlich Unity-seitig, §7), `engine_settings`, `checkpoint_settings`, `torch_settings`, `init_path`, `self_play`, `vis_encode_type`, `goal_conditioning_type`, `deterministic`, `epsilon_schedule`, `shared_critic`, `gail`/`rnd`. `env_settings` nur in den 4 `model_comparison*`-Dateien (num_envs + seed, **kein base_port**). YAML-Kommentare wurden ignoriert.

### 9.1 Solo-Configs (Behavior jeweils `LabyrinthNavigator`)

| Key | labyrinth_training | labyrinth_lstm | labyrinth_lstm_curiosity | labyrinth_lstm_v7 | labyrinth_transformer | labyrinth_transformer_export |
|---|---|---|---|---|---|---|
| normalize | false | true | true | true | false | false |
| hidden_units / num_layers | 256 / 2 | 256 / 2 | 256 / 2 | 256 / 2 | 256 / 2 | 256 / 2 |
| memory (seq/size/type) | — | 8 / 128 / lstm | 16 / 256 / lstm | 16 / 256 / lstm | 16 / 128 / transformer | 16 / 128 / transformer |
| learning_rate | 3.0e-4 | 3.0e-4 | 3.0e-4 | 3.0e-4 | 1.0e-4 | 1.0e-4 |
| batch_size / buffer_size | 512 / 10240 | 512 / 10240 | 512 / 40960 | 512 / 40960 | 1024 / 81920 | 1024 / 81920 |
| beta | 5.0e-3 | 1.0e-2 | 8.0e-3 | 5.0e-3 | 1.0e-3 | 1.0e-3 |
| epsilon / lambd / num_epoch | 0.2 / 0.95 / 3 | 0.2 / 0.95 / 3 | 0.2 / 0.95 / 3 | 0.2 / 0.95 / 3 | 0.2 / 0.95 / 3 | 0.2 / 0.95 / 3 |
| lr_schedule | linear | linear | linear | linear | linear | linear |
| γ extrinsic / strength | 0.99 / 1.0 | 0.995 / 1.0 | 0.995 / 1.0 | 0.995 / 1.0 | 0.997 / 1.0 | 0.997 / 1.0 |
| curiosity | — | — | strength 0.02, γ 0.99, Netz 256/2 (ohne learning_rate-Key) | — | strength 0.05, γ 0.99, lr 3.0e-4, Netz 128/2 | wie transformer |
| max_steps | 6 400 000 | 10 000 000 | 30 000 000 | 30 000 000 | 60 000 000 | **5 000** |
| time_horizon | 64 | 512 | 512 | 512 | 256 | 256 |
| summary_freq | 10 000 | 10 000 | 10 000 | 10 000 | 20 000 | 1 000 |
| keep_checkpoints / checkpoint_interval | 5 / 200 000 | 5 / 200 000 | 5 / 200 000 | 5 / 200 000 | 5 / 500 000 | 2 / 1 000 |

Diff `labyrinth_transformer` → `labyrinth_transformer_export`: nur max_steps 60 M→5000, summary_freq 20000→1000, keep_checkpoints 5→2, checkpoint_interval 500000→1000 (sonst identisch — reine Export-Kurzsession).

### 9.2 Vergleichs-Configs (Behaviors `MLP_Navigator`, `LSTM_Navigator`, `Transformer_Navigator`)

`env_settings`: model_comparison num_envs 1 / seed 42; final_v2 3 / 42; **final_v3 3 / 42** (`model_comparison_final_v3.yaml:2–3`); standalone 2 / 42.

**model_comparison.yaml** (ältester Stand): alle drei Behaviors vollständig identisch (normalize true, hidden 256/2, lr 3.0e-4, batch 2048, buffer 409600, beta 5.0e-3, num_epoch 5, γ 0.995, curiosity 0.05/0.99/3.0e-4/128/2, max_steps 5 M, horizon 512, summary 10 000, ckpt 5/200 000) **außer** memory: LSTM 32/256/lstm, Transformer 128/256/transformer, MLP ohne.

**model_comparison_final_v3.yaml** (aktiver Vergleichsstand) — identisch über alle drei Behaviors:

| Key | Wert |
|---|---|
| trainer_type / hidden_units / num_layers | ppo / 256 / 2 |
| epsilon / lambd / num_epoch | 0.2 / 0.95 / 3 |
| extrinsic strength | 1.0 |
| curiosity γ / lr / Netz | 0.99 / 3.0e-4 / 128 u., 2 Layer |
| max_steps / summary_freq | **30 000 000** / 10 000 |
| keep_checkpoints / checkpoint_interval / threaded | 5 / 200 000 / true |

— abweichend:

| Key | MLP_Navigator | LSTM_Navigator | Transformer_Navigator |
|---|---|---|---|
| normalize | false | **true** | false |
| memory seq/size/type | — | 16 / 256 / lstm | 16 / 128 / transformer |
| learning_rate | 3.0e-4 | 3.0e-4 | **1.0e-4** |
| batch_size / buffer_size | 512 / 40960 | 512 / 40960 | **1024 / 81920** |
| beta / beta_schedule | 5.0e-3 / — | 5.0e-3 / — | **5.0e-4 / constant** (`:51–52`) |
| lr_schedule | linear | linear | **constant** (`:56`) |
| γ extrinsic | 0.995 | 0.995 | **0.997** |
| curiosity strength | 0.05 | 0.05 | **0.02** (`:63`) |
| time_horizon | 512 | 512 | **256** |

**Diff final_v2 → final_v3** (mechanisch): nur Transformer_Navigator geändert — beta 1.0e-3→5.0e-4, beta_schedule neu (constant), lr_schedule linear→constant, curiosity strength 0.05→0.02; LSTM/MLP/env_settings unverändert. **model_comparison_standalone.yaml** = final_v2-Werte je Behavior, aber num_envs 2 und ohne `threaded`-Key.

Abgeleitete Rechnung (Summary-Datenpunkte je Behavior bei vollem Budget): max_steps / summary_freq = 30 000 000 / 10 000 = **3000**.

---

## 10. Custom-Policies und Patch-Mechanismus

### 10.1 `training/patch_mlagents.py` — venv-Patch (Voraussetzung für memory_type)

Venv-Ermittlung: CLI-Arg → `pip show mlagents`/Location → Fallback `C:\Users\Finnl\mlagents-31008` (Z. 19–31). Mechanik: exakte Einmal-String-Ersetzung (`assert old in text` und `count==1`, Z. 41–44), **kein Backup** (Rückbau nur via `--undo`, Z. 435–443). Zieldateien/Wirkung:

1. `mlagents/trainers/settings.py`: fügt hinter `memory_size`-Attribut den neuen Config-Key **`network_settings.memory.memory_type`** (Default `"lstm"`) ein (Z. 49–62).
2. `mlagents/trainers/torch_entities/networks.py`: (a) Importe `TransformerMemory`/`LSTMMemory` (76–83); (b) Weiche in `NetworkBody.__init__`: memory_type `"transformer"` → `TransformerMemory(h_size, memory_size, seq_len)`, `"lstm"` → `LSTMMemory(…)`, sonst Original-mlagents-LSTM (86–120); (c) `memory_size`-Property → **`(sequence_length − 1) · h_size`** für die Custom-Module (151–166); (d) `forward`: Inference (seq_len 1) = Rolling-Buffer der letzten S−1 Encodings im mlagents-`memories`-Tensor (Anhängen, Abschneiden, letzte Position als Output, Z. 199–230); Training (seq_len > 1) = volle Sequenz durchs Modul (215–234).
3. `mlagents/trainers/policy/torch_policy.py`: ONNX-Export nutzt die echte Buffer-Größe statt YAML-memory_size (363–380).
4. Kopiert `training/transformer_policy.py` → `torch_entities/transformer_memory.py` und `training/lstm_policy.py` → `torch_entities/lstm_memory.py` (403–414).

Idempotenz über Versions-Marker (v1→v4-Erkennung/Upgrades, Z. 245–339; settings-Skip bei vorhandenem `memory_type` Z. 57). Gelesene YAML-Keys im eingefügten Code: `memory.memory_type` (96), `memory.sequence_length` (102, 110); `memory.memory_size` → Modul-Argument (101); `hidden_units` → `h_size` (100). Verhalten des Keys `memory_type` auf **ungepatchter** venv: NICHT AUFLÖSBAR aus Repo-Quellen. Integration: `training/start_training.py` ruft den Patch vor jedem Start auf (Z. 48–56, abschaltbar `--no-patch`).

### 10.2 `TransformerMemory` (`training/transformer_policy.py`)

Kein eigener Trainer — Modul ersetzt (via Patch) den LSTM-Block im mlagents-`NetworkBody`; Obs-Encoder und Policy-/Value-Köpfe bleiben mlagents-Standard (venv → deren Parameter **NICHT AUFLÖSBAR**). Architektur: Input bereits `[B, S, h_size]` (keine obs_dim-Projektion im Modul, Z. 24–31); d_model = h_size (Patch:100; Zuordnung hidden_units→h_size liegt venv-intern); **nhead 4** (Default, nicht überschrieben → effektiv hartkodiert, Z. 29); **num_layers 2** (hartkodiert, Z. 30); FFN = `h·2` hartkodiert (55–57), ReLU, Post-LayerNorm-Residuals (75–76); Dropout 0.0 (46); **gelerntes** Positional Embedding der Länge seq_len (39–41); Causal-Mask (49–51, 74); Output `Linear(h → memory_size/2)`, Training alle Positionen, Inference letzte (36, 62, 77–80; Patch:212–213). seq_len aus YAML `sequence_length` (Patch:102).

**Parameterzahl-Rechnung** (h=hidden_units, S=seq_len, m=memory_size, L=2, nhead=4):
- PosEnc: S·h; je Layer: MHA 4h²+4h, LN 2h, FFN (h→2h→h) 4h²+3h, LN 2h → **8h²+11h**; Output-Proj: (h+1)·(m/2).
- **P = S·h + 2·(8h²+11h) + (h+1)·(m/2)**.
- Eingesetzt final_v3-Transformer (h 256, m 128, S 16): 4096 + 2·527 104 + 257·64 = 4096 + 1 054 208 + 16 448 = **1 074 752 Parameter (nur Memory-Modul)**. Gesamtnetz (Encoder+Köpfe): NICHT AUFLÖSBAR (venv).
- Export-Memory-Tensor: (S−1)·h = 15·256 = **3840**.

### 10.3 `LSTMMemory` (`training/lstm_policy.py`)

Custom-Wrapper um `nn.LSTM` mit identischem I/O-Vertrag wie TransformerMemory ([B,S,h] → [B·T, m/2]); hidden = output = memory_size/2 (Z. 30, 34), **num_layers 1** (Default, hartkodiert, Z. 27), batch_first (36); kein h/c-Transport zwischen Steps — Zustand läuft über denselben Rolling-Encoding-Buffer (Patch:218–230). Damit nutzt auch das LSTM-Behavior des Vergleichs das Custom-Modul (memory_type „lstm“ → LSTMMemory, Patch:104–111), nicht das native mlagents-LSTM.

**Parameterzahl** (PyTorch, 2 Bias-Sätze; out = m/2): **P = 4·[out·(h + out) + 2·out]**.
- final_v3-LSTM (h 256, m 256 → out 128): 4·[128·384 + 256] = **197 632** (nur Memory-Modul).
- Zum Vergleich m 128 → out 64: **82 432**. Export-Memory-Tensor ebenfalls 15·256 = 3840.

### 10.4 Launcher, Watchdog, Export, Ports

- `training/start_training.py`: Args `--run-id` (Default model_comparison_v1), `--config` (Default config/model_comparison.yaml), `--resume`, `--force`, `--no-patch` (Z. 34–44); startet `python -m mlagents.trainers.learn` (61–69, 90–91); keine Port-/Env-Logik (reiner Editor-Launcher).
- `training/watchdog_final_v3.py` (untracked): venv `C:\Users\Finnl\mlagents-31008` (Z. 30); Poll-Intervall 300 s (37); Prozess-Erkennung per PowerShell-CIM (57–68); liest `Policy/Entropy` aus den TB-Events von `results/model_comparison_final_v3/Transformer_Navigator` (71–86); **Entropie-Notbremse < 0.5 nur für Transformer_Navigator** → Flag `trainer_logs/WATCHDOG_ENTROPY_STOP.flag` + Kill, danach kein Neustart (36, 89–94, 132–148); Disable-Datei `trainer_logs/WATCHDOG_DISABLE.flag` → Selbstbeendigung (128–130); Auto-Resume-Kommando (97–110): `mlagents.trainers.learn config\model_comparison_final_v3.yaml --run-id model_comparison_final_v3 --env Build\KI_Agenten.exe --num-envs 5 --no-graphics --time-scale 40 --base-port 5004 --results-dir results --resume`; hält zusätzlich `hourly_analysis.py` am Leben (113–119, 154–155).
- Launcher-.bat (Root): `start_trainer_standalone.bat` = final_v3, `--env Build\KI_Agenten.exe --base-port 5004 --num-envs 3 --no-graphics --time-scale 40`, Resume checkpoint-bedingt, Restart-Loop, venv-Autodetektion + `%~dp0`; `start_trainer_visual.bat` = dito mit num-envs 1/time-scale 10/mit Grafik; `start_trainer_editor.bat` = final_v3 im Editor-Modus (num-envs 1, kein --env/base-port); `start_trainer{,_log,_watchdog}.bat` = ältere model_comparison-v2/v3-Varianten mit hartkodierten Fremdrechner-Pfaden (`C:\Users\alxbe\…`); `build_standalone.bat` = Unity 6000.2.6f1 batchmode-Build → Auto-Start standalone.
- Export/ONNX-Tooling: `export_onnx.py` (Opset 17, Custom-Symbolic für `aten::unflatten`, Export via Trainingssession `--initialize-from=v14`, Z. 29–75); `export_onnx_standalone.py` (Opset 17, ohne Unity; **hartkodiert**: BehaviorSpec Obs-Shape **(190,)**, Name `vector_obs`, Branches **(3, 3, 2)**, NetworkSettings 256/2 + memory 16/128/transformer, lädt `results/v14/manual_save/checkpoint.pt`, Z. 47–122 — Run-spezifisch v14, deckt sich nicht mit dem aktuellen Szenen-Stand, s. Abschluss (a) Check 10); `expand_ln.py` (LayerNorm→Primitive, Opset auf 11, für Barracuda 2.0.0); `convert_onnx.py` (version_converter-Versuche 11–17); `fix_onnx_batch.py` (dynamische Reshapes → [−1, …] für Batch-Betrieb); `check_ln_axes.py`/`inspect_ln.py` (Diagnose); `training/hourly_analysis.py` (stündliche 6-Seiten-PDF nach `Analyse/final_v3/`, MAX_STEPS-Konstante 30 M, Z. 23–29, 330, 362); `generate_report.py`/`auto_report_loop.py` (ältere Report-Schleife auf model_comparison_v2).
- **Ports:** base_port **5004** einheitlich in allen Standalone-/Watchdog-Kommandos (Belege §10.4); **5005** nur als Hinweistext in setup_and_export.ps1:46 sowie als `env_settings.base_port` in den configuration.yaml der Solo-Runs (mlagents-Standardwert, §11); Port-Offset-Schema je Env: im Tooling NICHT VORHANDEN (übernimmt mlagents intern); TensorBoard-Serverstart: NICHT VORHANDEN (nur lesende EventAccumulator-Nutzung).

---

## 11. Lauf-Inventar (results/, Datenträger-Stand 2026-07-10 ≈ 19:13)

Quellen je Zeile: `results/<run>/configuration.yaml` (cfg), Checkpoint-Dateinamen `<Behavior>-<steps>.pt`, `run_logs/training_status.json`. results/ ist gitignored (§0) → reines Datenträger-Inventar. Behavior überall `LabyrinthNavigator` außer model_comparison_final_v3. „mem“ = sequence_length/memory_size/memory_type; „cur“ = curiosity vorhanden.

| Run | cfg | max_steps | mem | cur | γ | buffer | envs/seed | max. Steps (Quelle: Dateiname; ✓ = auch JSON) | .pt | .onnx | letzte Änderung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| test_run | ja | 2 M | — | n | 0.99 | 10240 | 1/−1 | — (keine Checkpoints) | 0 | — | 2026-04-17 |
| mlp_baseline_v1 | ja | 2 M | — | n | 0.99 | 10240 | 1/−1 | 599 989 (nur .onnx) | 0 | 3 (199 958–599 989) | 2026-07-09* |
| mlp_baseline_v2 | ja | 2 M | — | n | 0.99 | 10240 | 1/−1 | 2 000 029 ✓ | 0 | 6 (inkl. Root-onnx) | 2026-04-17 |
| lstm_test_v1 | ja | 2 M | 8/128/lstm | n | 0.99 | 10240 | 1/−1 | 1 095 882 ✓ | 6 | — | 2026-04-28 |
| lstm_baseline_comparison | **nein** | — | — | — | — | — | — | — (nur 1 tfevents) | 0 | — | 2026-04-30 |
| transformer_test_v1 | ja | 2 M | 8/128/tf | n | 0.99 | 10240 | 1/−1 | 50 917 | 4 | — | 2026-04-19 |
| transformer_test_v2 | ja | 6.5 M | 8/128/tf | n | 0.99 | 10240 | 1/**42**, port 5004 | 1 788 707 ✓ | 7 | — | 2026-04-27 |
| transformer_v3 / v4 | ja | 15 M | 8/128/tf | n | 0.99 | 10240 | 1/−1 | 304 486 ✓ / 378 837 ✓ | 4 / 3 | — | 2026-04-28/29 |
| transformer_v5 | ja | 30 M | 8/128/tf | n | 0.99 | 10240 | 1/−1 | 787 445 ✓ | 15 | — | 2026-04-30 |
| transformer_v6 / v7 | nein | — | — | — | — | — | — | 599 985 / 1 399 994 | 4 / 6 | — | 2026-04-30 |
| transformer_v8 | ja | 30 M | 8/128/tf | n | 0.99 | 40960 | 1/−1 | 1 954 218 ✓ | 6 | — | 2026-04-30 |
| v9 | ja | 30 M | 8/128/tf | n | 0.99 | 40960 | 1/−1 | 8 768 907 ✓ | 6 | — | 2026-05-03 |
| V10 | nein | — | — | — | — | — | — | 2 999 774 | 6 | — | 2026-05-03 |
| V11 | ja | 30 M | 16/128/tf | n | 0.99 | 40960 | 1/−1 | 2 754 800 ✓ | 11 | — | 2026-05-11 |
| v12_overnight_001 | nein | — | — | — | — | — | — | — | 0 | — | 2026-05-12 |
| v12_overnight_002 | ja | 60 M | 16/128/tf | n | 0.99 | 81920 | **6**/−1 | 29 499 906 | 6 | — | 2026-05-12 |
| v13 | ja | 60 M | 16/128/tf | **ja** | **0.997** | 81920 | 1/−1 | 18 999 858 | 6 | — | 2026-05-12 |
| v14 | ja | 60 M | 16/128/tf | ja | 0.997 | 81920 | 1/−1 | 30 999 993 ✓ | 7 (+ manual_save: 2 .pt + `v14_actor.pt`) | — | 2026-05-13 |
| v14_onnx_export | ja | **5000** | 16/128/tf | ja | 0.997 | 81920 | 1/−1 | 999 | 5 | **keine** (trotz Name) | 2026-05-13 |
| v15 / v16 | nein | — | — | — | — | — | — | 8 499 772 / 4 499 933 | 6 / 6 | — | 2026-05-17 |
| v17 | ja | 10 M | 16/128/tf | ja | 0.997 | 81920 | **6**/−1 | 10 000 033 ✓ | 6 | — | 2026-05-18 |
| v18 | ja | 20 M | 16/128/tf | ja | 0.997 | 81920 | 6/−1 | 20 000 010 ✓ | 6 | — | 2026-05-19 |
| v19 / v20 | nein | — | — | — | — | — | — | 19 499 877 / 17 499 987 | 6 / 6 | — | 2026-05-19/20 |
| v21 / v21_snapshot | nein / ja (50 M) | 50 M | 16/128/tf | ja | 0.997 | 81920 | 1/−1 | 24 999 956 (Snapshot ✓) | 6 / 6 | — | 2026-05-20 |
| v22 / v23 | nein | — | — | — | — | — | — | 23 999 878 / 20 499 967 | 6 / 11 | — | 2026-05-24/25 |
| v24 | ja | 60 M | 16/128/tf | ja (0.05) | 0.997 | 81920 | 1/−1, port 5005 | 30 999 993 ✓ | 6 | — | 2026-05-27 |
| v24_snapshot | ja | 60 M | 16/128/tf | ja | 0.997 | 81920 | 1/−1 | 30 999 993 ✓ | 6 | — | 2026-05-26 |
| v24_backup_30.5M | nein (nur 2 lose .pt) | — | — | — | — | — | — | 30 499 782 | 2 | — | 2026-05-26 |
| transformer_specialist_v1 | ja | 10 M | 16/128/tf | **nein** | 0.997 | 81920 | 1/−1, `initialize_from: v24` | 1 999 971 | 9 | — | 2026-05-26 |
| transformer_specialist_v1_snapshot | ja | 10 M | 16/128/tf | nein | 0.997 | 81920 | 1/−1 (initialize_from null) | 1 999 971 ✓ | 9 | — | 2026-05-26 |
| **model_comparison_final_v3** | **nein** | — | — | — | — | — | — | LSTM 16 999 925 / MLP 16 999 973 / Transformer 16 999 839 | 11/12/12 | — | **2026-07-10 19:03 (Lauf aktiv)** |

\* mlp_baseline_v1: configuration.yaml/run_logs tragen Zeitstempel 2026-07-09 19:24, die Modell-/tfevents-Dateien 2026-04-17 — die Config-Dateien spiegeln eine spätere (Inference-/Resume-)Session.

**Detail model_comparison_final_v3:** keine configuration.yaml, kein training_status.json, kein timers.json (einziger Detail-Run ohne); `run_logs/` enthält Player-0…4.log (**5 Env-Prozesse** — konsistent mit dem Watchdog-Kommando `--num-envs 5`, §10.4). Checkpoints: LSTM_Navigator 11 (199 776–16 999 925), MLP_Navigator 12 (199 839–16 999 973), Transformer_Navigator 12 (199 878–16 999 839); keine ONNX. Der Lauf produzierte während der Erhebung fortlaufend neue Checkpoints (letzter beobachteter Satz 19:03/19:04) → alle Steps-Angaben sind ein Zeitpunkt-Snapshot, kein Endstand.

**Weitere deskriptive Befunde:** 13 Runs ohne configuration.yaml (V10, lstm_baseline_comparison, transformer_v6/v7, v12_overnight_001, v15, v16, v19–v23, v24_backup_30.5M, final_v3). configuration.yaml spiegelt jeweils den letzten Aufruf (mehrfach `resume: true`/`inference: true`; specialist_v1 `initialize_from: v24`, dessen Snapshot null). Bei mlp_baseline_v1/v2 liegen nur .onnx (keine .pt); bei allen übrigen Checkpoint-Runs umgekehrt nur .pt, während training_status.json auf fehlende .onnx verweist. `_snapshot`-Ordner = gleiche Checkpoint-Stände ohne Player-Logs; v24_backup_30.5M = 2 lose Dateien (Stand 30 499 782). v14 enthält `manual_save/` mit `v14_actor.pt` (Quelle des Standalone-Exports, §10.4). Solo-Runs nutzen `env_settings.base_port: 5005`, transformer_test_v2 5004. `Training_Archive/` ist **leer**. Eine Curriculum-Persistenzdatei existiert weder in results/ noch im Repo-Root (Suche `*curriculum*`/`*phase*` — konsistent mit §7.2: sie liegt in `Application.persistentDataPath`, außerhalb des Repos).

---

## 12. Offene Punkte (NICHT VORHANDEN / NICHT AUFLÖSBAR / tote Pfade)

**NICHT VORHANDEN (geprüft, ohne Code-/Asset-Gegenstück):**
1. „Kollisionsrate“-Metrik oder -Zähler (kein `OnCollisionEnter`/collisionCount projektweit).
2. Eval-/Test-/Holdout-Layout-Sets; ebenso jede Checkpoint-Evaluations-Pipeline auf fixem Map-Set.
3. Overfitting-Index, Konvergenzkriterium (z. B. 80-%-Schwelle), α-Korrektur/Statistik-Festlegungen — kein Gegenstück im Code; vorhandene Bausteine sind nur die TB-Metriken (§5) und die Curriculum-Gates 0.20–0.40 (§7.1).
4. Mehrere Seeds/Läufe je Architektur als Konfiguration (alle Vergleichs-YAMLs: ein Seed 42; Solo-Runs seed −1).
5. „Bridge“ als CellType/Prefab-Feld im MapGenerator (nur Tag + Placeholder-Prefab in Sensor_Test).
6. YAML-`environment_parameters`/Trainer-Curriculum, `base_port` in config/*.yaml, `SetReward`, `EpisodeInterrupted`, `RequestDecision`-Aufrufe, Kamera-/Grid-Sensoren, Wand-/Obstacle-Kollisionsstrafe, Loch-Überquerungs-Bonus, curriculumabhängige Reward-Skalierung, GroundCheck-Kindobjekt, KillZone als Szenen-Objekt, Python-Dependency-Manifeste, venv im Repo, TensorBoard-Serverstart im Tooling, Port-Offset-Logik im Tooling.
7. ONNX-Exporte für die drei final_v3-Behaviors (Stand Erhebung).
8. configuration.yaml/training_status.json im Run-Ordner model_comparison_final_v3.

**NICHT AUFLÖSBAR (nur außerhalb des Repos bzw. der erlaubten Quellen klärbar):**
1. Exakter Paket-/Python-Stand der Trainings-venv `C:\Users\Finnl\mlagents-31008` (Indizien: mlagents 0.30.0 + torch 2.0.1+cu118 aus training_status.json der Läufe).
2. Gesamt-Parameterzahlen der Netze (mlagents-Encoder/Köpfe liegen in der venv; nur die Memory-Module sind berechnet, §10.2/10.3), ONNX-Tensor-Namen (ModelSerializer), letzte Zuordnung hidden_units→h_size.
3. Verhalten des Keys `memory_type` auf ungepatchter mlagents-0.30.0-Installation.
4. Ist-Zustand der Curriculum-State-Dateien (`Application.persistentDataPath\curriculum_state_*.json`).
5. Endstand des zum Erhebungszeitpunkt laufenden final_v3-Trainings.
6. m_Model-GUID-Auflösungen außerhalb des Repos: keine offen (alle in §8 aufgelöst).

**Tote/inaktive Pfade (BELEGT, rein deskriptiv):**
1. `noRuntimeObstacles` gesetzt, nie gelesen, NonSerialized (§6.7).
2. `obstaclePrefabs[]` deklariert, nirgends verwendet, im Prefab leer (MapGenerator.cs:50).
3. Tags ohne Laufzeit-Träger: Obstacle, Platform, Bridge → zugehörige Ray-Kanäle/Typ-Codes/GroundCheck-Zweige laufen im Training leer (§6.2).
4. Lava-Crossing-Zweig über `episodeEndedByTerminal` strukturell unerreichbar; der Landungs-Zweig (+8) ist erreichbar (§5).
5. Sprung-Branch: nur Wert 1 belegt, Werte 0/2 No-Ops bei BranchSize 3 (§3).
6. TrivialBranch-Pool (100 Layouts) und `MapData_Training_01–05` unreferenziert; `Layout_01–05` nur in Nicht-Trainings-Szenen (§7.3).
7. LavaMapGenerator schreibt loopStartPhaseIndex 6 vs. V2Builder/Asset 5 (§7.3).
8. `start_trainer.bat`/`_log`/`_watchdog` zeigen auf Fremdrechner-Pfade (`C:\Users\alxbe\…`) und ältere Run-IDs.
9. `hasLineOfSight` ohne Episoden-Reset; im v24CompatMode nie aktualisiert (§5).
10. Sensor_Test.unity-Override VectorObservationSize 13 passt zu keiner Code-Dimension (§2.5).

---

## Abschluss

### (a) Konsistenz-Checks zwischen den Domänen

| # | Check | Ergebnis |
|---|---|---|
| 1 | Summe AddObservation (31) ↔ Szenen-Override `VectorObservationSize` in Training Area.unity (27× 31) ↔ Builder-Wert (ModelComparisonSceneBuilder.cs:134) | **✓ konsistent** |
| 2 | Prefab-Basis: `VectorObservationSize 21` ↔ Code-Abbruch bei 21 im v24CompatMode (Prefab v24CompatMode=1; Szene überschreibt 27× auf 0) | **✓ konsistent** |
| 3 | Ray-Dimension: (6+2)·(2·5+1)·2 = 176 aus Prefab-Serialisierung; Policy-Input 31+176 = 207 (Vergleich) bzw. 21+176 = 197 (Basis) | **✓ rechnerisch geschlossen** |
| 4 | Aktions-Branches: Prefab [3,3,3] ↔ Code liest 3 Branches; Branch 2 nutzt nur Wert 1 (Größe 3 dennoch serialisiert) | **✓ konsistent, Anomalie dokumentiert (§3)** |
| 5 | Behavior-Namen: final_v3-YAML {MLP,LSTM,Transformer}_Navigator ↔ Szene 9/9/9 ↔ results-Ordnernamen | **✓ konsistent** |
| 6 | phaseMaxSteps: Script-Default = Prefab-Serialisierung = 8 Einträge ↔ 8 Curriculum-Phasen | **✓ konsistent** |
| 7 | Curriculum-Pools: Asset-Layoutzahlen (100/100/150/200/150/196/199/192) = Dateizählung auf Platte | **✓ deckungsgleich** |
| 8 | Physik: Prefab überschreibt Script-Defaults (jumpForce 10.5 vs. 9.0; maxUpwardVelocity 8 vs. 7.0) → effektiv Prefab; Vergleichsszene ohne weitere Overrides | **✓ dokumentiert, zwei Stände erfasst** |
| 9 | Sensor_Test.unity: Override 13 ↔ Code liefert 21/31 | **✗ Inkonsistenz (nur Test-Szene, nicht Training)** |
| 10 | export_onnx_standalone.py hartkodiert Obs (190,) und Branches (3,3,2) ↔ aktueller Stand 197/207 und [3,3,3] | **✗ Abweichung — Skript ist v14-Run-spezifisch (190 = 14 + 176 nur als Rechenhinweis, historischer Vektorstand nicht aus aktuellen Quellen belegbar)** |
| 11 | num_envs: YAML 3 ↔ standalone.bat 3 ↔ Watchdog-CLI **5** ↔ beobachtete 5 Player-Logs im aktiven final_v3-Run | **△ drei Stände; aktiver Lauf folgt dem Watchdog (CLI überschreibt YAML)** |
| 12 | Versionskette mlagents: Unity-Paket 2.0.2 (manifest+lock) ∥ Python mlagents 0.30.0 (setup_and_export.ps1 + 23× training_status.json) | **✓ in sich konsistent** |
| 13 | torch: Läufe 2.0.1+cu118/+cpu ↔ setup_and_export.ps1 installiert 1.8.1+cpu | **△ zwei venv-Zwecke (Training vs. Export/Barracuda) — dokumentiert** |
| 14 | KillZone: Code erzeugt y −20 zur Laufzeit ↔ keine Szenen-/Prefab-Objekte ↔ Reward-Trigger Tag KillZone | **✓ konsistent** |
| 15 | Curriculum-Persistenz: Code schreibt nach persistentDataPath ↔ keine State-Datei in results//Repo | **✓ konsistent (Datei liegt außerhalb Repo)** |
| 16 | Spawn/Goal: gebacken als Zellen; Prefab-Modi Predefined (1/1) ≠ Script-Defaults Random (0/0) → effektiv gebackene Zellen mit Fallback-Kaskade | **✓ dokumentiert, zwei Stände erfasst (§6.3)** |
| 17 | Watchdog-Entropiequelle `results/model_comparison_final_v3/Transformer_Navigator/*.tfevents` ↔ tatsächlicher Ordner existiert | **✓ konsistent** |

### (b) Nur außerhalb des Repos klärbar

1. Hardware der Trainingsläufe (GPU/CPU/RAM; einziges Indiz: torch 2.0.1+cu118 → CUDA-11.8-fähige NVIDIA-GPU bei 21 Läufen).
2. venv-Zustand `C:\Users\Finnl\mlagents-31008` (Python-Version — Ordnername suggeriert 3.10.8, unbelegt — und exakte Paketstände) sowie der historische alxbe-Rechner (`start_trainer.bat`).
3. Inhalt/Existenz der `curriculum_state_*.json` in `Application.persistentDataPath` (steuert, in welcher Phase ein Resume fortsetzt).
4. Endstand und TB-Metriken des laufenden model_comparison_final_v3-Trainings (Lauf war während der Extraktion aktiv).
5. Ob die im Watchdog/Build referenzierte `Build\KI_Agenten.exe` aus dem aktuellen Commit gebaut wurde (Build/ nicht versioniert; build.log liegt bei, wurde als Nicht-Quellartefakt nicht ausgewertet).
6. Sämtliche Aussagen der Markdown-/Typst-Dokumentation (verbotene Quellen; gegen dieses SSOT abzugleichen).

---

## 13. Nachtrag: Finale Vergleichsläufe und Generalisierungstests (Stand 2026-07-12)

**Abgrenzung zum Haupt-SSOT:** Die Abschnitte 0–12 sind ein Snapshot vom **2026-07-10** (final_v3 damals aktiv bei ~17 M Steps, §11). Dieser Nachtrag ergänzt Entwicklungen bis 2026-07-12 und löst mehrere in §12 als *NICHT VORHANDEN* geführte Punkte auf. Evidenzregeln wie im Haupt-SSOT: Belege aus Code/Assets/Configs/`results/`; für v3-Trainingszahlen ist die einzige verfügbare Quelle das generierte Report-Artefakt `Analyse/final_v3/report_*.pdf` (Roh-tfevents nicht committet) — Provenienz je Aussage markiert. Die in diesem Nachtrag beschriebenen C#-Dateien und Layout-Assets sind **Working-Tree-Ergänzungen, noch nicht committet** (Status wie `watchdog_final_v3.py` in §0).

### 13.1 Es existieren ZWEI finale Vergleichsläufe (nicht einer)

| Lauf | Config | Steps (Endstand) | Envs | Abschlusskriterium | Rechner/Ort | Beleg |
|---|---|---|---|---|---|---|
| **model_comparison_final_v2** | `config/model_comparison_final_v2.yaml` | **16 600 000** (~5,53 M/Behavior-Loop) | 3 | „5 volle Curriculum-Loops je Env“, dann Stopp (kein 30-M-Budget ausgeschöpft) | alxbe-Rechner | `results/model_comparison_final_v2/` (Checkpoints -16599xxx.pt/.onnx); Endpunkt-Protokoll `results/model_comparison_final_v2/loop5_stop_protokoll.txt` (Env-Abschlüsse 15:08/16:05/16:45 am 2026-07-11) |
| **model_comparison_final_v3** | `config/model_comparison_final_v3.yaml` | **30 000 000** (vollständig) | 5 (`--num-envs 5`, Watchdog §10.4) | volles 30-M-Budget | Finnl-Rechner (GPU) | `Evaluations_Vorbereitung/` auf `origin/ModelTrainingComparsion` (Commit `b253f6d`, Finn Ludwig, 2026-07-11); Checkpoints `checkpoints/{MLP-30000089,LSTM-30003930,Transformer-30006822}.pt`; Laufzeit „31h 11m“ (Report-Artefakt `Analyse/final_v3/report_2026-07-11_09-49.pdf` S.1) |

**Auflösung Naming-Kollision zur Doku:** Die Trainer-Abweichungstabelle der Typst-Doku (Transformer beta 5.0e-4/constant, lr_schedule constant, curiosity 0.02) beschreibt **final_v3**, nicht final_v2 — vgl. SSOT §9.2 „Diff final_v2 → final_v3“ (nur Transformer_Navigator geändert). final_v2 und final_v3 unterscheiden sich **ausschließlich in vier Transformer-Hyperparametern**; MLP- und LSTM-Behavior sind byte-identisch zwischen beiden Configs.

**Aktualisierung §11 (Lauf-Inventar):** Der dort als „Lauf aktiv, ~17 M“ inventarisierte `model_comparison_final_v3` ist zwischenzeitlich bei **30 M abgeschlossen** (2026-07-11 ~07:42, Report-Artefakt). Die finalen v3-Checkpoints liegen versioniert unter `Evaluations_Vorbereitung/checkpoints/` (die `results/`-Variante bleibt gitignored). **NICHT AUFLÖSBAR bleibt** der Endstand aus dem Haupt-SSOT damit teil-aufgelöst: v3 = 30 M vollständig; v2 = 16,6 M (Loop-5-Stopp).

### 13.2 Generalisierungstest-Infrastruktur (löst §12-NICHT-VORHANDEN #2 auf)

Neu im Working Tree (nicht committet):

- **`Assets/Scripts/Map/DifficultyLevel.cs:12`** — neuer Enum-Wert `Giant = 9` (Out-of-Distribution-Stufe). Zugehörige `DifficultySettings` (`:81–96`): Grid **40–50 × 48–60** (Hard max: 37 × 45, §6.4), Level1-Korridore 8–12, MaxBranchDepth 6, MaxTotalRooms 42, LoopProbability 0.35, BranchProbability 0.75, GoalLavaDepth3Chance 0.25.
- **`Assets/Editor/GeneralizationSceneBuilder.cs`** (Menü `Training/Generalisierungstest bauen (Maps + Szene)`, `:41`): erzeugt Held-out-Layouts mit **eigenem Seed-Bereich `SEED_BASE = 900000`** (`:26`, disjunkt zu allen Trainings-Seeds: Curriculum `42000+…` §7.3, MapGeneratorEditor `Random 0–999999`), Plan `(Easy 50, Medium 50, Hard 50, Giant 5)` (`:28–34`), Ausgabe `Assets/Layouts/Generalization/Layout_GEN_<Diff>_NNN.asset` (`:25`); baut die Testszene `Assets/Scenes/Generalization Test.unity` (`:24`) als Ableitung der Trainingsszene, reduziert auf **3 Areale mit je 1 Agent** (EvalArea_MLP/LSTM/Transformer). Zwei weitere Menüpunkte: `Generalisierungstest: Modelle zuweisen + Build` (ONNX-Zuweisung + Standalone-Build nach `Build_Gen/`) und `Generalisierungstest: Build für Python-Inferenz` (setzt BehaviorType=Default, Modell=null → Steuerung über Python-Trainer).
- **`Assets/Scripts/Evaluation/GeneralizationEvalManager.cs`** — Orchestrierung. Protokoll: `episodesPerMap = 5` (`:41`), `randomSeedBase = 777` (`:43`), **paarweise faire Seeds** `seed = randomSeedBase*1000 + m*100 + ep` pro Episode identisch über alle drei Areale (`:88` → identische Spawn/Ziel-Würfe je Architektur), `timeScale = 5` (`:45`; Zeitlimits gelten in simulierten Sekunden), Zeitlimits je Kategorie 45/75/110/**180**s (Easy/Medium/Hard/Giant, `:48–51`); Tod oder Timeout = Fehlschlag. Ausgabe CSV `results/generalization/generalization_results.csv`, Spalten `map;kategorie;episode;agent;erfolg;zeitSekunden` (`:17–18, 77`). Nach Abschluss `Application.Quit()`.
- **Held-out-Kartenbestand auf Platte:** `Assets/Layouts/Generalization/` = **155** Assets (Easy 50, Medium 50, Hard 50, Giant 5; Dateizählung 2026-07-12). Getrennt von allen Curriculum-Pools (§7.1) und den TrivialBranch/Layout_01–05-Beständen (§7.3).

**Testumfang je Lauf:** 155 Karten × 5 Episoden × 3 Architekturen = **2 325 Bewertungsepisoden** (CSV-Zeilen 2 326 inkl. Header, belegt für v2).

**Betriebsart (beide Tests):** Python-Inferenz `mlagents.trainers.learn <cfg> --run-id <id> --inference --resume --env Build_Gen\KI_Agenten_GenTest.exe --num-envs 1 --time-scale 5 --no-graphics`. Grund gegen ONNX-in-Unity: Der Transformer-Graph ist mit Barracuda 2.0.0 nicht lauffähig (nicht unterstützter `If`-Operator per Graph-Chirurgie entfernbar, aber `Reshape` der Attention sprengt Barracudas 4D-Tensormodell) — konsistent mit §10.4/Abschluss und mit `Evaluations_Vorbereitung/README` (nur MLP+LSTM als ONNX vorhanden, Transformer nur Python).

### 13.3 Ergebnisse Generalisierungstest — final_v2 (löst §12-#3 teil-auf)

Quelle: `results/generalization/generalization_results_run1.csv` (2 325 Episoden, vollständig). Erfolgsrate = Anteil Episoden mit Zielerreichung, je Kategorie 250 Episoden/Architektur (Giant: 25).

| Kategorie | LSTM | MLP | Transformer |
|---|---|---|---|
| Easy (50) | **90,4 %** | 64,0 % | 57,2 % |
| Medium (50) | **88,4 %** | 61,6 % | 56,0 % |
| Hard (50) | **69,6 %** | 36,4 % | 29,6 % |
| Giant (5, OOD) | **48,0 %** | 16,0 % | 8,0 % |

Rangfolge final_v2: **LSTM ≫ MLP > Transformer**, konsistent über alle Kategorien; Generalisierungslücke gegenüber Trainings-Blockmitteln ≈ 0.

### 13.4 Ergebnisse Generalisierungstest — final_v3 (Finns 30-M-Modelle)

**Setup-Besonderheit (BELEGT, reproduzierbar):** Finns Checkpoints wurden auf GPU gespeichert (CUDA-Tensoren; vgl. §11-Indiz torch 2.0.1+**cu118**). Direktes Laden auf CPU-Maschine wirft `RuntimeError: Attempting to deserialize object on a CUDA device`. Fix: `torch.load(f, map_location='cpu')` + `torch.save` je Checkpoint. Danach `--resume` sauber („Resuming from step 30006822/30003930/30000089“). results-Struktur: `results/finn_v3_gentest/<Behavior>/checkpoint.pt` (CPU-konvertierte Kopien der `Evaluations_Vorbereitung/checkpoints/`), run-id `finn_v3_gentest`, base-port 5008.

**Abgeschlossen 2026-07-12 ~03:4x.** Quelle: `results/generalization/generalization_results_finn_v3.csv` (2 325 Episoden, vollständig). Identische Testharness wie final_v2 (§13.3) — dieselbe Szene, dieselben 155 Held-out-Maps, dieselben paarweisen Seeds.

| Kategorie | LSTM | MLP | Transformer |
|---|---|---|---|
| Easy (50) | 8,0 % | 78,4 % | **84,4 %** |
| Medium (50) | 4,0 % | **83,6 %** | 79,6 % |
| Hard (50) | 0,8 % | **63,6 %** | 56,4 % |
| Giant (5, OOD) | 0,0 % | 40,0 % | **52,0 %** |

Karten-Abdeckung (≥1 Erfolg / 5-von-5 perfekt): LSTM Easy 15/50 (0 perfekt), Medium 9/50, Hard 2/50, Giant 0/5; MLP/Transformer je 43–49 von 50 pro Kategorie.

**Befund (vollständige Rangfolge-Umkehr gegenüber final_v2):** In final_v3 **kollabiert das LSTM** (0–8 % über alle Kategorien), während MLP und Transformer dominieren (Transformer auf Easy und Giant vorn, MLP auf Medium/Hard). **Kontrolle:** Dieselbe Harness lieferte für final_v2 ein LSTM mit 90,4 % (Easy) — der Unterschied liegt also **eindeutig in den Modellgewichten, nicht im Testaufbau**. Der v3-LSTM zeigt zudem eine extreme Trainings-→-Held-out-Lücke (Training-Rolling ~57,5 % laut §13.5 vs. Held-out 4–8 %), MLP/Transformer dagegen kleine Lücken — konsistent mit einer späten LSTM-Instabilität/Überanpassung in v3 (Rolling < Beste-Success am Laufende, §13.5).

### 13.5 Trainings-Unterschied v2 ↔ v3 (Report-Artefakt-Provenienz)

Quelle: `Analyse/final_v3/report_*.pdf` (36 Stundenreports, page-1-Tabellen; generierte Artefakte, keine Hand-Doku). „Beste Success“ = bestes je erreichtes Rolling-Success-Niveau (monoton).

| Beste-Success (Endstand) | LSTM | MLP | Transformer |
|---|---|---|---|
| final_v2 (16,6 M, `results/…final_v2` tfevents) | ~85 % | ~63 % | ~49 % |
| final_v3 (30 M, Report 2026-07-11_09-49 S.1) | 74,3 % | **88,6 %** | 79,0 % |

**Befund:** Die Architektur-Rangfolge ist **nicht laufstabil**. In final_v2 dominiert das LSTM, in final_v3 der MLP (LSTM Schlusslicht). Da MLP-/LSTM-Config zwischen v2 und v3 identisch sind (§13.1), stammt die Differenz aus Trainingsbudget (30 M vs. 16,6 M), venv-/mlagents-Version (v3: `C:\Users\Finnl\mlagents-31008`) oder Stochastik — **empirische Untermauerung der in §12-#4 als NICHT VORHANDEN geführten Mehr-Seed-Anforderung.**

### 13.6 Aktualisierung §12 (aufgelöste NICHT-VORHANDEN-Punkte)

- §12-#2 „Eval-/Test-/Holdout-Layout-Sets; Checkpoint-Evaluations-Pipeline auf fixem Map-Set“ → **jetzt VORHANDEN** (§13.2: 155 Held-out-Maps + GeneralizationEvalManager + Build_Gen, Working Tree).
- §12-#3 „Overfitting-Index“ → **teilweise VORHANDEN** als Messung (Trainings- minus Held-out-Erfolg, §13.3 ≈ 0 für v2); als Code-Metrik weiterhin nicht implementiert.
- §12-#4 „Mehrere Seeds/Läufe je Architektur“ → weiterhin **NICHT VORHANDEN** als Konfiguration, aber es liegen nun **zwei vollständige Läufe** (v2/v3) mit divergierender Rangfolge vor (§13.5) — de facto ein Reproduzierbarkeits-Signal, kein kontrollierter Seed-Sweep.
- §12-#7 „ONNX-Exporte der drei final-Behaviors“ → für **MLP/LSTM VORHANDEN** (`Evaluations_Vorbereitung/onnx/`, opset 10/11); **Transformer weiterhin NICHT** (Barracuda-inkompatibel, §13.2).
