using UnityEngine;

public static class ProceduralLayoutGenerator
{
    public static MapData GenerateLayout(int seed,
                                         DifficultyLevel difficulty = DifficultyLevel.Hard,
                                         MapData[] fallbackLayouts = null)
    {
        switch (difficulty)
        {
            case DifficultyLevel.Trivial:       return GenerateTrivialLayout(seed);
            case DifficultyLevel.TrivialCorr:   return GenerateTrivialCorrLayout(seed);
            case DifficultyLevel.TrivialBranch: return GenerateTrivialBranchLayout(seed);
            case DifficultyLevel.TrivialHole:   return GenerateTrivialHoleLayout(seed);
            case DifficultyLevel.TrivialHazard: return GenerateTrivialHazardLayout(seed);
        }

        DifficultySettings settings = DifficultySettings.For(difficulty);

        for (int attempt = 0; attempt < 10; attempt++)
        {
            RoomCorridorGraph graph = new RoomCorridorGraph();
            if (!graph.BuildTopology(seed + attempt, settings))
                continue;

            MapData grid = CreateGrid(graph.GridWidth, graph.GridHeight);
            FillWithEmpty(grid);
            PlaceRooms(grid, graph);
            PlaceCorridors(grid, graph);
            PlaceWalls(grid);
            PlaceSpawnAndGoal(grid, graph);

            if (!HasSufficientCoverage(grid))
            {
                Debug.LogWarning($"ProceduralLayoutGenerator: Versuch {attempt + 1} Coverage zu gering.");
                continue;
            }

            ObstacleClusterPlacer.PlaceClusters(grid, graph, settings);
            var clusters = graph.GetAllClusters();
            PlatformPlacer.PlacePlatforms(grid, clusters);

            if (SemanticPathfinder.HasPath(grid, graph.spawnCell, graph.goalCell, clusters))
                return grid;

            Debug.LogWarning($"ProceduralLayoutGenerator: Versuch {attempt + 1} ungültig (kein Pfad).");
        }

        Debug.LogError("ProceduralLayoutGenerator: Alle 10 Versuche fehlgeschlagen. Nutze Fallback-Layout.");

        if (fallbackLayouts != null && fallbackLayouts.Length > 0)
            return fallbackLayouts[0];

        return null;
    }

    // ── Trivial: 7×7 offener Raum, Spawn in Ecke, Goal random ───────────────

    private static MapData GenerateTrivialLayout(int seed)
    {
        const int size = 7;
        var rng = new System.Random(seed);
        MapData grid = CreateGrid(size, size);
        grid.name = $"Trivial_{seed % 4}";
        grid.noRuntimeObstacles = true;

        for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
                grid.SetCell(x, y, (x == 0 || x == size - 1 || y == 0 || y == size - 1)
                    ? CellType.Wall : CellType.Floor);

        // Spawn in einer der 4 Ecken (rotierend per seed)
        Vector2Int[] corners = {
            new Vector2Int(1, 1),
            new Vector2Int(size - 2, 1),
            new Vector2Int(1, size - 2),
            new Vector2Int(size - 2, size - 2)
        };
        Vector2Int spawn = corners[seed % 4];
        grid.SetCell(spawn.x, spawn.y, CellType.SpawnPoint);

        // Goal auf zufälligem Floor-Tile (nicht Spawn)
        Vector2Int goal = PickRandomFloor(grid, seed, exclude: spawn);
        grid.SetCell(goal.x, goal.y, CellType.Goal);

        return grid;
    }

    // ── Trivial-Familie: gemeinsame Basis für Corr / Branch / Hole / Hazard ────
    //   withBranch=false → TrivialCorr (kein Ast, kein Ast-Raum)
    //   withBranch=true  → Branch/Hole/Hazard (2-breiter Ast + Positionen im Result)
    //   shapeType 0=gerade H | 1=gerade V | 2=L(H→unten) | 3=L(V→rechts)

