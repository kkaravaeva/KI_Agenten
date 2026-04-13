# Gesamter Entwicklungsstand — KI-Agent zur Labyrinth-Navigation

**Team:** Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker
**Engine:** Unity 2021.3
**Framework:** Unity ML-Agents
**Stand:** Nach Abschluss Milestone 1–2, Milestone 3 und Milestone-4-Blocker

---

## 1. Projektübersicht

### Forschungsfrage

Kann ein Transformer-basierter RL-Agent in einer selbst gebauten 3D-Labyrinthwelt generalisierbares Navigations- und Hindernisvermeidungsverhalten erlernen, das sich auf unbekannte Map-Layouts übertragen lässt?

### Pflicht-Scope

- Selbst gebaute 3D-Labyrinthwelt in Unity mit grid-basiertem Map-System und mindestens fünf unterschiedlichen Map-Layouts
- Agent mit Bewegung in vier Richtungen und physikbasierter Sprungmechanik
- Ray-basierte Sensorik zur Unterscheidung von Wänden, Hindernistypen und Ziel
- Basis-Hindernisse: Lavafelder (tödlich, überspringbar), Löcher (tödlich, nicht passierbar) und Sackgassen
- Transformer-basiertes Entscheidungsmodell als Kern des Agenten
- MLP-Baseline zum direkten Vergleich mit dem Transformer-Modell
- Reward-System mit Belohnung für Ziel-Erreichen, Bestrafung für Lava/Loch (evtl. Zeitlimit)
- Mindestens eine Ablationsstudie und Generalisierungstest auf mindestens einer komplett unbekannten Map
- Beobachtbarkeit: Live-Viewer oder Replay-System, TensorBoard-Metriken (Reward, Erfolgsrate, Episodenlänge)
- Reproduzierbares Git-Repository
- Schriftlicher Bericht und Video-Demos der Lernphase und finalen Läufe

### Optionale Erweiterungen

- Dynamische Hindernisse (ausfahrende Stacheln, sich bewegende Elemente)
- Brücken (nur per Sprung nutzbar)
- Interaktive Mechaniken (Türen mit Knopfdruck)
- Sammelobjekte (Sterne zur Zeitstrafen-Reduktion)
- Weitere Ablationsstudien (Curriculum Learning, Sensorik-Konfigurationen, Ego- vs. Gott-Perspektive)
- Erhöhung der Map-Anzahl oder prozedurale Map-Generierung
- Multi-Agent-Setup (kooperative Labyrinth-Lösung)

---

## 2. Projektstruktur

### Ordnerstruktur

```
Assets/
├── Scripts/
│   ├── Map/
│   │   ├── CellType.cs
│   │   ├── MapData.cs
│   │   └── MapGenerator.cs
│   └── Agent/
│       └── LabyrinthAgent.cs
├── Editor/
│   └── MapGeneratorEditor.cs
├── Prefabs/
│   ├── Map/
│   │   ├── Floor.prefab
│   │   ├── Wall.prefab
│   │   ├── Goal.prefab
│   │   ├── SpawnPoint.prefab
│   │   └── Obstacles/
│   │       ├── Obstacle_Placeholder.prefab
│   │       ├── Lava_Placeholder.prefab
│   │       └── Hole_Placeholder.prefab
│   └── Agent/
│       └── Agent.prefab
└── Scenes/
    ├── Training/          # Haupt-Trainingsszene
    └── Sensor_Test.unity  # Szene zum Testen der Sensorik
```

### Szenen

- **Training-Szene (`Scenes/Training/`):** Enthält das GameObject `MapController` mit der `MapGenerator`-Komponente sowie den Agenten. Hier wird entwickelt und trainiert.
- **Sensor-Test-Szene (`Sensor_Test.unity`):** Enthält alle Hindernistypen (Wall, Obstacle, Lava, Hole, Goal, Bridge) zum Testen und Validieren der Sensorik. Hier wurden die Ray-Sensor-Parameter konfiguriert und visuell geprüft.

---

## 3. Map-System (Milestone 1–2, erweitert durch Main-Merge)

### Datenmodell

**CellType.cs** — Enum mit allen Zelltypen:

```csharp
public enum CellType
{
    Empty,      // Leere Zelle, wird nicht instanziiert
    Floor,      // Bodenfeld
    Wall,       // Wand
    Obstacle,   // Hindernis (generisch)
    Goal,       // Zielobjekt
    SpawnPoint  // Spawnpunkt des Agenten
}
```

**MapData.cs** — ScriptableObject als abstrakter Bauplan einer Map:
- Speichert die Map als eindimensionales Array von CellTypes
- Definiert Breite (`width`) und Höhe (`height`)
- Zugriff über `GetCell(x, y)` und `SetCell(x, y, type)`
- Interne Speicherung als flaches Array mit Formel `index = y * width + x`
- Asset-Erstellung im Editor über: Rechtsklick → Create → Map → MapData

### Map-Generator

**MapGenerator.cs** — MonoBehaviour am GameObject `MapController`:

Inspector-Felder (Milestone-3-Branch):

| Header | Feld | Typ | Beschreibung |
|---|---|---|---|
| Map Layouts | `mapLayouts` | `MapData[]` | Array aller verfügbaren Map-Layouts |
| Preview Selection | `selectedLayoutIndex` | `int` | Index des aktuell gewählten Layouts |
| Prefabs | `floorPrefab` | `GameObject` | Prefab für Bodenfelder |
| Prefabs | `wallPrefab` | `GameObject` | Prefab für Wände |
| Prefabs | `obstaclePrefabs` | `GameObject[]` | Array mit Obstacle-Varianten |
| Prefabs | `goalPrefab` | `GameObject` | Prefab für das Zielobjekt |
| Prefabs | `spawnPointPrefab` | `GameObject` | Prefab für den Spawnpunkt |
| Settings | `cellSize` | `float` | Abstand zwischen Zellen (Standard: 1) |
| Spawn Settings | `useCenterFallback` | `bool` | Bei fehlendem SpawnPoint: Map-Mitte statt Vector3.zero (default: false) |

Ablauf bei `GenerateMap()`:
1. MapData wird auf Vollständigkeit geprüft
2. Bestehende Map-Objekte werden gelöscht (`ClearMap()`)
3. Jede Zelle wird durchlaufen
4. Für den jeweiligen CellType wird das passende Prefab über `GetPrefabForCell()` ermittelt
5. Das Prefab wird an der Weltposition `(x * cellSize, 0, y * cellSize)` instanziiert
6. Alle Objekte werden unter `MapRoot` eingeordnet und in `spawnedObjects` gespeichert

Weitere Methoden:
- `ClearMap()` — Zerstört alle instanziierten Objekte
- `ResetMap()` — ClearMap + GenerateMap
- `NextLayout()` / `PreviousLayout()` — Wechselt zwischen Layouts
- `GetSpawnPosition()` — Sucht SpawnPoint-Zelle, gibt Weltposition zurück. Fallback: `Vector3.zero` + Warnung (oder Map-Mitte bei `useCenterFallback = true`)
- `GetFallbackPosition()` — Private Methode, liefert je nach `useCenterFallback` entweder `Vector3.zero` oder `((width-1)*cellSize*0.5, 0, (height-1)*cellSize*0.5)`

### Dynamische Runtime-Platzierung (Main-Branch)

Nach dem Merge von Milestone 1–2 in Main wurden Spawn, Goal und Hindernisse von festen MapData-Einträgen auf **dynamische Laufzeit-Platzierung** umgestellt:

