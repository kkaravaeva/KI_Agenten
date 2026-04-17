using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// BFS-Pathfinder mit Obstacle-Semantik für die prozedurale Map-Validierung.
///
/// Walkability-Regeln:
///   Floor, SpawnPoint, Goal, Platform  → immer begehbar
///   Lava (Cluster depth == 1)          → begehbar (Agent kann 1 Tile überspringen)
///   Lava (Cluster depth > 1, hasPlatform) → begehbar (via Platform)
///   Lava (Cluster depth > 1, kein Platform) → NICHT begehbar
///   Hole                               → NIE begehbar
///   Wall, Empty                        → NICHT begehbar
/// </summary>
public static class SemanticPathfinder
{
    private static readonly Vector2Int[] Directions =
    {
        Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right
    };

    /// <summary>
    /// Prüft ob ein Pfad von start nach goal existiert.
    /// </summary>
    public static bool HasPath(
        MapData grid, Vector2Int start, Vector2Int goal,
        List<ObstacleCluster> clusters)
    {
        if (!IsInBounds(grid, start) || !IsInBounds(grid, goal))
            return false;

        Queue<Vector2Int>   queue   = new Queue<Vector2Int>();
        HashSet<Vector2Int> visited = new HashSet<Vector2Int>();

        queue.Enqueue(start);
        visited.Add(start);

        while (queue.Count > 0)
        {
            Vector2Int current = queue.Dequeue();
            if (current == goal) return true;

            foreach (Vector2Int dir in Directions)
            {
                Vector2Int next = current + dir;
                if (visited.Contains(next))       continue;
                if (!IsInBounds(grid, next))      continue;
                if (!IsWalkable(grid, next, clusters)) continue;

                visited.Add(next);
                queue.Enqueue(next);
            }
        }

        return false;
    }

    // ── Walkability ───────────────────────────────────────────────────────────

    private static bool IsWalkable(
        MapData grid, Vector2Int pos, List<ObstacleCluster> clusters)
    {
        CellType cell = grid.GetCell(pos.x, pos.y);

        switch (cell)
        {
            case CellType.Floor:
            case CellType.SpawnPoint:
            case CellType.Goal:
            case CellType.Platform:
            case CellType.Obstacle:    // Rückwärtskompatibilität mit alten Assets
                return true;

            case CellType.Hole:
                return false;

            case CellType.Lava:
                return IsLavaPassable(pos, clusters);

            default:
                return false;
        }
    }

    private static bool IsLavaPassable(Vector2Int pos, List<ObstacleCluster> clusters)
    {
        ObstacleCluster cluster = FindClusterAt(pos, clusters);

        if (cluster == null)
        {
            // Kein Cluster gefunden – Sicherheitsfall: nicht passierbar
            Debug.LogWarning($"SemanticPathfinder: Lava-Tile {pos} gehört zu keinem bekannten Cluster.");
            return false;
        }

        if (cluster.depth == 1)   return true;    // 1 Tile: Agent kann überspringen
        if (cluster.hasPlatform)  return true;    // Platform vorhanden: via Plattform passierbar
        return false;
    }

    // ── Cluster-Lookup ────────────────────────────────────────────────────────

    private static ObstacleCluster FindClusterAt(
        Vector2Int pos, List<ObstacleCluster> clusters)
    {
        foreach (ObstacleCluster c in clusters)
            if (ClusterContains(c, pos)) return c;
        return null;
    }

    /// <summary>
    /// Prüft ob pos innerhalb der Bounding-Box des Clusters liegt.
    /// origin ist immer die Ecke mit kleinsten x,y-Werten.
    /// </summary>
    private static bool ClusterContains(ObstacleCluster c, Vector2Int pos)
    {
        bool isNS = c.gangDir == Direction.North || c.gangDir == Direction.South;

        int depthLen = c.depth;
        int widthLen = c.width;

        if (isNS)
        {
            return pos.x >= c.origin.x && pos.x < c.origin.x + widthLen
                && pos.y >= c.origin.y && pos.y < c.origin.y + depthLen;
        }
        else
        {
            return pos.x >= c.origin.x && pos.x < c.origin.x + depthLen
                && pos.y >= c.origin.y && pos.y < c.origin.y + widthLen;
        }
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    private static bool IsInBounds(MapData grid, Vector2Int pos) =>
        pos.x >= 0 && pos.x < grid.width && pos.y >= 0 && pos.y < grid.height;
}
