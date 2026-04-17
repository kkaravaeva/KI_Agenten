# Prozedurale Map-Generierung — Technische Dokumentation

**Stand:** 17.04.2026
**Betroffene Dateien:**
- `Assets/Scripts/Map/RoomCorridorGraph.cs`
- `Assets/Scripts/Map/ProceduralLayoutGenerator.cs`
- `Assets/Scripts/Map/ObstacleClusterPlacer.cs`
- `Assets/Scripts/Map/PlatformPlacer.cs`
- `Assets/Scripts/Map/SemanticPathfinder.cs`
- `Assets/Editor/MapGeneratorEditor.cs`

---

## Übersicht

Die prozedurale Generierung erzeugt vollständige `MapData`-Assets (ScriptableObjects) ohne manuellen Designer-Input. Jedes generierte Layout enthält Räume, Gänge, Hindernisse (Lava/Hole), optionale Plattformen, einen Spawnpunkt und ein Ziel.

**Generierungspipeline (in Reihenfolge):**

```
BuildTopology  →  CreateGrid  →  FillWithEmpty  →  PlaceRooms  →  PlaceCorridors
→  PlaceWalls  →  PlaceSpawnAndGoal  →  CoverageCheck  →  PlaceClusters
→  PlacePlatforms  →  PathValidation
```

---

## 1. Grid-Größe und Pufferzone

**Datei:** `RoomCorridorGraph.cs`

Jedes Layout hat eine variable Grid-Größe:

```
GridWidth  = rng.Next(25, 38) + 2 * BORDER  → 29–41 Tiles breit
GridHeight = rng.Next(30, 46) + 2 * BORDER  → 34–50 Tiles hoch
```

`BORDER = 2` ist ein fester 2-Tile-Puffer an allen Rändern. Sämtliche Räume, Gänge und Obstacles werden innerhalb von `[BORDER, Grid-BORDER)` platziert — die äußersten 2 Tiles jeder Seite bleiben immer leer. Das verhindert visuelles Clipping und gibt der Wandgenerierung Spielraum.

---

## 2. Topologie-Generierung (`RoomCorridorGraph`)

### 2.1 Datenmodell

| Klasse | Felder | Bedeutung |
|---|---|---|
| `RoomNode` | `center`, `size`, `type`, `connections` | Rechteckiger Raum im Grid |
| `CorridorEdge` | `roomA`, `roomB`, `start`, `end`, `direction`, `leadsToGoal`, `isLoop`, `isTerminal`, `obstacle` | Verbindung zwischen zwei Räumen oder Terminal |
| `ObstacleCluster` | `origin`, `depth`, `width`, `type`, `hasPlatform`, `platformCell`, `gangDir` | Zusammenhängende Obstacle-Fläche in einem Korridor |

`RoomType`: `Start`, `Goal`, `DeadEnd`
`Direction`: `North`, `South`, `East`, `West`

### 2.2 Ablauf `BuildTopology(seed)`

1. **Raumgrößen zufällig festlegen:**
   - StartRoom: 3–5 × 3–5 Tiles
   - GoalRoom: 3 × 3 Tiles (fest)
   - DeadEnd-Räume: 1–3 × 1–3 Tiles

2. **StartRoom platzieren:** Zufällig im Grid, mindestens `BORDER + halbgröße + 2` vom Rand entfernt.

3. **Ebene-1: 6–9 Korridore vom StartRoom** in zufälliger Richtungsreihenfolge. Längen werden durch `GetMaxCorridorLen()` nach oben begrenzt, sodass der Zielraum immer innerhalb der Pufferzone landet. Mindestlänge: 4 Tiles.

4. **Terminal-Korridore vom StartRoom (2–4):** Gänge ohne Zielraum (`isTerminal=true`), enden mit einem Hole-Cluster.

5. **Rekursive Verzweigung `BranchFrom()`:**
   - Tiefe 1 → 2–4 Äste
   - Tiefe 2 → 1–3 Äste
   - Tiefe 3+ → 1–2 Äste
   - Max. Tiefe: 5, Max. Räume gesamt: 28
   - Pro Ebene 1–2 auch Terminal-Korridore (0–2)

6. **GoalRoom bestimmen:** Raum mit größtem Manhattan-Abstand vom StartRoom (25 % Chance auf zweit-weitesten). Alle anderen Räume werden `DeadEnd`.

7. **Mindestanzahl-Check:** `deadEndRooms + terminalCount >= 2`, sonst wird die Topologie verworfen.

8. **Optionaler Loop (30 %):** Ein orthogonaler Verbindungskorridor (`isLoop=true`) zwischen einem DeadEnd und dem StartRoom.

### 2.3 Längen-Berechnung

