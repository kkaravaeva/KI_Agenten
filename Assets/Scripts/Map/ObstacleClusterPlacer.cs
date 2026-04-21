using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Platziert Lava- und Hole-Cluster in den Korridoren der Topologie.
///
/// Regeln:
///   Goal-Korridor  → Lava, Tiefe 1/2/3 (zufällig gewichtet), hasPlatform wenn Tiefe > 1
///   Dead-End-Korridor → Hole, Tiefe immer 2 (Nicht-Überspringbarkeit durch Größe)
///   Loop-Korridor  → optional Lava Tiefe 1 (50 %)
/// </summary>
public static class ObstacleClusterPlacer
{
    public static void PlaceClusters(MapData grid, RoomCorridorGraph graph, DifficultySettings settings)
    {
        foreach (CorridorEdge corridor in graph.corridors)
        {
            if (corridor.isTerminal)
            {
                // Terminal-Korridor: immer Hole am Ende (kein Raum dahinter)
                ObstacleCluster c = BuildHoleCluster(corridor);
                PlaceCluster(grid, c);
                corridor.obstacle = c;
            }
            else if (corridor.leadsToGoal)
            {
                // Goal-Korridor: immer Lava
                PlaceGoalCorridorObstacles(grid, corridor, settings);
            }
            else if (corridor.isLoop)
            {
                // Loop: 50 % Lava Tiefe 1
                if (Random.value < 0.5f)
                {
                    ObstacleCluster c = BuildLoopLavaCluster(corridor);
                    PlaceCluster(grid, c);
                    corridor.obstacle = c;
                }
            }
            else if (corridor.roomB != null && corridor.roomB.type == RoomType.DeadEnd)
            {
                float roll          = Random.value;
                float noObstThresh  = settings.DeadEndNoObstacleChance;
                float holeThresh    = noObstThresh + settings.DeadEndHoleChance;

                ObstacleCluster cluster = null;
                if      (roll < noObstThresh) cluster = null;
                else if (roll < holeThresh)   cluster = BuildHoleCluster(corridor);
                else                          cluster = BuildDeadEndLavaCluster(corridor);

                if (cluster != null)
                {
                    PlaceCluster(grid, cluster);
                    corridor.obstacle = cluster;
                }
            }
        }
    }

    private static void PlaceGoalCorridorObstacles(MapData grid, CorridorEdge corridor,
                                                    DifficultySettings settings)
    {
        // Immer genau 1 Cluster – bei 2 Clustern würde nur der letzte registriert,
        // was den Pathfinder dazu bringt, erste-Cluster-Tiles als unbekannt zu werten.
        ObstacleCluster c = BuildLavaCluster(corridor, settings, 0, 1);
        PlaceCluster(grid, c);
        corridor.obstacle = c;
    }

    // ── Cluster-Builder ───────────────────────────────────────────────────────

    private static ObstacleCluster BuildLavaCluster(CorridorEdge corridor,
                                                     DifficultySettings settings,
                                                     int slotIndex = 0, int totalSlots = 1)
    {
        float roll   = Random.value;
        float depth3 = settings.GoalLavaDepth3Chance;
        float depth12split = (1f - depth3) * 0.5f;
        int depth = roll < depth12split ? 1 : roll < depth12split * 2f ? 2 : 3;

        Vector2Int origin = SlottedOrigin(corridor, depth, slotIndex, totalSlots);

        return new ObstacleCluster
        {
            origin      = origin,
            depth       = depth,
            width       = 2,
            type        = CellType.Lava,
            hasPlatform = depth > 1,
            gangDir     = corridor.direction
        };
    }

    private static ObstacleCluster BuildHoleCluster(CorridorEdge corridor)
    {
        // Hole: Tiefe 2 (nicht überspringbar), nahe am Dead-End-Eingang
        Vector2Int origin = DeadEndOrigin(corridor, depth: 2);

        return new ObstacleCluster
        {
            origin      = origin,
            depth       = 2,
            width       = 2,
            type        = CellType.Hole,
            hasPlatform = false,
            gangDir     = corridor.direction
        };
    }

    /// <summary>
    /// Lava in Dead-End-Korridoren: Tiefe 1–2, zentriert im Gang.
    /// Bei Tiefe 2 wird eine Platform platziert.
    /// </summary>
    private static ObstacleCluster BuildDeadEndLavaCluster(CorridorEdge corridor)
    {
        int depth = Random.value < 0.6f ? 1 : 2;
        Vector2Int origin = CenteredOrigin(corridor, depth);

        return new ObstacleCluster
        {
            origin      = origin,
            depth       = depth,
            width       = 2,
            type        = CellType.Lava,
            hasPlatform = depth > 1,
            gangDir     = corridor.direction
        };
    }

