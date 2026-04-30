using UnityEngine;

/// <summary>
/// Hauptgenerator für prozedurale 25×30-Layouts.
/// Erzeugt Raum-Gang-Topologie, platziert Obstacles und validiert den Pfad.
/// Bei 10 fehlgeschlagenen Versuchen: Fallback auf das erste Asset aus fallbackLayouts.
/// </summary>
public static class ProceduralLayoutGenerator
{
    /// <summary>
    /// Generiert ein neues MapData-Layout prozedural.
    /// </summary>
    /// <param name="seed">Startwert für die Zufallsgenerierung.</param>
    /// <param name="difficulty">Schwierigkeitsgrad des generierten Layouts.</param>
    /// <param name="fallbackLayouts">Asset-Layouts als Fallback (kann null sein).</param>
    /// <returns>Fertiges MapData, nie null wenn fallbackLayouts nicht leer ist.</returns>
    public static MapData GenerateLayout(int seed,
                                         DifficultyLevel difficulty = DifficultyLevel.Hard,
                                         MapData[] fallbackLayouts = null)
    {
        if (difficulty == DifficultyLevel.Trivial)
            return GenerateTrivialLayout(seed);

        DifficultySettings settings = DifficultySettings.For(difficulty);

        for (int attempt = 0; attempt < 10; attempt++)
        {
            // Topologie zuerst – Grid-Größe kommt aus dem Graph
            RoomCorridorGraph graph = new RoomCorridorGraph();
            if (!graph.BuildTopology(seed + attempt, settings))
                continue;

            MapData grid = CreateGrid(graph.GridWidth, graph.GridHeight);

            FillWithEmpty(grid);
            PlaceRooms(grid, graph);
            PlaceCorridors(grid, graph);
            PlaceWalls(grid);
            PlaceSpawnAndGoal(grid, graph);

            // Coverage-Check: min. 50 % der Tiles müssen sinnvolle Wege sein
            if (!HasSufficientCoverage(grid))
            {
                Debug.LogWarning($"ProceduralLayoutGenerator: Versuch {attempt + 1} Coverage zu gering. Neuer Seed.");
                continue;
            }

            ObstacleClusterPlacer.PlaceClusters(grid, graph, settings);

            // Cluster-Liste nach PlaceClusters neu laden (obstacle-Felder jetzt befüllt)
            var clusters = graph.GetAllClusters();
            PlatformPlacer.PlacePlatforms(grid, clusters);

            if (SemanticPathfinder.HasPath(grid, graph.spawnCell, graph.goalCell, clusters))
                return grid;

            Debug.LogWarning($"ProceduralLayoutGenerator: Versuch {attempt + 1} ungültig (kein Pfad). Neuer Seed.");
        }

        Debug.LogError("ProceduralLayoutGenerator: Alle 10 Versuche fehlgeschlagen. Nutze Fallback-Layout.");

        if (fallbackLayouts != null && fallbackLayouts.Length > 0)
            return fallbackLayouts[0];

        return null;
    }

    // ── Triviales Open-Room Layout (Phase 0) ─────────────────────────────────

    /// <summary>
    /// Erzeugt einen 7×7 offenen Raum ohne Hindernisse. Spawn und Goal liegen
    /// in diagonalen Ecken; 4 Rotationen (seed % 4) verhindern Memorisierung.
    /// </summary>
    private static MapData GenerateTrivialLayout(int seed)
    {
        const int size = 7;
        MapData grid = CreateGrid(size, size);
        grid.name = $"Trivial_{seed % 4}";
        grid.noRuntimeObstacles = true;

        for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
                grid.SetCell(x, y, (x == 0 || x == size - 1 || y == 0 || y == size - 1)
                    ? CellType.Wall
                    : CellType.Floor);

        // 4 diagonale Rotationen: Agent kann keine feste Richtung memorisieren
        Vector2Int spawn, goal;
        switch (seed % 4)
        {
            case 0:  spawn = new Vector2Int(1, 1);          goal = new Vector2Int(size - 2, size - 2); break;
            case 1:  spawn = new Vector2Int(size - 2, 1);   goal = new Vector2Int(1, size - 2);        break;
            case 2:  spawn = new Vector2Int(1, size - 2);   goal = new Vector2Int(size - 2, 1);        break;
            default: spawn = new Vector2Int(size - 2, size - 2); goal = new Vector2Int(1, 1);          break;
        }

        grid.SetCell(spawn.x, spawn.y, CellType.SpawnPoint);
        grid.SetCell(goal.x,  goal.y,  CellType.Goal);

        return grid;
    }

    // ── Grid-Initialisierung ──────────────────────────────────────────────────

    private static MapData CreateGrid(int width, int height)
    {
        MapData grid = ScriptableObject.CreateInstance<MapData>();
        grid.width  = width;
        grid.height = height;
        grid.Init();
        return grid;
    }

    /// <summary>
    /// Prüft ob mindestens 30 % der Inhaltsfläche sinnvolle Wege sind.
    /// Zählt nur den Innenbereich (Border-Zone ausgeschlossen), da die
    /// 2-Tile-Pufferzone immer leer ist und die Ratio sonst verfälscht.
    /// </summary>
    private static bool HasSufficientCoverage(MapData grid)
    {
        const int border = 2; // Muss RoomCorridorGraph.BORDER entsprechen
        int walkable = 0;
        int total    = 0;
        for (int y = border; y < grid.height - border; y++)
            for (int x = border; x < grid.width - border; x++)
            {
                total++;
                CellType c = grid.GetCell(x, y);
                if (c != CellType.Empty && c != CellType.Wall)
                    walkable++;
            }
        return total > 0 && walkable >= total * 0.15f;
    }