`GetMaxCorridorLen(corrStart, dir, destSize)` berechnet die maximal erlaubte Korridorlänge sodass der Zielraum sicher innerhalb der Pufferzone liegt:

```
North: (GridHeight - BORDER) - 2*hy - 2 - corrStart.y
South: corrStart.y - BORDER - 2*hy - 2
East:  (GridWidth  - BORDER) - 2*hx - 2 - corrStart.x
West:  corrStart.x - BORDER - 2*hx - 2
```

`GetMaxTerminalLen()` funktioniert analog ohne Zielraum-Margin.

---

## 3. Grid-Aufbau (`ProceduralLayoutGenerator`)

Nach erfolgreicher Topologie wird das Grid schrittweise befüllt:

| Schritt | Methode | Beschreibung |
|---|---|---|
| 1 | `CreateGrid()` | Leeres `MapData`-ScriptableObject mit Topologie-Dimensionen |
| 2 | `FillWithEmpty()` | Alle Tiles auf `CellType.Empty` |
| 3 | `PlaceRooms()` | Alle `RoomNode`-Flächen auf `CellType.Floor` |
| 4 | `PlaceCorridors()` | 2-Tile-breite gerade Gänge als Floor |
| 5 | `PlaceWalls()` | Alle `Empty`-Tiles die an einem Floor-Tile angrenzen (inkl. diagonal) werden zu `Wall` |
| 6 | `PlaceSpawnAndGoal()` | SpawnCell → `CellType.SpawnPoint`, GoalCell → `CellType.Goal` |

**Korridor-Breite:** Immer 2 Tiles. Der zweite Tile liegt senkrecht zur Gangrichtung (+X für N/S-Gänge, +Y für E/W-Gänge).

**Wandgenerierung:** Zweistufig — zuerst alle Kandidaten in einem Bool-Array sammeln, dann setzen. Verhindert Kaskadeneffekte (Wände die selbst wieder als Floor-Nachbar gezählt werden könnten).

### 3.1 Coverage-Check

Nach dem Wandsetzen wird geprüft, ob das Layout ausreichend befüllt ist:

```csharp
// Nur innerer Bereich [BORDER, Grid-BORDER) wird gezählt
// Threshold: walkable >= total * 0.15f
// Walkable = alles außer Empty und Wall
```

Der BORDER-Bereich ist intentionell leer und würde die Ratio verfälschen — daher wird nur der Innenbereich ausgewertet. Bei unter 15% wird ein neuer Versuch gestartet.

---

## 4. Obstacle-Platzierung (`ObstacleClusterPlacer`)

### 4.1 Regelwerk pro Korridor-Typ

| Korridor-Typ | Obstacle-Regel |
|---|---|
| `isTerminal = true` | Immer Hole, Tiefe 2 (nahe am Terminal-Ende) |
| `leadsToGoal = true` | Immer genau 1 Lava-Cluster, Tiefe 1/2/3 (zufällig gewichtet: 40%/40%/20%) |
| `isLoop = true` | 50 % Lava Tiefe 1 |
| `roomB.type == DeadEnd` | 25 % kein Obstacle · 12 % Hole · 63 % Lava (Tiefe 1–2) |

**Wichtig:** `leadsToGoal` setzt immer genau 1 Cluster. Frühere Implementierung mit optionalen 2 Clustern wurde entfernt, da nur der letzte Cluster in `corridor.obstacle` gespeichert wurde und der erste vom Pathfinder nicht erkannt werden konnte.

### 4.2 Origin-Berechnung

| Methode | Verwendung | Beschreibung |
|---|---|---|
| `CenteredOrigin()` | Loop, DeadEnd-Lava | Mitte des Korridors ± zufälliger Offset von ±1 |
| `DeadEndOrigin()` | Terminal/Hole | Letzten `depth` Tiles des Korridors (nahe am Ende) |
| `SlottedOrigin()` | (intern, für Multi-Slot) | Korridor in N gleichgroße Abschnitte aufgeteilt |

### 4.3 Cluster-Tile-Platzierung

```
isNS-Gang: x = origin.x + w,  y = origin.y + d   (d = depth-Iteration, w = width-Iteration)
EW-Gang:   x = origin.x + d,  y = origin.y + w
```

---

## 5. Plattform-Platzierung (`PlatformPlacer`)

Für jeden Lava-Cluster mit `hasPlatform = true` wird der mittlere Tile des Clusters auf `CellType.Platform` gesetzt. In `MapData.cellHeightOffsets` wird für diesen Tile ein Höhen-Offset von `0.75f` hinterlegt. Beim Instanziieren in `MapGenerator` wird das Plattform-Prefab um diesen Offset nach oben verschoben.

**Bedingung für `hasPlatform`:**
- Goal-Korridor: wenn `depth > 1`
- DeadEnd-Korridor: wenn `depth > 1`
- Loop-Korridor: nie (immer `depth == 1`)