    private static ObstacleCluster BuildLoopLavaCluster(CorridorEdge corridor)
    {
        Vector2Int origin = CenteredOrigin(corridor, depth: 1);

        return new ObstacleCluster
        {
            origin      = origin,
            depth       = 1,
            width       = 2,
            type        = CellType.Lava,
            hasPlatform = false,
            gangDir     = corridor.direction
        };
    }

    // ── Origin-Berechnung ─────────────────────────────────────────────────────

    /// <summary>
    /// Teilt den Korridor in totalSlots gleichgroße Abschnitte und gibt den Ursprung
    /// des Clusters im Abschnitt slotIndex zurück (für mehrere Cluster pro Korridor).
    /// </summary>
    private static Vector2Int SlottedOrigin(CorridorEdge corridor, int depth,
                                             int slotIndex, int totalSlots)
    {
        if (totalSlots <= 1) return CenteredOrigin(corridor, depth);

        bool isNS = IsNorthSouth(corridor.direction);
        int minVal = isNS
            ? Mathf.Min(corridor.start.y, corridor.end.y)
            : Mathf.Min(corridor.start.x, corridor.end.x);
        int maxVal = isNS
            ? Mathf.Max(corridor.start.y, corridor.end.y)
            : Mathf.Max(corridor.start.x, corridor.end.x);

        int slotSize  = (maxVal - minVal + 1) / totalSlots;
        int slotStart = minVal + slotIndex * slotSize;
        int slotEnd   = slotStart + slotSize - 1;

        int mid     = (slotStart + slotEnd) / 2;
        int originV = Mathf.Clamp(mid - depth / 2, slotStart, slotEnd - depth + 1);
        originV     = Mathf.Max(originV, minVal);

        return isNS
            ? new Vector2Int(corridor.start.x, originV)
            : new Vector2Int(originV, corridor.start.y);
    }

    /// <summary>
    /// Berechnet den Ursprung (kleinste x,y-Ecke) eines zentrierten Clusters im Korridor.
    /// Leichter Zufalls-Offset von ±1 Tile.
    /// </summary>
    private static Vector2Int CenteredOrigin(CorridorEdge corridor, int depth)
    {
        bool isNS = IsNorthSouth(corridor.direction);
        Vector2Int mid = (corridor.start + corridor.end) / 2;

        int randomOffset = Random.Range(-1, 2); // -1, 0 oder 1

        if (isNS)
        {
            int minY = Mathf.Min(corridor.start.y, corridor.end.y);
            int maxY = Mathf.Max(corridor.start.y, corridor.end.y);
            int rawY = mid.y - depth / 2 + randomOffset;
            int clampedY = Mathf.Clamp(rawY, minY, maxY - depth + 1);
            return new Vector2Int(corridor.start.x, clampedY);
        }
        else
        {
            int minX = Mathf.Min(corridor.start.x, corridor.end.x);
            int maxX = Mathf.Max(corridor.start.x, corridor.end.x);
            int rawX = mid.x - depth / 2 + randomOffset;
            int clampedX = Mathf.Clamp(rawX, minX, maxX - depth + 1);
            return new Vector2Int(clampedX, corridor.start.y);
        }
    }

    /// <summary>
    /// Berechnet den Ursprung eines Clusters der am Dead-End-Eingang (corridor.end) beginnt,
    /// d.h. die letzten `depth` Tiles des Korridors vor dem Dead-End.
    /// </summary>
    private static Vector2Int DeadEndOrigin(CorridorEdge corridor, int depth)
    {
        bool isNS = IsNorthSouth(corridor.direction);

        if (isNS)
        {
            // Für N-Korridor: end.y ist das Maximum; origin.y = end.y - depth + 1
            // Für S-Korridor: end.y ist das Minimum; origin.y = end.y
            int originY = corridor.direction == Direction.North
                ? corridor.end.y - depth + 1
                : corridor.end.y;
            return new Vector2Int(corridor.start.x, originY);
        }
        else
        {
            int originX = corridor.direction == Direction.East
                ? corridor.end.x - depth + 1
                : corridor.end.x;
            return new Vector2Int(originX, corridor.start.y);
        }
    }

    // ── Tile-Placement ────────────────────────────────────────────────────────

    private static void PlaceCluster(MapData grid, ObstacleCluster cluster)
    {
        bool isNS = IsNorthSouth(cluster.gangDir);

        for (int d = 0; d < cluster.depth; d++)
        {
            for (int w = 0; w < cluster.width; w++)
            {
                int x = isNS ? cluster.origin.x + w : cluster.origin.x + d;
                int y = isNS ? cluster.origin.y + d : cluster.origin.y + w;

                if (x >= 0 && x < grid.width &&
                    y >= 0 && y < grid.height)
                {
                    grid.SetCell(x, y, cluster.type);
                }
            }
        }
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    private static bool IsNorthSouth(Direction dir) =>
        dir == Direction.North || dir == Direction.South;
}
