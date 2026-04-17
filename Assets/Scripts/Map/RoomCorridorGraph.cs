using System.Collections.Generic;
using UnityEngine;

// ── Enums ────────────────────────────────────────────────────────────────────

public enum RoomType { Start, Goal, DeadEnd }

public enum Direction { North, South, East, West }

// ── Data classes ─────────────────────────────────────────────────────────────

public class RoomNode
{
    public Vector2Int center;
    public Vector2Int size;                          // Innere Floor-Tiles (exkl. Wände)
    public RoomType type;
    public List<CorridorEdge> connections = new List<CorridorEdge>();
}

public class CorridorEdge
{
    public RoomNode roomA;
    public RoomNode roomB;                           // null bei Terminal-Korridoren
    public Vector2Int start;
    public Vector2Int end;
    public Direction direction;
    public bool leadsToGoal;
    public bool isLoop;
    public bool isTerminal;                          // Endet mit Hole, kein Zielraum dahinter
    public ObstacleCluster obstacle;
}

public class ObstacleCluster
{
    public Vector2Int origin;
    public int depth;
    public int width = 2;
    public CellType type;
    public bool hasPlatform;
    public Vector2Int platformCell;
    public Direction gangDir;
}

// ── Main graph class ─────────────────────────────────────────────────────────

public class RoomCorridorGraph
{
    // Variabel pro Generierung – Basisgröße + 4 Tiles Puffer (2 je Seite)
    // Basisbereich: 25–37 × 30–45  →  Grid: 29–41 × 34–49
    public int GridWidth  { get; private set; }
    public int GridHeight { get; private set; }

    // 2-Tile Puffer an allen Rändern: Inhalte dürfen nie an den Grid-Rand stoßen
    private const int BORDER = 2;

    public List<RoomNode>     rooms     = new List<RoomNode>();
    public List<CorridorEdge> corridors = new List<CorridorEdge>();
    public RoomNode startRoom;
    public RoomNode goalRoom;
    public Vector2Int spawnCell;
    public Vector2Int goalCell;

    private System.Random rng;

    private Vector2Int sizeStart;
    private Vector2Int sizeGoal;
    private Vector2Int sizeDeadEnd;

    private const int MAX_BRANCH_DEPTH = 5;
    private const int MAX_TOTAL_ROOMS  = 28;
    private const int MIN_CORRIDOR_LEN = 4;

    public bool BuildTopology(int seed)
    {
        rng = new System.Random(seed);
        rooms.Clear();
        corridors.Clear();
        startRoom = null;
        goalRoom  = null;

        // Grid = Inhaltbereich (25–37 × 30–45) + 2×BORDER Puffer je Achse
        GridWidth  = rng.Next(25, 38) + 2 * BORDER;   // 29–41
        GridHeight = rng.Next(30, 46) + 2 * BORDER;   // 34–50

        sizeStart   = new Vector2Int(rng.Next(3, 6), rng.Next(3, 6));
        sizeGoal    = new Vector2Int(3, 3);
        sizeDeadEnd = new Vector2Int(rng.Next(1, 4), rng.Next(1, 4));

        // StartRoom-Position: mindestens BORDER + half + 2 vom Rand entfernt
        int marginX = sizeStart.x / 2 + BORDER + 2;
        int marginY = sizeStart.y / 2 + BORDER + 2;
        int sx = rng.Next(marginX, GridWidth  - marginX);
        int sy = rng.Next(marginY, GridHeight - marginY);

        startRoom = MakeRoom(new Vector2Int(sx, sy), sizeStart, RoomType.Start);
        rooms.Add(startRoom);
        spawnCell = startRoom.center;

        // ── Ebene 1: 6–9 Korridore vom StartRoom ─────────────────────────────
        int            target    = rng.Next(6, 10);
        List<RoomNode> allPlaced = new List<RoomNode>();

        foreach (Direction dir in ShuffledDirections())
        {
            if (allPlaced.Count >= target) break;
            Vector2Int corrStart = CorridorExit(startRoom, dir);
            int maxAvail = GetMaxCorridorLen(corrStart, dir, sizeDeadEnd);
            if (maxAvail < MIN_CORRIDOR_LEN) continue;
            int len = rng.Next(MIN_CORRIDOR_LEN, Mathf.Min(16, maxAvail) + 1);
            RoomNode r = TryPlaceRoom(startRoom, dir, len, sizeDeadEnd);
            if (r != null) allPlaced.Add(r);
        }

        // Terminal-Korridore direkt vom StartRoom (2–4)
        AddTerminalCorridors(startRoom, 2, 4);

        if (allPlaced.Count == 0) return false;

        // ── Rekursive Verzweigung ─────────────────────────────────────────────
        foreach (RoomNode level1Room in new List<RoomNode>(allPlaced))
            BranchFrom(level1Room, depth: 1, allPlaced);

        // ── GoalRoom: am weitesten entfernter Knoten ─────────────────────────
        allPlaced.Sort((a, b) =>
            ManhattanDist(b.center, startRoom.center)
                .CompareTo(ManhattanDist(a.center, startRoom.center)));

        int goalIndex = (allPlaced.Count > 1 && rng.NextDouble() < 0.25) ? 1 : 0;
        goalRoom      = allPlaced[goalIndex];
        goalRoom.type = RoomType.Goal;
        goalRoom.size = sizeGoal;
        goalCell      = goalRoom.center;

        foreach (CorridorEdge e in goalRoom.connections)
            e.leadsToGoal = true;

        foreach (RoomNode r in allPlaced)
            if (r != goalRoom) r.type = RoomType.DeadEnd;

        // ── Min. 3 nicht-Ziel-Äste ────────────────────────────────────────────
        int deadEndRooms = 0;
        foreach (RoomNode r in allPlaced)
            if (r.type == RoomType.DeadEnd) deadEndRooms++;

        int terminalCount = 0;
        foreach (CorridorEdge e in corridors)
            if (e.isTerminal) terminalCount++;

        if (deadEndRooms + terminalCount < 2) return false;

        // Optionaler Loop (30 %)
        if (rng.NextDouble() < 0.3)
            TryAddLoop(allPlaced);

        return goalRoom != null && rooms.Exists(r => r.type == RoomType.DeadEnd);
    }