    /// <summary>Füllt das gesamte Grid mit Empty-Tiles.</summary>
    private static void FillWithEmpty(MapData grid)
    {
        for (int y = 0; y < grid.height; y++)
            for (int x = 0; x < grid.width; x++)
                grid.SetCell(x, y, CellType.Empty);
    }

    /// <summary>
    /// Setzt Wall-Tiles an alle Empty-Zellen die direkt (inkl. Diagonal) an einem
    /// Floor-Tile angrenzen. Wände entstehen so nur als 1-Tile-Saum um Räume und Gänge.
    /// </summary>
    private static void PlaceWalls(MapData grid)
    {
        // Erst alle kandidaten sammeln, dann setzen – verhindert Kaskadeneffekte
        bool[,] shouldBeWall = new bool[grid.width, grid.height];

        for (int y = 0; y < grid.height; y++)
        {
            for (int x = 0; x < grid.width; x++)
            {
                if (grid.GetCell(x, y) != CellType.Empty) continue;

                for (int dy = -1; dy <= 1 && !shouldBeWall[x, y]; dy++)
                {
                    for (int dx = -1; dx <= 1 && !shouldBeWall[x, y]; dx++)
                    {
                        if (dx == 0 && dy == 0) continue;
                        int nx = x + dx, ny = y + dy;
                        if (nx < 0 || nx >= grid.width || ny < 0 || ny >= grid.height) continue;
                        if (IsFloorLike(grid.GetCell(nx, ny)))
                            shouldBeWall[x, y] = true;
                    }
                }
            }
        }

        for (int y = 0; y < grid.height; y++)
            for (int x = 0; x < grid.width; x++)
                if (shouldBeWall[x, y])
                    grid.SetCell(x, y, CellType.Wall);
    }

    private static bool IsFloorLike(CellType t) =>
        t == CellType.Floor || t == CellType.SpawnPoint || t == CellType.Goal;

    // ── Räume ─────────────────────────────────────────────────────────────────

    private static void PlaceRooms(MapData grid, RoomCorridorGraph graph)
    {
        foreach (RoomNode room in graph.rooms)
            PlaceRoom(grid, room);
    }

    /// <summary>
    /// Setzt alle inneren Tiles des Raums auf Floor.
    /// Verwendet size.x/2 als Halbbreite → konsistent mit CorridorExit.
    /// </summary>
    private static void PlaceRoom(MapData grid, RoomNode room)
    {
        int hx = room.size.x / 2;
        int hy = room.size.y / 2;

        for (int y = room.center.y - hy; y <= room.center.y + hy; y++)
        {
            for (int x = room.center.x - hx; x <= room.center.x + hx; x++)
            {
                if (x >= 0 && x < grid.width && y >= 0 && y < grid.height)
                    grid.SetCell(x, y, CellType.Floor);
            }
        }
    }

    // ── Korridore ─────────────────────────────────────────────────────────────

    private static void PlaceCorridors(MapData grid, RoomCorridorGraph graph)
    {
        foreach (CorridorEdge corridor in graph.corridors)
            PlaceCorridor(grid, corridor);
    }

    /// <summary>
    /// Zeichnet einen 2-Tile-breiten geraden Korridor von start bis end (inkl.).
    /// Der zweite Tile liegt in der zur Gangrichtung senkrechten Richtung +1.
    /// </summary>
    private static void PlaceCorridor(MapData grid, CorridorEdge corridor)
    {
        bool isNS = corridor.direction == Direction.North
                 || corridor.direction == Direction.South;

        Vector2Int step = RoomCorridorGraph.DirVec(corridor.direction);
        // Senkrechte Tile-Versatz (immer +1 in X für N/S, +1 in Y für E/W)
        Vector2Int perp = isNS ? new Vector2Int(1, 0) : new Vector2Int(0, 1);

        int dist = Mathf.Abs(corridor.end.x - corridor.start.x)
                 + Mathf.Abs(corridor.end.y - corridor.start.y);

        for (int i = 0; i <= dist; i++)
        {
            Vector2Int pos  = corridor.start + step * i;
            Vector2Int pos2 = pos + perp;

            SafeSetFloor(grid, pos);
            SafeSetFloor(grid, pos2);
        }
    }

    private static void SafeSetFloor(MapData grid, Vector2Int pos)
    {
        if (pos.x >= 0 && pos.x < grid.width && pos.y >= 0 && pos.y < grid.height)
            grid.SetCell(pos.x, pos.y, CellType.Floor);
    }

    // ── Spawn & Goal ──────────────────────────────────────────────────────────

    private static void PlaceSpawnAndGoal(MapData grid, RoomCorridorGraph graph)
    {
        Vector2Int sp = graph.spawnCell;
        Vector2Int gp = graph.goalCell;

        if (sp.x >= 0 && sp.x < grid.width && sp.y >= 0 && sp.y < grid.height)
            grid.SetCell(sp.x, sp.y, CellType.SpawnPoint);

        if (gp.x >= 0 && gp.x < grid.width && gp.y >= 0 && gp.y < grid.height)
            grid.SetCell(gp.x, gp.y, CellType.Goal);
    }
}
