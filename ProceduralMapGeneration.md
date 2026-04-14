# Procedural Map Generation – Implementierungsmöglichkeiten

## Vorhandene Grundlage

- **BFS-Pfadvalidierung** (`HasWalkablePath`) stellt sicher, dass Spawn → Goal erreichbar ist
- Hindernisse werden nur platziert, wenn der Pfad erhalten bleibt
- `MapData` (ScriptableObject) enthält das Grid als `CellType[]`-Array — kann auch zur Laufzeit befüllt werden

---

## Algorithmen

### 1. Recursive Backtracking (Maze)
Erzeugt Korridore durch das Grid per Tiefensuche. Garantiert von Natur aus Lösbarkeit. Einfach zu implementieren, ergibt labyrinthhafte Maps.

### 2. Cellular Automata
Zufälliges Rauschen → mehrfache Glättungs-Iterationen. Ergibt organische, höhlenartige Layouts. Erfordert abschließende BFS-Prüfung.

### 3. Room-Placement + Corridor Connection
Räume zufällig platzieren, per Minimum Spanning Tree verbinden. Klassischer Dungeon-Ansatz, gut für strukturierte Maps mit klaren Bereichen.

---

## Lösbarkeit sicherstellen

1. Floor-Cells generieren (per Algorithmus)
2. Spawn und Goal mit Mindestabstand platzieren (z. B. > 40 % der Map-Diagonale)
3. BFS prüfen → bei fehlendem Pfad neu generieren
4. Hindernisse platzieren (bestehende `PlaceRuntimeObstacles`-Logik wiederverwendbar)

---

## Integration

Neuer `MapSelectionMode.Procedural` im bestehenden `MapGenerator`. Statt ein `MapData`-Asset zu laden, wird ein leeres `MapData`-Objekt zur Laufzeit erstellt und per Generator befüllt. Kein Umbau der bestehenden Pipeline nötig.