    private void BranchFrom(RoomNode node, int depth, List<RoomNode> allPlaced)
    {
        if (depth >= MAX_BRANCH_DEPTH) return;
        if (rooms.Count >= MAX_TOTAL_ROOMS) return;

        int maxBranches = depth == 1 ? rng.Next(2, 5)
                        : depth == 2 ? rng.Next(1, 4)
                        : rng.Next(1, 3);
        int maxDesiredLen = Mathf.Max(8, 18 - depth * 2);

        int placed = 0;
        foreach (Direction dir in ShuffledDirections())
        {
            if (placed >= maxBranches) break;
            if (rooms.Count >= MAX_TOTAL_ROOMS) break;
            if (rng.NextDouble() > 0.70) continue;

            Direction backDir = GetBackDirection(node);
            if (dir == backDir) continue;

            Vector2Int corrStart = CorridorExit(node, dir);
            int maxAvail = GetMaxCorridorLen(corrStart, dir, sizeDeadEnd);
            if (maxAvail < MIN_CORRIDOR_LEN) continue;

            int len = rng.Next(MIN_CORRIDOR_LEN, Mathf.Min(maxDesiredLen, maxAvail) + 1);
            RoomNode sub = TryPlaceRoom(node, dir, len, sizeDeadEnd);
            if (sub == null) continue;

            allPlaced.Add(sub);
            placed++;
            BranchFrom(sub, depth + 1, allPlaced);
        }

        // Terminal-Korridore an Ebenen 1–2
        if (depth <= 2)
            AddTerminalCorridors(node, 0, 2);
    }

    private void AddTerminalCorridors(RoomNode source, int minCount, int maxCount)
    {
        int count  = rng.Next(minCount, maxCount + 1);
        int placed = 0;

        foreach (Direction dir in ShuffledDirections())
        {
            if (placed >= count) break;

            bool dirTaken = false;
            foreach (CorridorEdge e in source.connections)
                if (e.direction == dir) { dirTaken = true; break; }
            if (dirTaken) continue;

            Vector2Int corrStart = CorridorExit(source, dir);
            int maxAvail = GetMaxTerminalLen(corrStart, dir);
            if (maxAvail < 3) continue;

            int len = rng.Next(3, Mathf.Min(12, maxAvail) + 1);
            if (TryPlaceTerminalCorridor(source, dir, corrStart, len))
                placed++;
        }
    }