    private struct TrivialResult
    {
        public MapData    grid;
        public Vector2Int branchTip;  // oben-links der 2×2-Hole-Fläche; (-1,-1) = kein Ast
        public Vector2Int lavaCell1;  // Lava-Tile 1 quer im Hauptkorridor
        public Vector2Int lavaCell2;  // Lava-Tile 2 (== lavaCell1 bei 1-breitem Korridor)
    }

    private static TrivialResult BuildTrivialBase(int seed, bool withBranch)
    {
        var rng = new System.Random(seed);

        int spawnSize  = rng.Next(2, 5);
        int goalSize   = rng.Next(2, 5);
        int seg1Len    = rng.Next(4, 10);
        int corrWidth  = rng.Next(1, 3);
        int branchLen  = withBranch ? rng.Next(3, 7) : 0;
        int branchPos  = rng.Next(1, Mathf.Max(2, seg1Len - 2));  // Platz für 2-breiten Ast
        bool branchAlt = rng.Next(2) == 1;
        bool swapped   = rng.Next(2) == 1;
        int  shapeType = rng.Next(4);
        int  seg2Len   = shapeType >= 2 ? rng.Next(3, 8) : 0;

        const int border = 1;

        int Above(int s) => Mathf.Max(0, (s - corrWidth + 1) / 2);
        int Below(int s) => Mathf.Max(0, s - Above(s) - corrWidth);

        var r = new TrivialResult { branchTip = new Vector2Int(-1, -1) };

        switch (shapeType)
        {
            // ── 0: Gerade Horizontal ─────────────────────────────────────────
            default:
            case 0:
            {
                int spA = Above(spawnSize), spB = Below(spawnSize);
                int glA = Above(goalSize),  glB = Below(goalSize);
                int aboveCorr = Mathf.Max(!branchAlt ? branchLen : 0, Mathf.Max(spA, glA));
                int belowCorr = Mathf.Max( branchAlt ? branchLen : 0, Mathf.Max(spB, glB));
                int corrY  = border + aboveCorr;
                int leftW  = swapped ? goalSize  : spawnSize;
                int rightW = swapped ? spawnSize : goalSize;
                int cx0    = border + leftW;
                int rightX = cx0 + seg1Len;

                r.grid = CreateGrid(border + leftW + seg1Len + rightW + border,
                                    border + aboveCorr + corrWidth + belowCorr + border);
                r.grid.noRuntimeObstacles = true;
                FillWithEmpty(r.grid);

                int lA = Above(leftW), rA = Above(rightW);
                FillRoom(r.grid, border, corrY - lA, leftW,  leftW);
                FillRoom(r.grid, rightX, corrY - rA, rightW, rightW);
                for (int x = cx0; x < cx0 + seg1Len; x++)
                    for (int cw = 0; cw < corrWidth; cw++)
                        r.grid.SetCell(x, corrY + cw, CellType.Floor);
                r.grid.SetCell(border  + leftW  / 2, corrY - lA + leftW  / 2,
                    swapped ? CellType.Goal : CellType.SpawnPoint);
                r.grid.SetCell(rightX  + rightW / 2, corrY - rA + rightW / 2,
                    swapped ? CellType.SpawnPoint : CellType.Goal);

                int midX = cx0 + seg1Len / 2 - 1;
                r.lavaCell1 = new Vector2Int(midX, corrY);
                r.lavaCell2 = corrWidth >= 2 ? new Vector2Int(midX, corrY + 1) : r.lavaCell1;

                if (withBranch)
                {
                    int bX = Mathf.Clamp(cx0 + branchPos, cx0 + 1, cx0 + seg1Len - 3);
                    if (!branchAlt)
                    {
                        for (int y = corrY - 1; y >= corrY - branchLen; y--)
                            { r.grid.SetCell(bX, y, CellType.Floor); r.grid.SetCell(bX + 1, y, CellType.Floor); }
                        r.branchTip = new Vector2Int(bX, corrY - branchLen);
                    }
                    else
                    {
                        int bYs = corrY + corrWidth;
                        for (int y = bYs; y < bYs + branchLen; y++)
                            { r.grid.SetCell(bX, y, CellType.Floor); r.grid.SetCell(bX + 1, y, CellType.Floor); }
                        r.branchTip = new Vector2Int(bX, bYs + branchLen - 2);
                    }
                }
                break;
            }

            // ── 1: Gerade Vertikal ───────────────────────────────────────────
            case 1:
            {
                int spA = Above(spawnSize), spB = Below(spawnSize);
                int glA = Above(goalSize),  glB = Below(goalSize);
                int leftCorr  = Mathf.Max(!branchAlt ? branchLen : 0, Mathf.Max(spA, glA));
                int rightCorr = Mathf.Max( branchAlt ? branchLen : 0, Mathf.Max(spB, glB));
                int corrX   = border + leftCorr;
                int topH    = swapped ? goalSize  : spawnSize;
                int bottomH = swapped ? spawnSize : goalSize;
                int cy0     = border + topH;
                int bottomY = cy0 + seg1Len;

                r.grid = CreateGrid(border + leftCorr + corrWidth + rightCorr + border,
                                    border + topH + seg1Len + bottomH + border);
                r.grid.noRuntimeObstacles = true;
                FillWithEmpty(r.grid);

                int tL = Above(topH), bL = Above(bottomH);
                FillRoom(r.grid, corrX - tL, border,  topH,    topH);
                FillRoom(r.grid, corrX - bL, bottomY, bottomH, bottomH);
                for (int y = cy0; y < cy0 + seg1Len; y++)
                    for (int cw = 0; cw < corrWidth; cw++)
                        r.grid.SetCell(corrX + cw, y, CellType.Floor);
                r.grid.SetCell(corrX - tL + topH    / 2, border  + topH    / 2,
                    swapped ? CellType.Goal : CellType.SpawnPoint);
                r.grid.SetCell(corrX - bL + bottomH / 2, bottomY + bottomH / 2,
                    swapped ? CellType.SpawnPoint : CellType.Goal);

                int midY = cy0 + seg1Len / 2 - 1;
                r.lavaCell1 = new Vector2Int(corrX, midY);
                r.lavaCell2 = corrWidth >= 2 ? new Vector2Int(corrX + 1, midY) : r.lavaCell1;

                if (withBranch)
                {
                    int bY = Mathf.Clamp(cy0 + branchPos, cy0 + 1, cy0 + seg1Len - 3);
                    if (!branchAlt)
                    {
                        for (int x = corrX - 1; x >= corrX - branchLen; x--)
                            { r.grid.SetCell(x, bY, CellType.Floor); r.grid.SetCell(x, bY + 1, CellType.Floor); }
                        r.branchTip = new Vector2Int(corrX - branchLen, bY);
                    }
                    else
                    {
                        int bXs = corrX + corrWidth;
                        for (int x = bXs; x < bXs + branchLen; x++)
                            { r.grid.SetCell(x, bY, CellType.Floor); r.grid.SetCell(x, bY + 1, CellType.Floor); }
                        r.branchTip = new Vector2Int(bXs + branchLen - 2, bY);
                    }
                }
                break;
            }

            // ── 2: L-Form  [LeftRoom]──seg1──╗──seg2↓──[BottomRoom] ──────────
            case 2:
            {
                int leftRoomS   = swapped ? goalSize  : spawnSize;
                int bottomRoomS = swapped ? spawnSize : goalSize;
                int lA      = Above(leftRoomS);
                int aboveH  = Mathf.Max(!branchAlt ? branchLen : 0, lA);
                int corrY   = border + aboveH;
                int elbowX  = border + leftRoomS + seg1Len;
                int cx0     = border + leftRoomS;

                int w = border + leftRoomS + seg1Len + Mathf.Max(corrWidth, bottomRoomS) + border;
                int h = border + aboveH + corrWidth + seg2Len + bottomRoomS + border;
                h = Mathf.Max(h, corrY + Mathf.Max(leftRoomS - lA, corrWidth) + border);
                if (withBranch && branchAlt)
                    h = Mathf.Max(h, corrY + corrWidth + branchLen + border);

                r.grid = CreateGrid(w, h);
                r.grid.noRuntimeObstacles = true;
                FillWithEmpty(r.grid);

                FillRoom(r.grid, border, corrY - lA, leftRoomS, leftRoomS);
                for (int x = cx0; x < elbowX + corrWidth; x++)
                    for (int cw = 0; cw < corrWidth; cw++)
                        r.grid.SetCell(x, corrY + cw, CellType.Floor);
                for (int y = corrY + corrWidth; y < corrY + corrWidth + seg2Len; y++)
                    for (int cw = 0; cw < corrWidth; cw++)
                        r.grid.SetCell(elbowX + cw, y, CellType.Floor);

                int bottomY2 = corrY + corrWidth + seg2Len;
                FillRoom(r.grid, elbowX, bottomY2, bottomRoomS, bottomRoomS);
                r.grid.SetCell(border + leftRoomS   / 2, corrY - lA  + leftRoomS   / 2,
                    swapped ? CellType.Goal : CellType.SpawnPoint);
                r.grid.SetCell(elbowX + bottomRoomS / 2, bottomY2    + bottomRoomS / 2,
                    swapped ? CellType.SpawnPoint : CellType.Goal);

                int midX2 = cx0 + seg1Len / 2 - 1;
                r.lavaCell1 = new Vector2Int(midX2, corrY);
                r.lavaCell2 = corrWidth >= 2 ? new Vector2Int(midX2, corrY + 1) : r.lavaCell1;

                if (withBranch)
                {
                    int bX2 = Mathf.Clamp(cx0 + branchPos, cx0 + 1, elbowX - 2);
                    if (!branchAlt)
                    {
                        for (int y = corrY - 1; y >= corrY - branchLen; y--)
                            { r.grid.SetCell(bX2, y, CellType.Floor); r.grid.SetCell(bX2 + 1, y, CellType.Floor); }
                        r.branchTip = new Vector2Int(bX2, corrY - branchLen);
                    }
                    else
                    {
                        int bYs = corrY + corrWidth;
                        for (int y = bYs; y < bYs + branchLen; y++)
                            { r.grid.SetCell(bX2, y, CellType.Floor); r.grid.SetCell(bX2 + 1, y, CellType.Floor); }
                        r.branchTip = new Vector2Int(bX2, bYs + branchLen - 2);
                    }
                }
                break;
            }

            // ── 3: L-Form  [TopRoom]──seg1↓──╚──seg2→──[RightRoom] ──────────
            case 3:
            {
                int topRoomS   = swapped ? goalSize  : spawnSize;
                int rightRoomS = swapped ? spawnSize : goalSize;
                int tL      = Above(topRoomS);
                int leftCW  = Mathf.Max(!branchAlt ? branchLen : 0, tL);
                int corrX2  = border + leftCW;
                int cy02    = border + topRoomS;
                int elbowY2 = cy02 + seg1Len;

                int h = border + topRoomS + seg1Len + Mathf.Max(corrWidth, rightRoomS) + border;
                int w = border + leftCW + corrWidth + seg2Len + rightRoomS + border;
                w = Mathf.Max(w, corrX2 + Mathf.Max(topRoomS - tL, corrWidth) + border);
                if (withBranch && branchAlt)
                    w = Mathf.Max(w, corrX2 + corrWidth + branchLen + border);

                r.grid = CreateGrid(w, h);
                r.grid.noRuntimeObstacles = true;
                FillWithEmpty(r.grid);

                FillRoom(r.grid, corrX2 - tL, border, topRoomS, topRoomS);
                for (int y = cy02; y < elbowY2 + corrWidth; y++)
                    for (int cw = 0; cw < corrWidth; cw++)
                        r.grid.SetCell(corrX2 + cw, y, CellType.Floor);
                for (int x = corrX2 + corrWidth; x < corrX2 + corrWidth + seg2Len; x++)
                    for (int cw = 0; cw < corrWidth; cw++)
                        r.grid.SetCell(x, elbowY2 + cw, CellType.Floor);

                int rightX2 = corrX2 + corrWidth + seg2Len;
                FillRoom(r.grid, rightX2, elbowY2, rightRoomS, rightRoomS);
                r.grid.SetCell(corrX2 - tL + topRoomS   / 2, border  + topRoomS   / 2,
                    swapped ? CellType.Goal : CellType.SpawnPoint);
                r.grid.SetCell(rightX2    + rightRoomS  / 2, elbowY2 + rightRoomS / 2,
                    swapped ? CellType.SpawnPoint : CellType.Goal);

                int midY2 = cy02 + seg1Len / 2 - 1;
                r.lavaCell1 = new Vector2Int(corrX2, midY2);
                r.lavaCell2 = corrWidth >= 2 ? new Vector2Int(corrX2 + 1, midY2) : r.lavaCell1;

                if (withBranch)
                {
                    int bY3 = Mathf.Clamp(cy02 + branchPos, cy02 + 1, elbowY2 - 2);
                    if (!branchAlt)
                    {
                        for (int x = corrX2 - 1; x >= corrX2 - branchLen; x--)
                            { r.grid.SetCell(x, bY3, CellType.Floor); r.grid.SetCell(x, bY3 + 1, CellType.Floor); }
                        r.branchTip = new Vector2Int(corrX2 - branchLen, bY3);
                    }
                    else
                    {
                        int bXs = corrX2 + corrWidth;
                        for (int x = bXs; x < bXs + branchLen; x++)
                            { r.grid.SetCell(x, bY3, CellType.Floor); r.grid.SetCell(x, bY3 + 1, CellType.Floor); }
                        r.branchTip = new Vector2Int(bXs + branchLen - 2, bY3);
                    }
                }
                break;
            }
        }

        return r;
    }

