using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Ersetzt für jeden Lava-Cluster mit hasPlatform == true den mittleren Tile
/// durch CellType.Platform und trägt den Y-Offset (0.75 Units) in MapData ein.
///
/// Das Platform-Tile liegt im Grid an derselben XZ-Position wie ein Lava-Tile,
/// wird aber beim Instantiieren 0.75 Units höher gesetzt.
/// Umgebende Lava-Tiles bleiben Lava (visuell + Todestrigger).
/// </summary>
public static class PlatformPlacer
{
    private const float PLATFORM_HEIGHT = 0.75f;

    public static void PlacePlatforms(MapData grid, List<ObstacleCluster> clusters)
    {
        foreach (ObstacleCluster cluster in clusters)
        {
            if (cluster.type != CellType.Lava || !cluster.hasPlatform)
                continue;

            Vector2Int platformCell = ClusterCenter(cluster);

            // Sicherstellen dass der gewählte Tile innerhalb des Grids liegt
            if (platformCell.x < 0 || platformCell.x >= grid.width ||
                platformCell.y < 0 || platformCell.y >= grid.height)
                continue;

            grid.SetCell(platformCell.x, platformCell.y, CellType.Platform);
            grid.cellHeightOffsets[platformCell] = PLATFORM_HEIGHT;
            cluster.platformCell = platformCell;
        }
    }

    /// <summary>
    /// Mittlerer Tile des Clusters (Bounding-Box-Zentrum, abgerundet).
    /// </summary>
    private static Vector2Int ClusterCenter(ObstacleCluster c)
    {
        bool isNS = c.gangDir == Direction.North || c.gangDir == Direction.South;

        if (isNS)
        {
            int cx = c.origin.x + c.width / 2;
            int cy = c.origin.y + c.depth / 2;
            return new Vector2Int(cx, cy);
        }
        else
        {
            int cx = c.origin.x + c.depth / 2;
            int cy = c.origin.y + c.width / 2;
            return new Vector2Int(cx, cy);
        }
    }
}