    private bool TryPlaceTerminalCorridor(RoomNode source, Direction dir,
                                           Vector2Int corrStart, int len)
    {
        Vector2Int step    = DirVec(dir);
        Vector2Int corrEnd = corrStart + step * (len - 1);

        if (!InBounds(corrStart) || !InBounds(corrEnd)) return false;

        CorridorEdge edge = new CorridorEdge
        {
            roomA       = source,
            roomB       = null,
            start       = corrStart,
            end         = corrEnd,
            direction   = dir,
            leadsToGoal = false,
            isLoop      = false,
            isTerminal  = true,
            obstacle    = null
        };
        corridors.Add(edge);
        source.connections.Add(edge);
        return true;
    }

    // ── Längen-Berechnung mit BORDER-Puffer ───────────────────────────────────

    /// <summary>
    /// Maximale Korridorlänge damit der Zielraum innerhalb der Pufferzone liegt.
    /// </summary>
    private int GetMaxCorridorLen(Vector2Int corrStart, Direction dir, Vector2Int destSize)
    {
        int hx = destSize.x / 2;
        int hy = destSize.y / 2;
        switch (dir)
        {
            case Direction.North: return (GridHeight - BORDER) - 2 * hy - 2 - corrStart.y;
            case Direction.South: return corrStart.y - BORDER - 2 * hy - 2;
            case Direction.East:  return (GridWidth  - BORDER) - 2 * hx - 2 - corrStart.x;
            case Direction.West:  return corrStart.x - BORDER - 2 * hx - 2;
            default: return 0;
        }
    }

    /// <summary>
    /// Maximale Länge eines Terminal-Korridors innerhalb der Pufferzone.
    /// </summary>
    private int GetMaxTerminalLen(Vector2Int corrStart, Direction dir)
    {
        switch (dir)
        {
            case Direction.North: return (GridHeight - BORDER) - 1 - corrStart.y;
            case Direction.South: return corrStart.y - BORDER;
            case Direction.East:  return (GridWidth  - BORDER) - 1 - corrStart.x;
            case Direction.West:  return corrStart.x - BORDER;
            default: return 0;
        }
    }

    private Direction GetBackDirection(RoomNode node)
    {
        if (node.connections.Count == 0) return Direction.North;
        return Opposite(node.connections[0].direction);
    }

    public List<ObstacleCluster> GetAllClusters()
    {
        var result = new List<ObstacleCluster>();
        foreach (CorridorEdge e in corridors)
            if (e.obstacle != null) result.Add(e.obstacle);
        return result;
    }

    // ── Raum platzieren ───────────────────────────────────────────────────────

    private RoomNode TryPlaceRoom(RoomNode source, Direction dir, int corridorLen, Vector2Int destSize)
    {
        Vector2Int corrStart  = CorridorExit(source, dir);
        Vector2Int destCenter = RoomCenterAfterCorridor(corrStart, dir, corridorLen, destSize);
        RoomNode   candidate  = MakeRoom(destCenter, destSize, RoomType.DeadEnd);

        if (!InBounds(candidate) || Overlaps(candidate, rooms))
            return null;

        Vector2Int corrEnd = CorridorExit(candidate, Opposite(dir));

        CorridorEdge edge = new CorridorEdge
        {
            roomA       = source,
            roomB       = candidate,
            start       = corrStart,
            end         = corrEnd,
            direction   = dir,
            leadsToGoal = false,
            isLoop      = false,
            isTerminal  = false,
            obstacle    = null
        };
        corridors.Add(edge);
        source.connections.Add(edge);
        candidate.connections.Add(edge);
        rooms.Add(candidate);
        return candidate;
    }

    // ── Loop ─────────────────────────────────────────────────────────────────