    private static MapData GenerateTrivialCorrLayout(int seed)
    {
        TrivialResult r = BuildTrivialBase(seed, withBranch: false);
        r.grid.name = $"TrivialCorr_{seed % 200}";
        PlaceWalls(r.grid);
        return r.grid;
    }

    private static MapData GenerateTrivialBranchLayout(int seed)
    {
        TrivialResult r = BuildTrivialBase(seed, withBranch: true);
        r.grid.name = $"TrivialBranch_{seed % 200}";
        PlaceWalls(r.grid);
        return r.grid;
    }

    private static MapData GenerateTrivialHoleLayout(int seed)
    {
        TrivialResult r = BuildTrivialBase(seed, withBranch: true);
        r.grid.name = $"TrivialHole_{seed % 200}";
        PlaceWalls(r.grid);
        if (r.branchTip.x >= 0)
        {
            var t = r.branchTip;
            r.grid.SetCell(t.x,     t.y,     CellType.Hole);
            r.grid.SetCell(t.x + 1, t.y,     CellType.Hole);
            r.grid.SetCell(t.x,     t.y + 1, CellType.Hole);
            r.grid.SetCell(t.x + 1, t.y + 1, CellType.Hole);
        }
        return r.grid;
    }

    private static MapData GenerateTrivialHazardLayout(int seed)
    {
        TrivialResult r = BuildTrivialBase(seed, withBranch: true);
        r.grid.name = $"TrivialHazard_{seed % 200}";
        PlaceWalls(r.grid);
        if (r.branchTip.x >= 0)
        {
            var t = r.branchTip;
            r.grid.SetCell(t.x,     t.y,     CellType.Hole);
            r.grid.SetCell(t.x + 1, t.y,     CellType.Hole);
            r.grid.SetCell(t.x,     t.y + 1, CellType.Hole);
            r.grid.SetCell(t.x + 1, t.y + 1, CellType.Hole);
        }
        r.grid.SetCell(r.lavaCell1.x, r.lavaCell1.y, CellType.Lava);
        r.grid.SetCell(r.lavaCell2.x, r.lavaCell2.y, CellType.Lava);
        return r.grid;
    }