- **Grundlayouts enthalten nur noch Wall und Floor** — SpawnPoint, Goal und Obstacle werden nicht mehr fest in MapData gespeichert
- **Spawnpunkt-Platzierung (Issue #40):** Beim Episodenstart wird genau ein Spawnpunkt zufällig auf einer gültigen Floor-Zelle erzeugt
- **Ziel-Platzierung (Issue #41):** Genau ein Zielobjekt wird zufällig auf einer gültigen Floor-Zelle platziert. Bereits im Layout vorhandene Goal-Zellen werden als Floor behandelt
- **Hindernis-Platzierung (Issue #42):** Hindernisse werden zur Laufzeit auf Floor-Zellen verteilt. Anzahl ist konfigurierbar. Platzierung variiert pro Episode
- **BFS-Pfadvalidierung (Issue #43):** Vor Episodenstart wird geprüft, dass kein Spawn auf Goal liegt, keine Hindernisse auf Spawn/Goal stehen, und ein begehbarer Pfad vom Spawn zum Goal existiert
- **Begehbare Flächen (Issue #39):** Die Grundlayouts wurden so vorbereitet, dass ausreichend freie Floor-Bereiche für flexible Platzierung existieren

### Fünf Map-Layouts

Fünf unterschiedliche Grundlayouts (map1–map5) existieren als JPEG-Pläne und als MapData-Assets. Sie unterscheiden sich in Wandplatzierung und Offenheit. Spawn, Goal und Hindernisse werden dynamisch darauf platziert. Aktuell enthalten die Layouts keine Sackgassen.

### Custom Editor

**MapGeneratorEditor.cs** — Custom Inspector für den MapGenerator mit Buttons:
- „Generate Selected Layout"
- „Previous Layout" / „Next Layout"
- „Clear Preview"

### Prefabs

| Prefab | Beschreibung | Tag | Collider |
|---|---|---|---|
| Floor | Flacher Cube, Scale (1, 0.1, 1) | Floor | Box Collider |
| Wall | Hoher Cube, Scale (1, 2, 1) | Wall | Box Collider |
| Goal | Sphere oder markierter Cube | Goal | Box Collider |
| SpawnPoint | Flacher Marker-Cube | — | Box Collider |
| Obstacle_Placeholder | Generischer Cube | Obstacle | Box Collider |
| Lava_Placeholder | Cube (Platzhalter) | Obstacle (⚠️ muss auf `Lava` umgestellt werden) | Box Collider |
| Hole_Placeholder | Cube (Platzhalter) | unklar (⚠️ muss auf `Hole` geprüft/umgestellt werden) | Box Collider |

### Tag Manager

Folgende Tags sind im Unity Tag Manager registriert:
`Wall`, `Obstacle`, `Lava`, `Hole`, `Goal`, `Bridge` — sechs Tags (Issue #28).

### Layer

- **Ground** — eigener Layer für Boden-Erkennung per Raycast. Zugewiesen an: Floor-Prefab, SpawnPoint-Prefab.

---

## 4. Agent-System (Milestone 3)

### Agent-Prefab

**Pfad:** `Prefabs/Agent/Agent.prefab`

Komponenten:
- **Rigidbody:** Freeze Rotation X/Z, Masse und Drag konfiguriert
- **CapsuleCollider:** Height = 2, passend in eine Grid-Zelle (cellSize = 1)
- **LabyrinthAgent** (Script): Erbt von `Unity.MLAgents.Agent`
- **BehaviorParameters:** Behavior Name = `LabyrinthNavigator`
- **DecisionRequester:** Decision Period = 5 (Entscheidung alle 5 FixedUpdates)
- **RayPerceptionSensorComponent3D:** Konfiguriert für horizontale Umgebungserkennung

Capsule-Child-Mesh: LocalPosition korrigiert auf (0, 0, 0) — war zuvor um (0.5, 0.05, 0.5) versetzt (Bugfix aus Issue #32).

### LabyrinthAgent.cs

**Felder:**
- `[Header("Map")] public MapGenerator mapGenerator` — Referenz auf den MapGenerator
- `moveSpeed = 2f` — Bewegungsgeschwindigkeit (serialisiert, im Inspector änderbar)
- `jumpForce = 3.5f` — Sprungkraft (serialisiert, im Inspector änderbar)
- `groundCheckDistance = 0.15f` — Toleranz für Bodenerkennung (serialisiert)
- `goalTransform` (private) — wird per `FindWithTag("Goal")` gesucht

**Methoden:**

`Initialize()`:
- Ruft `FindGoal()` auf

`OnEpisodeBegin()`:
- Ruft `FindGoal()` auf (für Map-Wechsel)
- Liest Spawn-Position über `mapGenerator.GetSpawnPosition()`
- Setzt `transform.localPosition = spawnPos + Vector3.up * 0.5f`
- Setzt `transform.localRotation = Quaternion.identity`
- Setzt `rb.velocity = Vector3.zero` und `rb.angularVelocity = Vector3.zero`

`CollectObservations(VectorSensor sensor)`:
- 3 Floats: Eigengeschwindigkeit (normalisiert durch moveSpeed)
- 1 Float: isGrounded-Status
- 3 Floats: Normalisierter Richtungsvektor zum Goal
- 6 Floats: Boden-Sensor (3 Raycasts × 2 Observations)
- **Total Space Size = 13** (die 6 Boden-Sensor-Observations sind darin enthalten; RayPerceptionSensor zählt sich automatisch separat)

`OnActionReceived(ActionBuffers actions)`:
- Branch 0 (Size 5): 0=Idle, 1=Vorwärts, 2=Rückwärts, 3=Links, 4=Rechts
- Branch 1 (Size 2): 0=Kein Sprung, 1=Sprung
- Bewegung über `Rigidbody.MovePosition()` in Weltkoordinaten (kein lokales Drehen)
- Sprung über `Rigidbody.AddForce(Vector3.up * jumpForce, ForceMode.Impulse)`, nur wenn `isGrounded == true`

`Heuristic(in ActionBuffers actionsOut)`:
- WASD = Bewegung, Space = Sprung, kein Input = Idle
- Input über `GetKey` (nicht GetKeyDown)
- Behavior Type muss auf „Heuristic Only" umgeschaltet werden für manuelles Testen

`FixedUpdate()`:
- Ground-Check per Raycast nach unten mit LayerMask „Ground"

`FindGoal()`:
- Sucht Goal per `FindWithTag("Goal")`
- Fallback bei fehlendem Goal: drei Nullen als Zielrichtung + Console-Warnung

`OnDrawGizmosSelected()`:
- Gelbe Linie Richtung Goal (Zielrichtung visualisiert)
- Ground-Check-Linie: grün = grounded, rot = in der Luft
- Boden-Sensor-Raycasts: cyan = sicher, magenta = Gefahr

### Aktionsraum (Detail)

| Branch | Size | Aktionen | Bewegungsmethode |
|---|---|---|---|
| 0 (Bewegung) | 5 | 0=Idle, 1=Vorwärts (+Z), 2=Rückwärts (-Z), 3=Links (-X), 4=Rechts (+X) | `Rigidbody.MovePosition()` |
| 1 (Sprung) | 2 | 0=Kein Sprung, 1=Springen | `Rigidbody.AddForce(Impulse)` |

Bewegung und Sprung können gleichzeitig gewählt werden (zwei separate Branches). Dies ist nötig, damit der Agent Lava-Zellen im Vorwärtslauf überspringen kann.

### Sprungkalibrierung

| Parameter | Wert | Herleitung |
|---|---|---|
| moveSpeed | 2f | Bei 3f überspringt Agent auch 2-Zellen-Lücken (2.75 Zellen). Bei 2f = 1.43 Zellen Sprungweite |
| jumpForce | 3.5f | Zusammen mit moveSpeed=2: Sprungweite ~1.43 (>1, <2), Sprunghöhe ~0.62 |
| Gravity | Unity-Standard (-9.81) | Unverändert |

Ergebnis: 1-Zellen-Lücke überwindbar, 2-Zellen-Lücke nicht. Kein Doppelsprung möglich (isGrounded-Check).

### Designentscheidung: Zielrichtung als Observation

**Gewählt: Option A — Zielrichtung als Observation, mit geplantem Vergleich.**

Der Agent bekommt einen normalisierten Richtungsvektor zum Goal (3 Floats). Begründung:
- Ermöglicht schnelle Validierung der gesamten Trainings-Pipeline
- Schnellere Konvergenz im ersten Trainingsdurchlauf
- Ein späteres Experiment ohne Zielrichtung ist als Ablationsstudie geplant (Vergleich: Wie stark profitiert der Agent vom eingebauten Kompass vs. reine Exploration?)

---

## 5. Sensorik (Milestone 3)

### Horizontaler Ray-Sensor (RayPerceptionSensorComponent3D)

| Parameter | Wert | Begründung |
|---|---|---|
| Sensor Name | RayPerceptionSensor | — |
| Detectable Tags | Wall, Obstacle, Lava, Hole, Goal, Bridge | 6 Tags für alle relevanten Objekttypen |
| Rays Per Direction | 5 (11 total) | Bessere Abdeckung von Korridoren und Abzweigungen |
| Max Ray Degrees | 120° | Menschenähnliches Sichtfeld, deckt seitliche Abzweigungen ab |
| Sphere Cast Radius | 0.25 | Anpassung an Agent-Capsule-Radius, vermeidet falsche Treffer in schmalen Durchgängen |
| Ray Length | 12 | 12 Zellen Vorausschau bei cellSize=1 |
| Stacked Raycasts | 2 | Implizite Bewegungserkennung durch Vergleich mit vorherigem Frame |
| Start Vertical Offset | 0.25 | Rays auf Hüfthöhe des Agents |
| End Vertical Offset | 0.5 | Rays verlaufen leicht ansteigend |
| Ray Layer Mask | Mixed (alles außer Ignore Raycast) | — |

Die RayPerceptionSensor-Observations werden automatisch zum Observation-Vektor addiert und müssen nicht in der Space Size berücksichtigt werden.

### Boden-Sensor (manuell in CollectObservations)

Zusätzlich zu den horizontalen Rays gibt es einen manuellen Boden-Sensor für die Erkennung von Gefahren direkt unter und vor dem Agenten.

**Technische Details:**

| Aspekt | Umsetzung |
|---|---|
| Ansatz | Manuelle Raycasts nach unten in `CollectObservations()` |
| Anzahl Raycasts | 3 (unter Agent, 1 Zelle voraus, 2 Zellen voraus) |
| Observations pro Raycast | 2 (Typ-Code + normalisierte Distanz) |
| Observations total | 6 |

**Erkannte Bodentypen und Typ-Codes:**

| Bodentyp | Typ-Code |
|---|---|
| Floor | 1.0 |
| Bridge | 0.5 |
| Unbekannt | 0.0 |
| Hole | -0.5 |
| Lava | -1.0 |
| Kein Treffer (Abgrund) | -0.5 (Hole-Code + max Distanz) |

**Designentscheidung:** Eine zweite `RayPerceptionSensorComponent3D` war technisch nicht möglich — die Komponente castet ausschließlich in der horizontalen Ebene. Daher manuelle Raycasts (~30 Zeilen Code).

**Gizmo-Visualisierung:** Cyan = sicherer Boden, Magenta = Gefahr. Flackern im Play-Mode ist rein visuell (asynchrones Editor-Repaint) und beeinflusst Training nicht.

**Offener Punkt:** Die Boden-Sensoren wurden implementiert, aber noch nicht mit einer Map validiert, die alle Bodentypen (Lava, Hole, Floor) gleichzeitig enthält. Wird in Milestone 4 bei der Hindernisimplementierung abgedeckt.

### Observation-Zusammenfassung

| Quelle | Anzahl Floats | Beschreibung |
|---|---|---|
| RayPerceptionSensor3D | automatisch | 11 Rays × 2 Frames (Stacked) × (6 Tags + 2 Werte) — wird von ML-Agents verwaltet |
| Eigengeschwindigkeit | 3 | `rb.velocity / moveSpeed` (normalisiert) |
| isGrounded | 1 | 1.0 wenn am Boden, 0.0 wenn in der Luft |
| Zielrichtung | 3 | Normalisierter `Vector3` Richtung Goal |
| Boden-Sensor | 6 | 3 Raycasts × (Typ-Code + Distanz) |
| **Space Size (manuell)** | **13** | Velocity(3) + isGrounded(1) + Zielrichtung(3) + Boden(6) |

---

## 6. Abgeschlossene Issues (Gesamtübersicht)

### Milestone 1–2 (Map-System & Mehrere Maps)

| Issue | Titel | Status | Bearbeiter |
|---|---|---|---|
| #2 | Map Plan — 5 Map Designs erstellen | ✅ | David Pelcz |
| #3 | Map-Generator-Script erstellen | ✅ | — |
| #4 | Projektstruktur für das Map-System anlegen | ✅ | — |
| #19 | Map-Auswahlmechanismus implementieren | ✅ | Ekaterina |
| #20 | Map-Reset mit wechselnden Maps integrieren | ✅ | Ekaterina |
| #39 | Begehbare Platzierungsflächen definieren | ✅ | Ekaterina |
| #40 | Zufällige Spawnpunkt-Platzierung pro Episode | ✅ | Ekaterina |
| #41 | Zufällige Ziel-Platzierung pro Episode | ✅ | Ekaterina |
| #42 | Zufällige Hindernis-Platzierung pro Episode | ✅ | Ekaterina |
| #43 | Gültigkeitsprüfung (BFS-Pfadvalidierung) | ✅ | Ekaterina |
| #44 | Testszene zur Validierung | ✅ | Ekaterina |

### Milestone 3 (Agent-Grundsystem)

| Issue | Titel | Status | Bearbeiter |
|---|---|---|---|
| #21 | Agent-Prefab anlegen und Grundstruktur | ✅ | — |
| #22 | ML-Agents-Komponente konfigurieren | ✅ | Finn |
| #23 | Agent-Script anlegen mit Grundgerüst | ✅ | — |
| #24 | Discrete Action Space definieren (6 Aktionen) | ✅ | Finn |
| #25 | Horizontale Bewegungssteuerung implementieren | ✅ | Finn |
| #26 | Sprungmechanik implementieren und kalibrieren | ✅ | Finn |
| #27 | Heuristic-Modus für manuelles Testen | ✅ | Finn |
| #28 | Fehlende Tags und Dummy-Prefabs für Sensorik | ✅ | Alexander |
| #29 | RayPerceptionSensor3D-Komponente hinzufügen | ✅ | Alexander / Finn |
| #30 | Ray-Sensor-Parameter konfigurieren | ✅ | Finn |
| #31 | Boden-Sensor für sichere/unsichere Felder | ✅ | Finn |
| #32 | Zusätzliche Observations sammeln | ✅ | Finn |
| #33 | Sensorik visuell debuggen und validieren | ✅ | Finn |
| #34 | Spawn-Daten aus Map-Datenmodell auslesen | ✅ | Finn |
| #35 | Agent-Spawn in OnEpisodeBegin einbauen | ✅ | Finn |
| #36 | Spawn bei Map-Wechsel testen | ✅ | Finn |

### Milestone 1.x (Neues Issue-Set, noch offen)

| Issue | Titel | Status |
|---|---|---|
| #62 | 1.1 Projektstruktur anlegen | offen |
| #64 | 1.2 Map-Datenmodell & Generator | offen |
| #66 | 1.3 Prefabs & Positionierung | offen |
| #69 | 1.4 Map-Erzeugung & Reset | offen |
| #71 | 1.5 Tag-System & Sensorvorbereitung | offen |
| #73 | 1.6 Mehrere Map-Layouts erstellen | offen |
| #74 | 1.7 Map-Auswahl & Rotation | offen |
| #77 | 1.8 Testszene & Validierung | offen |

**Hinweis:** Die Issues #62–#77 scheinen eine Neu-Anlage der Roadmap-Struktur zu sein. Der darunter beschriebene Inhalt ist durch die älteren Issues (#2–#44) bereits umgesetzt.

---

## 7. Merge-Konflikte und Entscheidungen

### Merge Milestone-3 → Main

Bei der Zusammenführung von Milestone-3-Branch in Main gab es Konflikte im `MapGenerator.cs`. Auflösung:

**Übernommen aus Main:**
- Runtime-Obstacles, Kamera-Framing, zufällige Spawn-/Goal-Auswahl, BFS-Pfadvalidierung (gesamte Logik aus Issues #39–#44)

**Übernommen aus Milestone-3:**
- `useCenterFallback`-Feld (im Header „Spawn Settings")
- Neue private Methode `GetFallbackPosition()` — liefert je nach Einstellung `Vector3.zero` oder Map-Mitte
- `GetSpawnPosition()` ruft an beiden Fehlerstellen `GetFallbackPosition()` statt hart `Vector3.zero` auf

**Verworfen aus Milestone-3:**
- `useRandomSpawnPoint` — Main wählt Spawns grundsätzlich zufällig aus allen begehbaren Zellen, das Feld wäre wirkungslos gewesen

---

## 8. Getroffene Designentscheidungen (Milestone-4-Blocker)

### Entscheidung 1: CellType-Erweiterung

**Entscheidung:** Keine neuen CellTypes (`Lava`, `Hole`) im Enum. Unterscheidung läuft über Tags an den Prefabs + Anpassung der dynamischen Platzierungslogik.

**Begründung:**
1. Hindernisse werden dynamisch zur Laufzeit platziert (Issues #40–#43). `GetPrefabForCell()` wird dafür nicht verwendet. Neue CellTypes hätten keinen Aufrufer.
2. Die Sensor-Erkennung (Ray-Sensor + Boden-Sensor) arbeitet bereits tag-basiert und ist unabhängig vom CellType-Enum.
3. Die Tags `Lava`, `Hole`, `Bridge` existieren bereits im Tag Manager.

**To-Dos für Milestone 4:**
- Prefab-Tags korrigieren: `Lava_Placeholder` → Tag `Lava`, `Hole_Placeholder` → Tag `Hole`
- Dynamische Platzierungslogik erweitern: Zwischen Lava- und Hole-Prefabs unterscheiden
- BFS-Pfadvalidierung prüfen: Lava als „überwindbar" (überspringbar), Hole als „nicht passierbar" behandeln

### Entscheidung 2: Sackgassen

**Entscheidung:** Kein eigenes Prefab, kein eigener CellType, kein eigener Tag. Sackgassen sind rein durch Wandkonfiguration definiert.

**Begründung:**
1. Layout-Merkmal, kein Hindernis-Prefab — keine Kollisionslogik nötig
2. Bestehende Sensorik (Wall-Tag) deckt die Erkennung ab
3. Aktuelle Maps enthalten keine Sackgassen
4. Spätere Erweiterung über Layout-Anpassung jederzeit möglich ohne Code-Änderungen

### Entscheidung 3: Zielrichtung als Observation

**Entscheidung:** Option A — Agent bekommt normalisierten Richtungsvektor zum Goal (3 Floats).

**Begründung:** Schnelle Pipeline-Validierung, schnellere Konvergenz. Experiment ohne Zielrichtung als Ablationsstudie geplant.

---

## 9. Heuristic-Testprotokoll (Milestone 3)

| Test | Status | Anmerkung |
|---|---|---|
| Idle ohne Input | ✅ bestätigt | Agent bleibt stehen |
| WASD Bewegung alle 4 Richtungen | ✅ bestätigt | — |
| Sprung funktioniert | ✅ bestätigt | — |
| Kein Doppelsprung | ✅ bestätigt | isGrounded-Check funktioniert |
| Wandkollision kein Durchdringen | ❌ nicht getestet | — |
| 1-Zellen-Lücke übersprungen | ❌ nicht getestet | Braucht Lava-Zellen oder manuell gebaute Lücke |
| 2-Zellen-Lücke nicht übersprungen | ❌ nicht getestet | Braucht Lava-Zellen oder manuell gebaute Lücke |

Die drei nicht getesteten Punkte werden in Milestone 4 bei der Hindernisimplementierung abgedeckt.

---

## 10. Offene Punkte und bekannte Limitierungen

### Noch nicht umgesetzt (steht in den nächsten Milestones an)

- **Milestone 4:** Lava- und Hole-Prefabs mit korrekten Tags, Todeslogik bei Kontakt, Episode-Reset bei Tod
- **Milestone 5:** Reward-System (konkrete Werte), Trainingsumgebung (YAML-Config), erstes Training
- **Milestone 6:** Transformer-Integrationsstrategie, Ablationsstudien-Auswahl, Evaluationskonzept
- **Milestone 7:** Transformer-Modell implementieren und trainieren
- **Milestone 8:** MLP-Baseline, Modellvergleich, Ablationsstudie(n)
- **Milestone 9:** Generalisierungstest auf unbekannter Map
- **Milestone 10:** (in Roadmap nicht explizit nummeriert)
- **Milestone 11:** Erweiterungen auswählen und implementieren
- **Milestone 12:** Schriftlicher Bericht, Video-Demos, Repository finalisieren

### Noch ungeklärte Rahmenbedingungen

- **Python/PyTorch-Kompetenz im Team:** Abfrage lief zum Zeitpunkt der Heistermann-Kritik — aktueller Status unklar
- **Hardware/GPU-Zugang:** Nur Laptops (CPU) — GPU-Zugang für Transformer-Training muss geklärt werden
- **Transformer-Integrationsstrategie:** ML-Agents Custom Network API vs. separates Framework — Entscheidung steht in Milestone 6 an
- **Nächste Einreichung bei Heistermann:** Termin und Format unklar
- **Teamaufteilung:** Bisher keine festen Verantwortungsbereiche formalisiert. Heistermann erwartet: (1) 3D-Umgebung/Maps/Hindernisse, (2) RL-Problem/Reward/Baseline, (3) Transformer-Modell, (4) Evaluation/Doku/Reproduzierbarkeit

### Bekannte technische Schulden

- Prefab-Tags `Lava_Placeholder` und `Hole_Placeholder` tragen noch falsche Tags (→ Milestone 4)
- Boden-Sensor noch nicht mit echten Lava/Hole-Zellen validiert (→ Milestone 4)
- Wandkollisions-Test und Sprungkalibrierungs-Test mit echten Hindernissen stehen aus (→ Milestone 4)
- Die Issue-Nummern #62–#77 duplizieren inhaltlich die bereits abgeschlossenen Issues #2–#44 — Bereinigung im Issue-Tracker empfohlen

---

## 11. Erwartungshaltung Herr Heistermann (Zusammenfassung)

### Liefergegenstände

- Funktionierende 3D-Welt in Unity
- Trainierter Agent mit Transformer-Modell
- MLP-Baseline zum Vergleich
- Mindestens eine Ablationsstudie
- Reproduzierbares Git-Repository mit Seeds, Skripten, Configs, Anleitung
- Video-Demos der Lernphase und finalen Läufe
- Live-Viewer oder Replay-System
- Schriftlicher Bericht

### Fachliche Tiefe im Bericht

- Klare Problemdefinition (Pflicht vs. optional)
- Systemarchitektur (grafisch)
- Formale RL-Spezifikation (Beobachtungsraum, Aktionsraum, Reward, Episodenlogik — mit konkreten Zahlen)
- Methodische Begründung (Warum PPO, ML-Agents, Ray-Sensoren — mit Alternativen)
- Transformer-Rolle konkret (Eingaben, Ausgaben, Architektur, Mehrwert)
- Evaluationsplan (Metriken, Generalisierung, Baseline, Ablation, statistische Auswertung)

### Arbeitsorganisation

- Klare Arbeitspakete mit namentlichen Zuständigkeiten
- Realistische Zeitplanung
- Transparenter Umsetzungsstand
- KI-Nutzung ist erlaubt — Erwartungen sind deshalb **höher**

---

## 12. Roadmap-Übersicht (Milestones 1–12)

| Milestone | Thema | Status |
|---|---|---|
| 1 | Projektstruktur & Map-Grundsystem | ✅ Abgeschlossen |
| 2 | Mehrere Maps & Sensorvorbereitung | ✅ Abgeschlossen |
| 3 | Agent-Grundsystem | ✅ Abgeschlossen |
| 4 | Hindernisse & Interaktion | ⏳ Blocker-Issue erledigt, Umsetzung steht an |
| 5 | Reward-System & Training | ⬜ Offen |
| 6 | Recherche & Entscheidungsfindung | ⬜ Offen |
| 7 | Transformer-Modell | ⬜ Offen |
| 8 | MLP-Baseline, Vergleich & Ablation | ⬜ Offen |
| 9 | Generalisierungstest | ⬜ Offen |
| 10 | (nicht explizit in Roadmap) | — |
| 11 | Erweiterungen | ⬜ Offen |
| 12 | Bericht & Video-Demos | ⬜ Offen |


# Danach bearbeitete issues:

## Issue #82 — Zusammenfassung

Ausgangslage (bei Überprüfung vorgefunden):
Die Tags Lava und Hole existierten bereits im Tag Manager (zusammen mit Wall, Obstacle, Goal, Floor, Bridge). Die Prefabs Lava_Placeholder und Hole_Placeholder trugen bereits ihre korrekten Tags (Lava bzw. Hole), nicht mehr den generischen Tag Obstacle. Der RayPerceptionSensor3D des Agenten hatte bereits 6 Detectable Tags konfiguriert, darunter Lava und Hole.

Erledigte Änderung:
Der Tippfehler im Prefab-Namen wurde korrigiert: Hole_Placeholer → Hole_Placeholder.

Überprüfungen:

Tag Manager: 7 Tags vorhanden (Wall, Obstacle, Goal, Floor, Lava, Hole, Bridge) — bestätigt per Screenshot aus Unity Editor.
Prefab-Tags: Lava_Placeholder trägt Tag Lava, Hole_Placeholder trägt Tag Hole — bestätigt per Screenshot aus Unity Editor (Tag-Dropdown).
RayPerceptionSensor3D: 6 Detectable Tags konfiguriert, Lava und Hole enthalten — bestätigt per Screenshot des Inspector.
Boden-Sensor (LabyrinthAgent.cs): Erkennt laut Dokumentation bereits Lava (Code -1.0) und Hole (Code -0.5) als separate Tag-basierte Bodentypen. Kein Anpassungsbedarf.
MapGenerator.cs: Kein String-Vergleich mit "Obstacle" im Code. Zuordnung läuft über CellType-Enum und Inspector-Prefab-Referenzen. Die Tag-Umstellung an den Prefabs hat keine Auswirkung auf dieses Script. Kein Anpassungsbedarf.
CellType.cs: Bleibt unverändert — laut Entscheidung aus Issue 4.0 werden keine neuen CellTypes für Lava/Hole angelegt. Die Unterscheidung läuft ausschließlich über Tags.
Dynamische Platzierungslogik (Issues #40–#43): Quellcode war nicht in den Projektdateien verfügbar. Laut Issue 4.0 ist die Erweiterung dieser Logik (Unterscheidung Lava/Hole-Prefabs bei Runtime-Platzierung) ein separates To-Do für Milestone 4, nicht Teil von Issue #82.


Akzeptanzkriterien:
KriteriumStatusTags Lava und Hole existieren im Tag ManagerErfüllt (bereits vorhanden)Beide Prefabs tragen ihren jeweiligen ne1uen TagErfüllt (bereits vorhanden)Tippfehler im Prefab-Namen behobenErfüllt (manuell korrigiert)Ray-Sensor erkennt beide neuen TagsErfüllt (bereits konfiguriert)

## Issue 83

 Ausgangslage

Das Prefab `Lava_Placeholder` war ein generischer Cube mit Scale (1, 1, 1), Unity-Standardmaterial (grau), einem physischen BoxCollider (IsTrigger = false, Size 1×1×1) und — nach Issue 82 — bereits korrektem Tag `Lava`.

 Durchgeführte Änderungen

**1. Geometrie angepasst:**
Transform Scale von (1, 1, 1) auf (1, 0.1, 1) geändert. Das Lavafeld liegt damit flach auf Bodenhöhe, analog zum Floor-Prefab.

**2. Material zugewiesen:**
Neues Material `M_Lava01` erstellt und abgelegt unter `Assets/Materials/M_Lava01.mat`. Farbgebung rot/orange, damit Lava visuell eindeutig vom Floor unterscheidbar ist. Im MeshRenderer des Prefabs als Element 0 zugewiesen.

**3. BoxCollider auf IsTrigger = true gesetzt:**
Der Agent wird nicht mehr physisch blockiert, sondern kann das Lavafeld durchlaufen. Die Todeslogik greift später per `OnTriggerEnter` (separates Issue 4.2).

**4. BoxCollider-Größe angepasst:**
Size auf (1, 4, 1) und Center auf (0, 2.5, 0) gesetzt. Durch die Scale (Y=0.1) ergibt das eine Welt-Trigger-Höhe von 0.4 Einheiten (von Y=0.05 bis Y=0.45). Herleitung: Die Sprunghöhe des Agenten beträgt ~0.62 Einheiten (aus Issue 26, jumpForce=3.5, moveSpeed=2). Die Trigger-Oberkante (0.45) liegt unterhalb der Sprunghöhe (0.62), sodass der Agent beim Springen den Trigger nicht auslösen sollte, beim Laufen aber schon.

 Bewusst ausgeklammert

- **Trigger-Kalibrierung (Heuristic-Test):** Die vorgeschlagenen Collider-Werte basieren auf rechnerischer Herleitung. Ein praktischer Test im Heuristic-Modus (Laufen löst Trigger aus, Springen nicht) steht noch aus und wird in einem späteren Issue durchgeführt. Falls die Werte nicht passen, muss Size.Y bzw. Center.Y nachjustiert werden.
- **Todeslogik (`OnTriggerEnter`):** Ist nicht Teil dieses Issues, sondern von Issue 4.2 (Todeslogik & Episode-Reset).
- **Temporäres Test-Script (`LavaTriggerTest.cs`):** Wurde als Hilfsmittel für den späteren Kalibrierungstest vorbereitet, ist aber noch nicht am Prefab angehängt.

 Akzeptanzkriterien

| Kriterium | Status |
|---|---|
| Prefab liegt flach auf Bodenhöhe | Erfüllt — Scale (1, 0.1, 1) |
| Visuell deutlich von Floor unterscheidbar | Erfüllt — eigenes Material `M_Lava01` (rot/orange) |
| BoxCollider ist IsTrigger = true | Erfüllt |
| Trigger-Höhe kalibriert (Laufen löst aus, Springen nicht) | Rechnerisch hergeleitet, praktischer Test ausstehend |

## Issue Map Rework (ohne nummer)
 Issue: Konfigurierbare Hindernis-Platzierung (ObstaclePlacementMode)

**Datum:** 11.04.2026
**Betroffene Datei:** `Assets/Scripts/Map/MapGenerator.cs`
**Keine Änderungen an:** `CellType.cs`, `MapData.cs`, `LabyrinthAgent.cs`, `MapGeneratorEditor.cs`, `MapDataEditor.cs`, Prefabs

---

 Ausgangslage

- Hindernisse wurden ausschließlich zufällig auf beliebigen begehbaren Floor-Zellen platziert (Issue 42)
- Layouts enthielten nur `Wall` und `Floor` — keine Möglichkeit, Hindernis-Positionen im Layout vorzudefinieren
- `CellType.Obstacle` existierte im Enum, wurde im Code aber als Floor gerendert und als begehbar behandelt

---

 Umgesetzte Änderungen

 1. Neues Enum `ObstaclePlacementMode`

```csharp
public enum ObstaclePlacementMode
{
    RandomOnFloor,
    PredefinedSpawnPoints
}
```

Definiert oberhalb der `MapGenerator`-Klasse, analog zu `MapSelectionMode`.

 2. Neues Inspector-Feld

```csharp
[Header("Obstacle Placement")]
public ObstaclePlacementMode obstaclePlacementMode = ObstaclePlacementMode.RandomOnFloor;
```

Default: `RandomOnFloor` (bisheriges Verhalten). Erscheint automatisch im Inspector, da `MapGeneratorEditor.cs` `DrawDefaultInspector()` verwendet.

 3. `GetObstacleCandidateCells()` — Modusunterscheidung

- **`RandomOnFloor`:** Alle begehbaren Zellen sind Kandidaten (Verhalten unverändert)
- **`PredefinedSpawnPoints`:** Nur Zellen mit `CellType.Obstacle` aus dem Layout sind Kandidaten

 4. `SelectRandomSpawnCell()` — Obstacle-Zellen ausgeschlossen

Im Modus `PredefinedSpawnPoints` werden `CellType.Obstacle`-Zellen aus der Spawn-Kandidatenliste entfernt. Agent spawnt nur auf `Floor`, `SpawnPoint` oder `Goal`-Zellen.

 5. `SelectRandomGoalCell()` — Obstacle-Zellen ausgeschlossen

Analog zu `SelectRandomSpawnCell()`: Im Modus `PredefinedSpawnPoints` wird das Goal nicht auf Obstacle-Markern platziert.

---

 Getroffene Entscheidungen

 Entscheidung 1: Obstacle-Zellen aus Spawn/Goal-Auswahl ausschließen

**Gewählt:** Ausschließen im Modus `PredefinedSpawnPoints`

**Begründung:** Obstacle-Marker sind für Hindernisse reserviert. Wenn Spawn/Goal diese Positionen belegen, reduziert das die verfügbaren Hindernispositionen und unterläuft die Kontrolle des Level-Designers. Der Aufwand ist minimal (eine Bedingung pro Methode).

 Entscheidung 2: Unbelegte Obstacle-Marker als Floor belassen

**Gewählt:** Keine Änderung — unbelegte Marker werden als Floor gerendert und sind begehbar

**Begründung:**
- Kein zusätzlicher Code nötig
- Trainingsfreundlich: Agent lernt, dass Positionen episodenabhängig variieren
- `GetPrefabForCell(CellType.Obstacle)` gibt bereits `floorPrefab` zurück

---

 Nicht geänderte Stellen (geprüft)

| Stelle | Begründung |
|---|---|
| `CellType.cs` | `Obstacle` existiert bereits, kein neuer Wert nötig |
| `MapData.cs` | Generisch, keine Anpassung |
| `LabyrinthAgent.cs` | Nutzt nur `GetSpawnPosition()` und `FindWithTag("Goal")` — Schnittstellen unverändert |
| `MapGeneratorEditor.cs` | Verwendet `DrawDefaultInspector()`, neues Feld erscheint automatisch |
| `MapDataEditor.cs` | Paint Tool unterstützt `CellType.Obstacle` bereits (Label „O", Farbe Orange) |
| `IsWalkableCellType()` | Obstacle bleibt begehbar — korrekt für BFS (unbelegte Marker sind passierbar) |
| `HasWalkablePath()` | Belegte Marker werden über `blockedCells`-Parameter blockiert — funktioniert ohne Änderung |
| `PlaceRuntimeObstacles()` | Iteriert über Kandidaten aus `GetObstacleCandidateCells()` — Modusunterscheidung dort |
| `SpawnRuntimeMarkersAndObstacles()` | Instanziiert aus `currentRuntimeObstacleCells` — generisch genug |
| `GetRuntimeObstaclePrefab()` | Wählt zufällig aus `obstaclePrefabs[]` — unverändert |
| Prefabs | Keine Prefab-Änderungen |

---

 Layout-Status

Alle fünf Layouts wurden mit `CellType.Obstacle`-Zellen (`03`) erweitert:

| Layout | Größe | Obstacle | Goal | SpawnPoint | Floor |
|---|---|---|---|---|---|
| Layout_01 | 25×30 | 10 | 1 | 1 | 257 |
| Layout_02 | 25×30 | 4 | 1 | 1 | 208 |
| Layout_03 | 25×30 | 12 | 0 | 0 | 218 |
| Layout_04 | 25×30 | 21 | 1 | 1 | 217 |
| Layout_05 | 18×30 | 30 | 0 | 1 | 172 |

Layouts ohne Goal/SpawnPoint-Zellen funktionieren korrekt — Spawn und Goal werden dynamisch auf Floor-Zellen platziert.


 Offene Punkte

 1. Zusammenhängende Obstacle-Gruppen gleicher Typ

Nebeneinanderliegende Obstacle-Marker erhalten aktuell unabhängig voneinander einen zufälligen Typ (Lava oder Hole). Gewünscht: Benachbarte Marker sollen denselben Hindernistyp erhalten. Erfordert Cluster-Erkennung in `PlaceRuntimeObstacles()` oder `SpawnRuntimeMarkersAndObstacles()` (z. B. Flood-Fill auf Obstacle-Markern, dann pro Cluster einen Typ zuweisen).

 2. Hole-Prefab Collider/Trigger

`Hole_Placeholder` hat noch `IsTrigger = false` und Scale `(1,1,1)`. Muss analog zu `Lava_Placeholder` angepasst werden (Milestone 4, Issue 4.2: Todeslogik).

 3. Todeslogik

`OnTriggerEnter` für Lava/Hole und Episode-Reset bei Kontakt steht noch aus (Milestone 4, Issue 4.2).

## Issue 84:
Zusammenfassung für Issue 84 — Dokumentation
Designentscheidung: Variante (a) — echtes Loch mit Durchfallen
Der Agent fällt physisch durch das Hole. Die Episode endet erst, wenn der Agent eine Kill-Box 20 Einheiten unter der Map berührt. Dies wurde gewählt statt der ursprünglich im Issue beschriebenen Variante "sofort sterben bei Betreten", weil das Durchfallen ein realistischeres Abgrund-Verhalten darstellt.
Durchgeführte Änderungen:
1. Neuer Layer HoleSurface (Layer 6):
Ermöglicht die Trennung von physischer Kollision und Raycast-Erkennung. Die Physics Collision Matrix wurde so konfiguriert, dass Default ↔ HoleSurface nicht kollidiert. Dadurch fällt der Agent physisch durch, aber der Boden-Sensor-Raycast (ohne LayerMask) trifft den Collider trotzdem.
2. Hole-Prefab angepasst:

Layer: HoleSurface (Layer 6)
Scale: (1, 0.1, 1) — flach auf Bodenhöhe
Material: Hole_Mat (schwarz) — visuell als Abgrund erkennbar
BoxCollider: IsTrigger = false, Size (1, 1, 1), Center (0, 0, 0) — normaler Collider für Raycast-Erkennung

3. Neuer Tag KillZone (Tag 7):
Für die Kill-Box unter der Map.
4. MapGenerator.cs — neue Methode SpawnKillZone():
Erzeugt bei jeder Map-Generierung automatisch eine unsichtbare Trigger-Box (BoxCollider, IsTrigger = true, Tag KillZone) 20 Einheiten unter der Map. Die Box spannt die gesamte Map-Fläche auf. Wird in GenerateMap() nach SpawnRuntimeMarkersAndObstacles() aufgerufen.
5. LabyrinthAgent.cs — Boden-Sensor Fallback-Wert:
Der typeCode bei "kein Raycast-Treffer" wurde von -0.5f auf -1.5f geändert, damit das neuronale Netz Hole (-0.5f) von echtem Abgrund/Map-Ende (-1.5f) unterscheiden kann.
Offene Punkte für Folge-Issues:

Todeslogik (Issue 4.2): OnTriggerEnter im LabyrinthAgent muss auf Tag KillZone reagieren und EndEpisode() aufrufen (+ negativer Reward)
GroundCheck über Hole: Der Agent erkennt isGrounded = false über dem Hole, weil HoleSurface nicht im groundLayer enthalten ist. Das ist korrekt und gewollt.

## Issue 85: 4.1.4 MapGenerator um neue Hindernistypen erweitern

**Entscheidung aus Issue 4.0:** Tag-basierter Ansatz gewählt — keine dedizierten CellTypes für Lava/Hole.

**Status: Erledigt ✅**

- `CellType.cs` hat keine Lava/Hole-Einträge — korrekt für tag-basierten Ansatz
- `Lava_Placeholder.prefab` (Tag: `"Lava"`) und `Hole_Placeholder.prefab` (Tag: `"Hole"`) existieren unter `Assets/Prefabs/Map/Obstacles/`
- Beide Prefabs sind im `obstaclePrefabs`-Array des MapGenerator in `KI.unity`, `KI_Agenten_Unity.unity` und `MapGenerator_Test.unity` zugewiesen
- `LabyrinthAgent.cs` wertet `CompareTag("Lava")` und `CompareTag("Hole")` für die Observation aus (Zeilen 77–78)
- `MapGenerator.cs` enthält `SpawnKillZone()` für Hole-Sturz-Detektion
- `SampleScene.unity`: `obstaclePrefabs: []` — noch leer, niedrige Priorität

Kann geschlossen werden mit Kommentar: *Tag-basierter Ansatz gewählt. Lava_Placeholder und Hole_Placeholder mit korrekten Tags im obstaclePrefabs-Array konfiguriert. Keine CellType-Erweiterung notwendig.*

---

## Issue 86: 4.1.5 Hindernisse in die bestehenden Map-Layouts einbauen

**Status: Größtenteils erledigt, ein Akzeptanzkriterium nicht strikt erfüllt ⚠️**

Die 5 genutzten Layout-Assets (in `KI.unity` referenziert) enthalten alle `CellType.Obstacle`-Zellen:

| Layout | Größe | Obstacle-Zellen |
|--------|-------|----------------|
| Layout_01 | 25x30 | 10 |
| Layout_02 | 25x30 | 4 |
| Layout_03 | 25x30 | 12 |
| Layout_04 | 25x30 | 21 |
| Layout_05 | 18x30 | 30 |

**Erfüllt:**
- Alle 5 Maps haben walkable Zellen und Obstacle-Spawnpunkte ✅
- `obstaclePrefabs` enthält Lava + Hole in `KI.unity` ✅
- Lösbarkeit gesichert (BFS-Check im MapGenerator + `runtimeObstacleCount: 3`) ✅

**Offenes Problem:**
- `KI.unity` setzt `obstaclePlacementMode` nicht explizit → Default `RandomOnFloor`
- Obstacles werden zufällig auf beliebigen Floor-Zellen platziert, nicht gezielt auf den markierten Obstacle-Zellen
- `randomizeObstaclePrefab: 1` + nur 3 Obstacles → **kein garantiertes "mindestens 1 Lava UND 1 Hole" pro Episode** (statistisch ~75%)
- Strategische Platzierung ("Lava auf Hauptpfad, Holes als Sackgassen") nicht umgesetzt

**Lösungsoptionen:**
1. `obstaclePlacementMode = PredefinedSpawnPoints` in `KI.unity` setzen → nutzt die markierten Obstacle-Zellen gezielt
2. `runtimeObstacleCount` erhöhen (z.B. auf 6+) für höhere statistische Sicherheit beider Typen pro Episode
3. Anforderung als "statistisch ausreichend" akzeptieren

---

## Issue 87: Todeslogik

### Ausgangslage / Problem
Die ursprüngliche Issue-Beschreibung sah ein separates `DeathZone.cs`-Script auf Hindernis-Prefabs vor. Dieser Ansatz wurde verworfen, da er architektonisch inkonsistent gewesen wäre: Der Agent ist bereits die zentrale Instanz für Reward-Vergabe und Episodensteuerung. Logik auf einzelnen Prefabs hätte diese Verantwortung fragmentiert.

---

### Umgesetzte Architektur: Zwei Todesmechaniken, eine zentrale Stelle

Die gesamte Todeslogik liegt in `LabyrinthAgent.cs` → `OnTriggerEnter()`. Kein externes Script auf Prefabs.

```csharp
private void OnTriggerEnter(Collider other)
{
    if (other.CompareTag("Lava") || other.CompareTag("KillZone"))
    {
        AddReward(-1f);
        EndEpisode();
    }
}
```

---

### Mechanik 1: Lava — sofortiger Tod

- **Lava-Prefab**: `BoxCollider` mit `isTrigger: true`
- Agent betritt den Trigger → `OnTriggerEnter` schlägt an → Episode endet sofort

---

### Mechanik 2: Hole — physikalisches Fallen + verzögerter Tod

Zwei Komponenten arbeiten zusammen:

**Hole-Prefab** (`Hole_Placeholder.prefab`):
- `BoxCollider` mit `isTrigger: true`
- Trigger = keine physische Kollision → Agent fällt durch
- Trigger-Collider bleibt erhalten damit der **Boden-Sensor-Raycast** das Hole erkennt (`TypeCode = -0.5`)

**Floor-Collider-Deaktivierung** (`MapGenerator.cs` → `SpawnRuntimeMarkersAndObstacles()`):
- Der Floor-Tile existiert unter jedem Hole (MapGenerator spawnt ihn für jede begehbare Zelle)
- Beim Platzieren eines Hole-Obstacles: Suche per Weltposition in `spawnedObjects` nach dem Tile an dieser Stelle, deaktiviere dessen `BoxCollider`
- Suche ist positions-basiert (nicht namens-basiert), da der Tile-Name vom `CellType` abhängt (`Floor_x_y`, `Obstacle_x_y` etc.) und Holes auf verschiedenen CellTypes landen können

```csharp
if (obstacleInstance.CompareTag("Hole"))
{
    Vector3 holePos = CellToWorld(obstacleCell);
    foreach (GameObject spawnedObj in spawnedObjects)
    {
        if (spawnedObj == null) continue;
        if (Vector3.Distance(spawnedObj.transform.position, holePos) > 0.01f) continue;
        BoxCollider col = spawnedObj.GetComponent<BoxCollider>();
        if (col != null && !col.isTrigger)
        {
            col.enabled = false;
            break;
        }
    }
}
```

**KillZone** (`MapGenerator.cs` → `SpawnKillZone()`):
- Zur Laufzeit erzeugte unsichtbare Trigger-Box, 20 Einheiten unterhalb der Map
- Deckt die gesamte Map-Ausdehnung ab
- Agent fällt durch das Hole → trifft KillZone → `OnTriggerEnter` → Episode endet

---

### Entschieden gegen
- ❌ `DeathZone.cs` auf Prefabs: Logik-Fragmentierung, erhöhte Kopplung
- ❌ CellType-Erweiterung (Hole/Lava als eigene CellTypes): hätte das Obstacle-Randomisierungssystem außer Kraft gesetzt
- ❌ Physics-Layer-Matrix allein: hätte das Floor-Tile-Problem nicht gelöst

### Vollständig erhalten
- ✅ Zufällige Hole-Platzierung im `RandomOnFloor`-Modus
- ✅ Zufällige Hole-Platzierung an vordefinierten Stellen im `PredefinedSpawnPoints`-Modus
- ✅ Gemischte Obstacle-Arrays (Hole + Lava + andere im selben `obstaclePrefabs[]`)

Hinweis: Die `MapData_Training_*`-Assets werden in keiner aktiven Trainingsszene referenziert und sind nicht relevant für das Training.

---

## Issue 88: 4.2.2 Negativen Reward bei Tod vergeben

**Betroffene Datei:** `Assets/Scripts/Agent/LabyrinthAgent.cs`
**Keine Änderungen an:** `MapGenerator.cs`, Prefabs, Szenen, sonstigen Scripts

---

### Ausgangslage

`OnTriggerEnter` war bereits implementiert (Issue 87) und unterschied per `CompareTag` zwischen Lava- und Hole-Tod. Beide Todesfälle wurden jedoch identisch behandelt: hardcoded `AddReward(-1f)`, kein Logging, keine Inspector-Konfigurierbarkeit.

---

### Umgesetzte Änderungen

**1. Zwei serialisierte Penalty-Felder (statt einem hardcoded Wert)**

```csharp
[Header("Reward – Tod")]
[SerializeField] private float lavaDeathPenalty = -1f;
[SerializeField] private float holeDeathPenalty = -1f;
```

Beide Felder erscheinen im Inspector unter dem Header „Reward – Tod" und können dort unabhängig voneinander eingestellt werden — ohne Code-Änderung.

**2. `OnTriggerEnter` aufgeteilt in zwei separate Branches**

```csharp
private void OnTriggerEnter(Collider other)
{
    if (other.CompareTag("Lava"))
    {
        AddReward(lavaDeathPenalty);
        Debug.Log($"[Tod] Todesursache=Lava | Reward={lavaDeathPenalty}");
        EndEpisode();
    }
    else if (other.CompareTag("KillZone"))
    {
        AddReward(holeDeathPenalty);
        Debug.Log($"[Tod] Todesursache=Hole | Reward={holeDeathPenalty}");
        EndEpisode();
    }
}
```

Vorher war es ein gemeinsames `if (... || ...)` mit gemeinsamem `AddReward(-1f)`. Jetzt hat jeder Todesfall seinen eigenen Reward-Wert und seinen eigenen Log-Eintrag.

---

### Getroffene Entscheidungen

**Entscheidung 1: Zwei separate Felder statt eines gemeinsamen `deathPenalty`**

Das Issue forderte, Lava- und Hole-Tod „mindestens vorzubereiten" für unterschiedliche Bestrafungen. Ein einzelnes `deathPenalty`-Feld hätte die Unterscheidbarkeit wieder aufgehoben. Zwei Felder kosten keine zusätzliche Komplexität und lassen die Tür für Experimente offen (z.B. Lava = -1.0, Hole = -0.5, falls der Agent Holes als weniger gefährlich einschätzen soll).

**Entscheidung 2: `AddReward()` statt `SetReward()`**

`AddReward()` akkumuliert den Reward für den aktuellen Step. Da `EndEpisode()` unmittelbar danach aufgerufen wird, ist das Verhalten identisch zu `SetReward()`. `AddReward()` ist die ML-Agents-Konvention für schrittweise Rewards und bleibt konsistent mit dem restlichen Agent-Code.

**Entscheidung 3: Kein separates `DeathZone.cs` (unverändert aus Issue 87)**

Die gesamte Todeslogik bleibt in `LabyrinthAgent.cs`. Das entspricht der in Issue 87 getroffenen Architekturentscheidung: Der Agent ist die zentrale Instanz für Reward und Episodensteuerung — keine Fragmentierung auf Prefab-Scripts.

---

### Akzeptanzkriterien

| Kriterium | Status |
|---|---|
| Negativer Reward wird bei Tod vergeben | Erfüllt |
| Reward-Wert ist im Inspector konfigurierbar | Erfüllt — zwei `[SerializeField]`-Felder |
| Debug-Log zeigt Todesgrund und Reward-Wert | Erfüllt |
| Lava-Tod und Hole-Tod sind als separate Todesursachen unterscheidbar | Erfüllt |

---

## Issue 107: Third-Person-Kamera & Agenten-Rotation

**Betroffene Dateien:**
- `Assets/Scripts/Agent/LabyrinthAgent.cs` — Agenten-Rotation ergänzt
- `Assets/Scripts/Camera/ThirdPersonCamera.cs` — neu erstellt
- Szene `MapGenerator_Test.unity` — Kamera-Komponente manuell zugewiesen

**Keine Änderungen an:** `MapGenerator.cs`, Prefabs, `CellType.cs`, Action-Space, sonstigen Scripts

---

### Ausgangslage

Die Kamera war statisch und wurde von `MapGenerator.cs` einmalig beim Kartenaufbau positioniert (`FrameCameraToCurrentMap()`), um die gesamte Map zu rahmen. Der Agent bewegte sich world-aligned (W = Welt-Z+, A = Welt-X- usw.) und rotierte nie — `transform.localRotation` blieb dauerhaft `Quaternion.identity`. Es existierte kein Camera-Follow-System.

Zusätzlich wurden die Labyrinthwände in der Szene `MapGenerator_Test.unity` auf Scale Y = 4.5 erhöht, damit der Agent nicht mehr über die Wände springen kann.

---

### Umgesetzte Änderungen

**1. Agenten-Rotation in `LabyrinthAgent.cs`**

In `OnActionReceived()` wird der Agent nach jedem Bewegungsschritt per `rb.MoveRotation()` in die Bewegungsrichtung gedreht:

```csharp
if (direction != Vector3.zero)
{
    rb.MovePosition(transform.position + direction * moveSpeed * Time.fixedDeltaTime);
    rb.MoveRotation(Quaternion.LookRotation(direction));  // NEU
}
```

`rb.MoveRotation()` wird statt `transform.rotation =` verwendet, da die Rotation über den Rigidbody gesteuert wird und so keine Physics-Artefakte entstehen. Die Rotation ist ein Snap (keine Interpolation), da eine geglättete Rotation die Sensor-Semantik verzögern würde.

**Nebeneffekt auf Boden-Sensoren:** Die Raycast-Offsets `transform.forward * 1f` und `transform.forward * 2f` in `CollectObservations()` zeigen nun in die tatsächliche Bewegungsrichtung des Agenten statt immer in Welt-Z+. Das ist inhaltlich korrekt und verbessert die Qualität der Observations für das ML-Training.

**2. Neues Script `ThirdPersonCamera.cs`**

Neues MonoBehaviour unter `Assets/Scripts/Camera/ThirdPersonCamera.cs`:

```csharp
public class ThirdPersonCamera : MonoBehaviour
{
    public Transform target;
    public float heightOffset = 3f;
    public float distanceOffset = 5f;
    public float positionSmoothTime = 0.1f;
    public float rotationSmoothSpeed = 5f;
}
```

Kernlogik in `LateUpdate()`:
- **Position:** Zielposition = `target.position + target.rotation * (0, heightOffset, -distanceOffset)` → Kamera hinter und über dem Agenten in dessen lokalem Raum. Geglättet per `Vector3.SmoothDamp`.
- **Rotation:** Kamera schaut auf `target.position + Vector3.up * 1f` (leicht über Agent-Mitte). Geglättet per `Quaternion.Slerp` mit `rotationSmoothSpeed`.
- `LateUpdate()` statt `Update()`, damit die Kamera erst nach Agentbewegung (FixedUpdate) aktualisiert wird — kein Frame-Lag zwischen Agentposition und Kameraposition.

**3. Manueller Unity-Schritt (Szene `MapGenerator_Test.unity`)**

- `ThirdPersonCamera`-Script auf das `Main Camera`-GameObject gezogen
- `target`-Feld im Inspector auf den Agent-Transform gesetzt

---

### Steuerung im Heuristic-Modus

Die Tastenbelegung bleibt unverändert (W/A/S/D + Space). Der Agent dreht sich automatisch in die zuletzt gedrückte Bewegungsrichtung — keine separate Rotationstaste nötig. Die Kamera schwenkt daraufhin hinter den Agenten in seine neue Blickrichtung.

---

### Getroffene Entscheidungen

**Entscheidung 1: Snap-Rotation statt Smooth-Rotation am Agenten**
Eine interpolierte Rotation am Agenten hätte die Sensor-Offsets (`transform.forward`) während der Drehung in Zwischenzustände versetzt, die für den Beobachtungsraum irreführend wären. Snap-Rotation hält Sensor- und Bewegungsrichtung synchron.

**Entscheidung 2: Rotation über `rb.MoveRotation()` statt `transform.rotation`**
Direktes Setzen von `transform.rotation` bei einem Rigidbody-Objekt kann Physics-Inkonsistenzen erzeugen. `rb.MoveRotation()` ist die korrekte Rigidbody-API für kinematisch gesteuerte Rotation.

**Entscheidung 3: Kein Eingriff in `MapGenerator.FrameCameraToCurrentMap()`**
`ThirdPersonCamera.LateUpdate()` überschreibt jede Frame die Kameraposition. Die einmalige Map-Framing-Logik im MapGenerator ist damit funktionslos, solange `target` gesetzt ist — ein Eingriff wäre unnötige Kopplung.

**Entscheidung 4: Keine Änderung am Action-Space**
Die Rotation ist eine rein visuelle/sensorische Konsequenz der bestehenden Bewegungsaktionen. Der Action-Space (5 Bewegungsoptionen, 2 Sprungoptionen) bleibt unverändert — bestehende Trainingsläufe sind strukturell kompatibel.

---

### Akzeptanzkriterien

| Kriterium | Status |
|---|---|
| Kamera folgt Agent-Position (inkl. Sprung) | Erfüllt — `SmoothDamp` in `LateUpdate()` |
| Kamera dreht sich mit Agenten-Y-Rotation | Erfüllt — Offset in lokalem Agenten-Raum |
| Agent dreht sich visuell in Bewegungsrichtung | Erfüllt — `rb.MoveRotation(Quaternion.LookRotation(direction))` |
| Boden-Sensoren zeigen in Bewegungsrichtung | Erfüllt — Nebeneffekt der Agenten-Rotation |
| Steuerung im Heuristic-Modus unverändert | Erfüllt — keine neue Taste, keine Action-Space-Änderung |
| Agent kann Wände nicht mehr überspringen | Erfüllt — Wandhöhe in `MapGenerator_Test.unity` auf Scale Y = 4.5 erhöht |

---

## Issue 105– SpawnPlacementMode

**Datum:** 12.04.2026
**Betroffene Datei:** `Assets/Scripts/Map/MapGenerator.cs`

### Ausgangsproblem

Beim Testen wurde festgestellt, dass der Spawnpunkt des Agenten bisher immer zufällig aus allen begehbaren Zellen gewählt wurde — unabhängig davon, ob im Layout eine explizit markierte `CellType.SpawnPoint`-Zelle vorhanden war. Die Spawn-Platzierung war damit nicht klar steuerbar.

### Umgesetzte Änderungen

**1. Neues Enum `SpawnPlacementMode`** (oberhalb der Klasse, analog zu `ObstaclePlacementMode`)

```csharp
public enum SpawnPlacementMode
{
    RandomSpawnPoints,
    PredefinedSpawnPoints
}
```

**2. Neues Inspector-Feld** in `[Header("Spawn Settings")]`:

```csharp
public SpawnPlacementMode spawnPlacementMode = SpawnPlacementMode.RandomSpawnPoints;
```

**3. Erweiterung von `SelectRandomSpawnCell()`**

Die Methode verzweigt jetzt auf Basis von `spawnPlacementMode`:

- **`RandomSpawnPoints`**: Bisheriges Verhalten — alle begehbaren Zellen sind Kandidaten. `CellType.Obstacle`-Zellen werden ausgeschlossen, wenn `obstaclePlacementMode == PredefinedSpawnPoints`, da diese für Hindernisse reserviert sind.
- **`PredefinedSpawnPoints`**: Nur `CellType.SpawnPoint`-Zellen aus dem Layout werden als Kandidaten zugelassen. Enthält das Layout keine solchen Zellen, wird eine `LogWarning` ausgegeben und auf das `RandomSpawnPoints`-Verhalten zurückgefallen.

### Getroffene Entscheidungen

**Entscheidung 1: Eigenes Enum statt Erweiterung von `ObstaclePlacementMode`**
Spawn- und Hindernis-Platzierung sind unabhängige Konfigurationsachsen. Ein gemeinsames Enum hätte ungültige Kombinationen erzwungen und die Lesbarkeit im Inspector verschlechtert.

**Entscheidung 2: Fallback auf Random statt hartem Fehler bei fehlendem SpawnPoint**
Wenn `PredefinedSpawnPoints` gewählt ist, aber das Layout keine `CellType.SpawnPoint`-Zelle enthält, bricht die Episode nicht ab — stattdessen wird ein Warning geloggt und auf zufällige Zellen zurückgefallen. Das verhindert unkontrolliertes Verhalten bei falsch konfigurierten Layouts.

**Entscheidung 3: `SelectRandomGoalCell()` und Obstacle-Logik unverändert**
Die Goal- und Hindernis-Platzierung sind weiterhin ausschließlich an `obstaclePlacementMode` gebunden. Keine Kopplung an den neuen `spawnPlacementMode`.

**Entscheidung 4: Nur ein Spawnpunkt zur Laufzeit**
Der Code platziert `spawnPointPrefab` genau einmal (an `currentSpawnCell`). Bei `PredefinedSpawnPoints` mit genau einer markierten Zelle im Layout ergibt sich daraus automatisch ein deterministischer, einziger Spawn-Marker — keine zusätzliche Absicherung im Code nötig.

### Akzeptanzkriterien

| Kriterium | Status |
|---|---|
| `SpawnPlacementMode` im Inspector auswählbar | Erfüllt — serialisiertes Feld unter „Spawn Settings" |
| `RandomSpawnPoints` reproduziert bisheriges Verhalten | Erfüllt — identische Logik wie zuvor |
| `PredefinedSpawnPoints` nutzt nur markierte SpawnPoint-Zellen | Erfüllt — explizite CellType-Prüfung |
| Layout ohne SpawnPoint-Zellen bricht nicht ab | Erfüllt — Warning + Fallback auf Random |
| Goal- und Obstacle-Logik unverändert | Erfüllt — keine Änderungen an `SelectRandomGoalCell()` oder `GetObstacleCandidateCells()` |
| Keine Änderungen an Prefabs oder anderen Scripts | Erfüllt |

---

## Issue 93: 5.1.2 Reward-Werte für Tod konsolidieren und konfigurierbar machen

**Datum:** 13.04.2026
**Betroffene Datei:** `Assets/Scripts/Agent/LabyrinthAgent.cs`
**Keine Änderungen an:** `MapGenerator.cs`, Prefabs, sonstigen Scripts

---

### Ausgangslage

Die Reward-Vergabe bei Tod war bereits in Issue 88 zentral im `LabyrinthAgent` implementiert (zwei `[SerializeField]`-Felder `lavaDeathPenalty` und `holeDeathPenalty`, getrennte `OnTriggerEnter`-Branches mit Debug-Logs). Dieses Issue stellte fest, dass die Implementierung die Akzeptanzkriterien vollständig erfüllt — fehlend war ausschließlich die Dokumentation der Architekturentscheidung im Code.

---

### Architekturentscheidung: Zentral am Agent (nicht in DeathZone.cs)

Ein separates `DeathZone.cs`-Script auf Hindernis-Prefabs existiert nicht und wurde bewusst nicht eingeführt. Stattdessen gilt:

- **Alle Reward-Werte** liegen als serialisierte Felder am `LabyrinthAgent` — im Inspector konfigurierbar, ohne Code-Änderung anpassbar
- **Trigger-Objekte** (Lava-Prefab, KillZone-Box) lösen nur `OnTriggerEnter` aus — sie vergeben selbst keine Rewards
- **Der Agent** ist die einzige Instanz, die `AddReward()` und `EndEpisode()` aufruft

**Begründung:** ML-Agents-Paradigma sieht vor, dass ausschließlich die Agent-Klasse Rewards und Episode-Steuerung übernimmt. Logik auf einzelnen Prefab-Scripts würde diese Verantwortung fragmentieren und die Konfigurierbarkeit erschweren — insbesondere im Hinblick auf Milestone 5 (Step-Penalty, Goal-Reward).

---

### Umgesetzte Änderung

Der Kommentar vor `OnTriggerEnter` in `LabyrinthAgent.cs` wurde zu einer vollständigen Architekturdokumentation ausgebaut:

```csharp
// === Architekturentscheidung: Zentrale Reward-Vergabe am Agent ===
// Alle Reward-Werte bei Tod sind als serialisierte Felder am LabyrinthAgent definiert
// (lavaDeathPenalty, holeDeathPenalty). Externe Trigger-Objekte (Lava, KillZone) rufen
// keine Rewards direkt auf, sondern lösen nur OnTriggerEnter aus. Der Agent vergibt
// den Reward intern. Das entspricht dem ML-Agents-Paradigma (nur die Agent-Klasse
// darf AddReward/EndEpisode aufrufen) und erleichtert die Konfiguration in Milestone 5.
//
// Todesauslöser:
// 1. Lava: IsTrigger=true am Lava-Prefab → Agent läuft in Trigger → lavaDeathPenalty
// 2. Hole: Agent fällt durch HoleSurface-Layer → trifft KillZone-Box → holeDeathPenalty
//    (Lava und Hole haben bewusst separate Felder für spätere Differenzierung)
```

---

### Akzeptanzkriterien

| Kriterium | Status |
|---|---|
| Reward-Vergabe bei Tod ist konsistent und zentral konfigurierbar | Erfüllt — zwei `[SerializeField]`-Felder am Agent (seit Issue 88) |
| Lava-Tod und Hole-Tod sind als separate Todesursachen unterscheidbar | Erfüllt — getrennte Branches + separate Penalty-Felder |
| Architekturentscheidung (zentral vs. verteilt) ist dokumentiert | Erfüllt — Kommentar in `LabyrinthAgent.cs` vor `OnTriggerEnter` |

---

## Issue 94: 5.1.3 Zeitlimit (MaxStep) & Step-Penalty implementieren

### Kontext

ML-Agents bietet eine eingebaute `MaxStep`-Property auf der `Agent`-Klasse. Wird sie gesetzt, ruft das Framework automatisch `EndEpisode()` auf, sobald der Agent die entsprechende Anzahl an Decisions erreicht hat. Dabei gibt es **keinen automatischen zusätzlichen Reward** — die Episode endet mit dem bis dahin akkumulierten Reward.

### MaxStep — Begründung des Werts

**Überschlagsrechnung (größte Map: 25×30 Zellen, Zellgröße 1.0 m):**

| Parameter | Wert |
|---|---|
| `moveSpeed` | 3 m/s |
| Unity FixedUpdate | 50 Hz (0.02 s/Step) |
| ML-Agents Decision Period | 5 (Standard) |
| Zeit pro Zelle | 1 m / 3 m/s = 0,33 s |
| Physics-Steps pro Zelle | 0,33 s / 0,02 s = 16,7 |
| Decisions pro Zelle | 16,7 / 5 ≈ 3,3 |
| Längster realistischer Pfad | ~150 Zellen (Labyrinth, 25×30) |
| Optimale Decisions minimal | 150 × 3,3 ≈ 500 |
| **MaxStep (5× Puffer)** | **2500** |

Der Faktor 5 gibt dem Agenten ausreichend Spielraum, auch bei suboptimalen Trajektorien während des Trainings die Map zu lösen, ohne bei gutem Verhalten in Timeout zu laufen.

**→ MaxStep = 2500 wird im Unity Inspector am Agent-Prefab gesetzt.**

### Timeout-Verhalten — Architekturentscheidung

**Entscheidung: Option A — kein expliziter Timeout-Penalty.**

Begründung:
- Der Step-Penalty akkumuliert über die gesamte Episodenlänge: Bei `MaxStep = 2500` und `stepPenalty = -0.001f` ergibt sich ein kumulativer Timeout-Malus von `2500 × 0.001 = -2.5`. Timeout ist damit bereits indirekt bestraft — ohne einen separaten Reward-Aufruf.
- Ein expliziter Timeout-Penalty (`-1.0f`) wäre redundant und könnte das Lernsignal verzerren, da er unabhängig vom bisherigen Episodenverlauf wirkt.
- ML-Agents' automatisches `EndEpisode()` bei MaxStep ist ausreichend als Terminierungssignal.

### Step-Penalty — Implementierung

In `OnActionReceived()` wird zu Beginn jedes Steps ein kleiner negativer Reward addiert. Zusätzlich werden Step-Count und Cumulative Reward in privaten Feldern gesichert, da ML-Agents beide Werte zurücksetzt **bevor** `OnEpisodeBegin()` aufgerufen wird:

```csharp
[Header("Reward – Zeit")]
[SerializeField] private float stepPenalty = -0.001f;

private int lastEpisodeStepCount = 0;
private float lastEpisodeCumulativeReward = 0f;

public override void OnEpisodeBegin()
{
    Debug.Log($"[Episode] Neue Episode. Steps letzte Episode: {lastEpisodeStepCount} | Letzter Cumulative Reward: {lastEpisodeCumulativeReward:F3}");
    // ...
}

public override void OnActionReceived(ActionBuffers actions)
{
    AddReward(stepPenalty);
    lastEpisodeStepCount = StepCount;
    lastEpisodeCumulativeReward = GetCumulativeReward();
    // ... restliche Bewegungslogik
}
```

**Begründung der Größenordnung (`-0.001f`):**

| Szenario | Kumulativer Step-Penalty |
|---|---|
| Optimaler Pfad (~500 Steps) | -0,5 |
| Timeout (2500 Steps) | -2,5 |
| Lava/Hole-Tod | -1,0 (einmalig) |

- Der Step-Penalty bei 500 Steps (`-0.5`) ist spürbar kleiner als ein Todesfall (`-1.0`), sodass der Agent keinen Anreiz hat, Lava/Holes als Abkürzung zu riskieren.
- Bei Timeout (`-2.5`) übersteigt der akkumulierte Penalty einen Einzeltod — Herumstehen wird stärker bestraft als Sterben, aber die Lava-Grenze bleibt trotzdem unattraktiv.
- Das Feld ist im Inspector konfigurierbar (`[SerializeField]`), sodass der Wert ohne Code-Änderung für Experimente angepasst werden kann.

**Hinweis: `StepCount` und `GetCumulativeReward()` in `OnEpisodeBegin`**

ML-Agents setzt beide Werte zurück, bevor `OnEpisodeBegin()` aufgerufen wird — ein direktes Auslesen dort liefert immer `0`. Die privaten Felder `lastEpisodeStepCount` und `lastEpisodeCumulativeReward` sichern die Werte am Ende jedes `OnActionReceived`-Aufrufs und stehen damit in der nächsten `OnEpisodeBegin` korrekt zur Verfügung.

### Test — Ergebnis

Getestet im Heuristic-Modus mit `MaxStep = 100` (Testwert), Agent stehend:

```
[Episode] Neue Episode. Steps letzte Episode: 100 | Letzter Cumulative Reward: -0,100
```

- Steps = 100 → MaxStep greift korrekt, Episode endet automatisch
- Reward = -0.100 → 100 × (-0.001) = erwarteter akkumulierter Step-Penalty ✅

MaxStep danach auf den begründeten Produktionswert **2500** zurückgesetzt.

### Akzeptanzkriterien

| Kriterium | Status |
|---|---|
| MaxStep ist gesetzt und begründet dokumentiert | ✅ Wert 2500, Überschlagsrechnung oben |
| Verhalten bei Timeout ist definiert und dokumentiert | ✅ Option A (kein expliziter Penalty), Step-Penalty übernimmt indirekte Bestrafung |
| Step-Penalty ist implementiert und konfigurierbar | ✅ `[SerializeField] private float stepPenalty = -0.001f` in `LabyrinthAgent.cs` |
| Step-Penalty ist in seiner Größenordnung begründet | ✅ Tabelle oben |
| Test bestanden: Episode endet bei MaxStep | ✅ Verifiziert im Heuristic-Modus |