---

## 6. Pfad-Validierung (`SemanticPathfinder`)

BFS von `spawnCell` nach `goalCell` mit semantischen Walkability-Regeln:

| CellType | Passierbar? | Bedingung |
|---|---|---|
| Floor, SpawnPoint, Goal, Platform, Obstacle | Ja | immer |
| Hole | Nein | nie |
| Lava | Ja | wenn `depth == 1` (überspringbar) |
| Lava | Ja | wenn `hasPlatform == true` (via Plattform) |
| Lava | Nein | wenn `depth > 1` und kein Platform |
| Wall, Empty | Nein | immer |

Bei einem Lava-Tile wird `FindClusterAt(pos, clusters)` aufgerufen — BFS-Lookup über alle registrierten Cluster. Wird kein Cluster gefunden (Konfigurationsfehler), wird das Tile als nicht passierbar behandelt.

Schlägt die Pfadvalidierung fehl, wird die Topologie verworfen und ein neuer Versuch gestartet (max. 10 Versuche).

---

## 7. Editor-Integration (`MapGeneratorEditor`)

Im Unity-Inspector des `MapGenerator`-GameObjects erscheint unter **"Prozedurale Layout-Generierung"**:

| Feld | Default | Beschreibung |
|---|---|---|
| Anzahl Layouts | 10 | 1–1000 per Slider |
| Ausgabe-Ordner | `Assets/Layouts/Procedural` | Zielordner für .asset-Dateien |
| Bestehende löschen | true | Löscht alle `Layout_P_*`-Assets vor der Generierung |
| mapLayouts[] befüllen | true | Weist das `mapLayouts`-Array nach der Generierung automatisch zu |

**Seed-Strategie:** `baseSeed = Random.Range(0, 999999)`, jedes Layout bekommt `baseSeed + i * 7` als Seed. Damit sind Layouts deterministisch reproduzierbar, aber untereinander unkorreliert.

**Fallback:** Im Batch-Modus wird `null` als Fallback übergeben. Schlägt die Generierung für ein Layout nach 10 Versuchen fehl, wird es übersprungen und `failed`-Zähler erhöht (kein Recycling bestehender Assets — verhindert den "asset already exists"-Fehler).

---

## 8. Mehrfach-Versuch-Strategie

`ProceduralLayoutGenerator.GenerateLayout()` versucht bis zu 10 Mal eine gültige Topologie zu generieren. Bei jedem Versuch wird `seed + attempt` als Seed verwendet.

Ein Versuch schlägt fehl wenn:
- `BuildTopology()` → `false` (Mindest-Äste nicht erreicht, Überlappungen usw.)
- `HasSufficientCoverage()` → `false` (< 15% des Innenbereichs walkable)
- `SemanticPathfinder.HasPath()` → `false` (kein Pfad von Spawn zu Goal)

---

## 9. Mögliche Erweiterungen / ToDos

- **Map-Komplexität konfigurierbar machen:** Derzeit sind `MAX_BRANCH_DEPTH`, `MAX_TOTAL_ROOMS`, Korridor-Längen-Bereiche und Coverage-Threshold als Konstanten fest codiert. Diese als serialisierte Parameter in den `MapGeneratorEditor` zu übernehmen würde Presets für leichte, mittlere und schwere Maps ermöglichen.

- **Goal/Spawn kann von Obstacle überschrieben werden:** `ObstacleClusterPlacer` prüft nicht, ob ein Obstacle-Tile auf dem Spawn- oder Goal-Tile landet. In der Praxis greift als Fallback der `useCenterFallback`-Spawn in `MapGenerator`, aber das sollte sauber behoben werden. Lösung: In `PlaceCluster()` einen Bounds-Check gegen `graph.spawnCell` und `graph.goalCell` ergänzen und betroffene Tiles überspringen.

- **Korridor-Breite variabel:** Derzeit immer 2 Tiles. Variante mit 1 oder 3 Tiles als Korridor-Eigenschaft (`CorridorEdge.width`) ist architektonisch vorgedacht, aber nicht umgesetzt.

- **Mehrere Cluster pro Korridor:** `CorridorEdge.obstacle` ist ein einzelner Cluster. Für sehr lange Gänge wäre `List<ObstacleCluster>` pro Edge sinnvoll. Wurde bewusst aus Komplexitätsgründen zurückgestellt (erfordert Anpassungen in `GetAllClusters()` und `SemanticPathfinder`).

- **Cluster-Typ-Validierung im Editor:** Nach der Generierung kann im Editor kein visueller Preview der Cluster gerendert werden. Eine Gizmo-Darstellung in `MapDataEditor.cs` (farbige Overlay-Rechtecke für Lava/Hole-Cluster) wäre hilfreich.