    // ── Grid-Hilfsmethoden ────────────────────────────────────────────────────

    private static MapData CreateGrid(int width, int height)
    {
        MapData grid = UnityEngine.ScriptableObject.CreateInstance<MapData>();
        grid.width  = width;
        grid.height = height;
        grid.Init();
        return grid;
    }

    private static void FillWithEmpty(MapData grid)
    {
        for (int y = 0; y < grid.height; y++)
            for (int x = 0; x < grid.width; x++)
                grid.SetCell(x, y, CellType.Empty);
    }

    /// <summary>Setzt einen width×height Innenbereich auf Floor (keine Wände).</summary>
    private static void FillRoom(MapData grid, int originX, int originY, int width, int height)
    {
        for (int y = originY; y < originY + height; y++)
            for (int x = originX; x < originX + width; x++)
                if (x >= 0 && x < grid.width && y >= 0 && y < grid.height)
                    grid.SetCell(x, y, CellType.Floor);
    }

    private static void PlaceWalls(MapData grid)
    {
        bool[,] shouldBeWall = new bool[grid.width, grid.height];

        for (int y = 0; y < grid.height; y++)
        {
            for (int x = 0; x < grid.width; x++)
            {
                if (grid.GetCell(x, y) != CellType.Empty) continue;

                for (int dy = -1; dy <= 1 && !shouldBeWall[x, y]; dy++)
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

        for (int y = 0; y < grid.height; y++)
            for (int x = 0; x < grid.width; x++)
                if (shouldBeWall[x, y])
                    grid.SetCell(x, y, CellType.Wall);
    }

    private static bool IsFloorLike(CellType t) =>
        t == CellType.Floor || t == CellType.SpawnPoint || t == CellType.Goal
        || t == CellType.Lava || t == CellType.Hole;

    private static Vector2Int PickRandomFloor(MapData grid, int seed, Vector2Int exclude)
    {
        var rng = new System.Random(seed ^ 0x5F3759DF);
        var candidates = new System.Collections.Generic.List<Vector2Int>();

        for (int y = 0; y < grid.height; y++)
            for (int x = 0; x < grid.width; x++)
                if (grid.GetCell(x, y) == CellType.Floor && new Vector2Int(x, y) != exclude)
                    candidates.Add(new Vector2Int(x, y));

        if (candidates.Count == 0)
            return exclude; // Fallback: Goal == Spawn (sollte nie eintreten)

        return candidates[rng.Next(candidates.Count)];
    }

    private static bool HasSufficientCoverage(MapData grid)
    {
        const int border = 2;
        int walkable = 0, total = 0;
        for (int y = border; y < grid.height - border; y++)
            for (int x = border; x < grid.width - border; x++)
            {
                total++;
                CellType c = grid.GetCell(x, y);
                if (c != CellType.Empty && c != CellType.Wall) walkable++;
            }
        return total > 0 && walkable >= total * 0.15f;
    }

    // ── Raum-Korridor-Pipeline (Easy/Medium/Hard) ─────────────────────────────

    private static void PlaceRooms(MapData grid, RoomCorridorGraph graph)
    {
        foreach (RoomNode room in graph.rooms)
            PlaceRoom(grid, room);
    }

    private static void PlaceRoom(MapData grid, RoomNode room)
    {
        int hx = room.size.x / 2;
        int hy = room.size.y / 2;

        for (int y = room.center.y - hy; y <= room.center.y + hy; y++)
            for (int x = room.center.x - hx; x <= room.center.x + hx; x++)
                if (x >= 0 && x < grid.width && y >= 0 && y < grid.height)
                    grid.SetCell(x, y, CellType.Floor);
    }

    private static void PlaceCorridors(MapData grid, RoomCorridorGraph graph)
    {
        foreach (CorridorEdge corridor in graph.corridors)
            PlaceCorridor(grid, corridor);
    }

    private static void PlaceCorridor(MapData grid, CorridorEdge corridor)
    {
        bool isNS = corridor.direction == Direction.North
                 || corridor.direction == Direction.South;

        Vector2Int step = RoomCorridorGraph.DirVec(corridor.direction);
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