    private void TryAddLoop(List<RoomNode> placed)
    {
        List<RoomNode> deadEnds = placed.FindAll(r => r.type == RoomType.DeadEnd);
        Shuffle(deadEnds);

        foreach (RoomNode de in deadEnds)
        {
            Direction inDir = de.connections[0].direction;

            foreach (Direction loopDir in Perpendiculars(inDir))
            {
                Vector2Int loopStart = CorridorExit(de, loopDir);
                Vector2Int loopEnd   = CorridorExit(startRoom, Opposite(loopDir));

                if (!InBounds(loopStart) || !InBounds(loopEnd)) continue;

                bool isNS = loopDir == Direction.North || loopDir == Direction.South;
                if (isNS && loopStart.x != loopEnd.x) continue;
                if (!isNS && loopStart.y != loopEnd.y) continue;

                CorridorEdge loopEdge = new CorridorEdge
                {
                    roomA       = de,
                    roomB       = startRoom,
                    start       = loopStart,
                    end         = loopEnd,
                    direction   = loopDir,
                    leadsToGoal = false,
                    isLoop      = true,
                    isTerminal  = false,
                    obstacle    = null
                };
                corridors.Add(loopEdge);
                de.connections.Add(loopEdge);
                startRoom.connections.Add(loopEdge);
                return;
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private RoomNode MakeRoom(Vector2Int center, Vector2Int size, RoomType type) =>
        new RoomNode { center = center, size = size, type = type,
                       connections = new List<CorridorEdge>() };

    public Vector2Int CorridorExit(RoomNode room, Direction dir)
    {
        int hx = room.size.x / 2;
        int hy = room.size.y / 2;
        switch (dir)
        {
            case Direction.North: return new Vector2Int(room.center.x,          room.center.y + hy + 1);
            case Direction.South: return new Vector2Int(room.center.x,          room.center.y - hy - 1);
            case Direction.East:  return new Vector2Int(room.center.x + hx + 1, room.center.y);
            case Direction.West:  return new Vector2Int(room.center.x - hx - 1, room.center.y);
            default: return room.center;
        }
    }

    private Vector2Int RoomCenterAfterCorridor(
        Vector2Int corrStart, Direction dir, int length, Vector2Int destSize)
    {
        Vector2Int step    = DirVec(dir);
        Vector2Int corrEnd = corrStart + step * (length - 1);
        int hx = destSize.x / 2;
        int hy = destSize.y / 2;
        switch (dir)
        {
            case Direction.North: return new Vector2Int(corrEnd.x,          corrEnd.y + hy + 1);
            case Direction.South: return new Vector2Int(corrEnd.x,          corrEnd.y - hy - 1);
            case Direction.East:  return new Vector2Int(corrEnd.x + hx + 1, corrEnd.y);
            case Direction.West:  return new Vector2Int(corrEnd.x - hx - 1, corrEnd.y);
            default: return corrEnd;
        }
    }

    // InBounds respektiert den BORDER-Puffer auf allen Seiten

    private bool InBounds(RoomNode room)
    {
        int hx = room.size.x / 2 + 1;
        int hy = room.size.y / 2 + 1;
        return room.center.x - hx >= BORDER && room.center.x + hx < GridWidth  - BORDER
            && room.center.y - hy >= BORDER && room.center.y + hy < GridHeight - BORDER;
    }

    private bool InBounds(Vector2Int pos) =>
        pos.x >= BORDER && pos.x < GridWidth  - BORDER
     && pos.y >= BORDER && pos.y < GridHeight - BORDER;

    private bool Overlaps(RoomNode candidate, List<RoomNode> others)
    {
        foreach (RoomNode other in others)
            if (RectsOverlap(candidate, other)) return true;
        return false;
    }

    private bool RectsOverlap(RoomNode a, RoomNode b)
    {
        int ax = a.size.x / 2 + 2, ay = a.size.y / 2 + 2;
        int bx = b.size.x / 2 + 2, by = b.size.y / 2 + 2;
        return Mathf.Abs(a.center.x - b.center.x) < ax + bx
            && Mathf.Abs(a.center.y - b.center.y) < ay + by;
    }

    private int ManhattanDist(Vector2Int a, Vector2Int b) =>
        Mathf.Abs(a.x - b.x) + Mathf.Abs(a.y - b.y);

    public static Vector2Int DirVec(Direction dir)
    {
        switch (dir)
        {
            case Direction.North: return Vector2Int.up;
            case Direction.South: return Vector2Int.down;
            case Direction.East:  return Vector2Int.right;
            case Direction.West:  return Vector2Int.left;
            default: return Vector2Int.zero;
        }
    }

    public static Direction Opposite(Direction dir)
    {
        switch (dir)
        {
            case Direction.North: return Direction.South;
            case Direction.South: return Direction.North;
            case Direction.East:  return Direction.West;
            case Direction.West:  return Direction.East;
            default: return dir;
        }
    }

    private static List<Direction> Perpendiculars(Direction dir)
    {
        return (dir == Direction.North || dir == Direction.South)
            ? new List<Direction> { Direction.East, Direction.West }
            : new List<Direction> { Direction.North, Direction.South };
    }

    private List<Direction> ShuffledDirections()
    {
        var dirs = new List<Direction>
            { Direction.North, Direction.South, Direction.East, Direction.West };
        Shuffle(dirs);
        return dirs;
    }

    private void Shuffle<T>(List<T> list)
    {
        for (int i = list.Count - 1; i > 0; i--)
        {
            int j = rng.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }
}
