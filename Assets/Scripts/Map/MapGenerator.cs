using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public enum MapSelectionMode
{
    Fixed,
    Random
}

public enum ObstaclePlacementMode
{
    RandomOnFloor,
    PredefinedSpawnPoints
}

public enum SpawnPlacementMode
{
    RandomSpawnPoints,
    PredefinedSpawnPoints
}

public class MapGenerator : MonoBehaviour
{
    [Header("Map Layouts")]
    public MapData[] mapLayouts;

    [Header("Map Selection")]
    public MapSelectionMode selectionMode = MapSelectionMode.Fixed;
    public int selectedLayoutIndex = 0;
    public bool avoidImmediateRepeat = true;

    [Header("Prefabs")]
    public GameObject floorPrefab;
    public GameObject wallPrefab;
    public GameObject[] obstaclePrefabs;
    public GameObject goalPrefab;
    public GameObject spawnPointPrefab;
    public GameObject lavaPrefab;
    public GameObject holePrefab;
    public GameObject platformPrefab;

    [Header("Obstacle Placement")]
    public ObstaclePlacementMode obstaclePlacementMode = ObstaclePlacementMode.RandomOnFloor;

    [Header("Runtime Obstacles")]
    [Min(0)] public int runtimeObstacleCount = 3;
    public bool randomizeObstaclePrefab = true;

    [Header("Procedural Generation")]
    [Tooltip("true = prozedurales Layout; false = MapData-Assets (Training)")]
    public bool useProceduralGeneration = false;

    [Header("Map Settings")]
    public float cellSize = 1f;

    [Header("Spawn Settings")]
    public SpawnPlacementMode spawnPlacementMode = SpawnPlacementMode.RandomSpawnPoints;
    [Tooltip("false = Vector3.zero bei fehlendem SpawnPoint, true = Mitte der Map")]
    public bool useCenterFallback = false;

    [Header("Camera Framing")]
    public bool autoFrameCamera = true;
    public Camera targetCamera;
    [Range(20f, 80f)] public float cameraPitch = 60f;
    public float cameraPadding = 1.2f;
    public float minCameraDistance = 8f;
    public float minCameraHeight = 6f;

    private Transform mapRoot;
    private readonly List<GameObject> spawnedObjects = new List<GameObject>();

    private MapData currentMapData;
    private int currentLayoutIndex = -1;

    private Vector2Int currentSpawnCell = new Vector2Int(-1, -1);
    private Vector3 currentSpawnWorldPosition = Vector3.zero;

    private Vector2Int currentGoalCell = new Vector2Int(-1, -1);
    private Vector3 currentGoalWorldPosition = Vector3.zero;

    private readonly List<Vector2Int> currentRuntimeObstacleCells = new List<Vector2Int>();

    private void Awake()
    {
        EnsureMapRoot();
    }

    private void Start()
    {
        GenerateRuntimeMap();
    }

    private void EnsureMapRoot()
    {
        if (mapRoot != null) return;

        Transform existing = transform.Find("MapRoot");
        if (existing != null)
        {
            mapRoot = existing;
        }
        else
        {
            GameObject root = new GameObject("MapRoot");
            mapRoot = root.transform;
            mapRoot.SetParent(transform);
            mapRoot.localPosition = Vector3.zero;
            mapRoot.localRotation = Quaternion.identity;
            mapRoot.localScale = Vector3.one;
        }
    }

    public void GenerateRuntimeMap()
    {
        if (useProceduralGeneration)
        {
            MapData layout = ProceduralLayoutGenerator.GenerateLayout(
                Random.Range(0, 99999), mapLayouts);

            if (layout != null)
                GenerateMap(layout);
            return;
        }

        SelectMapLayout();

        if (currentMapData == null)
            return;

        GenerateMap(currentMapData);
    }

    public void GenerateSelectedMap()
    {
        if (!TryGetLayoutByIndex(selectedLayoutIndex, out MapData selectedMap))
            return;

        currentLayoutIndex = selectedLayoutIndex;
        currentMapData = selectedMap;

        GenerateMap(currentMapData);
    }

    private void SelectMapLayout()
    {
        if (mapLayouts == null || mapLayouts.Length == 0)
        {
            Debug.LogError("MapGenerator: Keine Map-Layouts zugewiesen!");
            currentMapData = null;
            return;
        }

        if (selectionMode == MapSelectionMode.Fixed)
        {
            selectedLayoutIndex = Mathf.Clamp(selectedLayoutIndex, 0, mapLayouts.Length - 1);

            if (!TryGetLayoutByIndex(selectedLayoutIndex, out MapData selectedMap))
            {
                currentMapData = null;
                return;
            }

            currentLayoutIndex = selectedLayoutIndex;
            currentMapData = selectedMap;
        }
        else
        {
            int randomIndex = GetRandomLayoutIndex();

            if (!TryGetLayoutByIndex(randomIndex, out MapData selectedMap))
            {
                currentMapData = null;
                return;
            }

            currentLayoutIndex = randomIndex;
            selectedLayoutIndex = randomIndex;
            currentMapData = selectedMap;
        }
    }

    private int GetRandomLayoutIndex()
    {
        if (mapLayouts == null || mapLayouts.Length == 0)
            return -1;

        if (mapLayouts.Length == 1)
            return 0;

        int randomIndex = Random.Range(0, mapLayouts.Length);

        if (avoidImmediateRepeat && currentLayoutIndex >= 0)
        {
            while (randomIndex == currentLayoutIndex)
            {
                randomIndex = Random.Range(0, mapLayouts.Length);
            }
        }

        return randomIndex;
    }

    private bool TryGetLayoutByIndex(int index, out MapData mapData)
    {
        mapData = null;

        if (mapLayouts == null || mapLayouts.Length == 0)
        {
            Debug.LogError("MapGenerator: Keine Map-Layouts zugewiesen!");
            return false;
        }

        if (index < 0 || index >= mapLayouts.Length)
        {
            Debug.LogError($"MapGenerator: selectedLayoutIndex {index} ist außerhalb des gültigen Bereichs!");
            return false;
        }

        mapData = mapLayouts[index];

        if (mapData == null)
        {
            Debug.LogError($"MapGenerator: Layout an Index {index} ist null!");
            return false;
        }

        if (mapData.cells == null || mapData.cells.Length != mapData.width * mapData.height)
        {
            Debug.LogError($"MapGenerator: Layout '{mapData.name}' hat keine gültigen cells!");
            return false;
        }

        return true;
    }

    public void GenerateMap(MapData mapData)
    {
        if (mapData == null)
        {
            Debug.LogError("MapGenerator: mapData ist null!");
            return;
        }

        if (mapData.cells == null || mapData.cells.Length != mapData.width * mapData.height)
        {
            Debug.LogError($"MapGenerator: Layout '{mapData.name}' hat keine gültigen cells!");
            return;
        }

        EnsureMapRoot();
        ClearMap();

        currentMapData = mapData;

        Vector2Int spawnCell = SelectRandomSpawnCell(mapData);
        currentSpawnCell = spawnCell;
        currentSpawnWorldPosition = spawnCell.x >= 0 && spawnCell.y >= 0
            ? CellToWorld(spawnCell)
            : Vector3.zero;

        Vector2Int goalCell = SelectRandomGoalCell(mapData, currentSpawnCell);
        currentGoalCell = goalCell;
        currentGoalWorldPosition = goalCell.x >= 0 && goalCell.y >= 0
            ? CellToWorld(goalCell)
            : Vector3.zero;

        currentRuntimeObstacleCells.Clear();
        // Bei prozeduraler Generierung sind Obstacles bereits im Grid eingebaut
        if (!useProceduralGeneration)
            PlaceRuntimeObstacles(mapData, currentSpawnCell, currentGoalCell);

        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType cellType = mapData.GetCell(x, y);
                GameObject prefab = GetPrefabForCell(cellType);

                if (prefab != null)
                {
                    float yOffset = cellType == CellType.Platform
                        ? mapData.cellHeightOffsets.TryGetValue(new Vector2Int(x, y), out float h) ? h : 0.75f
                        : 0f;
                    Vector3 position = new Vector3(x * cellSize, yOffset, y * cellSize);
                    GameObject instance = Instantiate(prefab, position, Quaternion.identity, mapRoot);
                    instance.name = $"{cellType}_{x}_{y}";
                    spawnedObjects.Add(instance);
                }
            }
        }

        SpawnRuntimeMarkersAndObstacles();
        SpawnKillZone();
        FrameCameraToCurrentMap();
    }

    private void SpawnRuntimeMarkersAndObstacles()
    {
        if (spawnPointPrefab != null && IsValidCell(currentSpawnCell))
        {
            GameObject spawnInstance = Instantiate(spawnPointPrefab, CellToWorld(currentSpawnCell), Quaternion.identity, mapRoot);
            spawnInstance.name = $"RuntimeSpawnPoint_{currentSpawnCell.x}_{currentSpawnCell.y}";
            spawnedObjects.Add(spawnInstance);
        }

        if (goalPrefab != null && IsValidCell(currentGoalCell))
        {
            GameObject goalInstance = Instantiate(goalPrefab, CellToWorld(currentGoalCell), Quaternion.identity, mapRoot);
            goalInstance.name = $"RuntimeGoal_{currentGoalCell.x}_{currentGoalCell.y}";
            spawnedObjects.Add(goalInstance);
        }

        if (obstaclePrefabs == null || obstaclePrefabs.Length == 0)
            return;

        foreach (Vector2Int obstacleCell in currentRuntimeObstacleCells)
        {
            GameObject obstaclePrefab = GetRuntimeObstaclePrefab();
            if (obstaclePrefab == null)
                continue;

            GameObject obstacleInstance = Instantiate(obstaclePrefab, CellToWorld(obstacleCell), Quaternion.identity, mapRoot);
            obstacleInstance.name = $"RuntimeObstacle_{obstacleCell.x}_{obstacleCell.y}";
            spawnedObjects.Add(obstacleInstance);

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
        }
    }

    /// <summary>
    /// Erzeugt eine unsichtbare Trigger-Box unter der gesamten Map.
    /// Wenn der Agent durch ein Hole fällt und diese Box berührt, wird die Episode beendet.
    /// </summary>
    private void SpawnKillZone()
    {
        if (currentMapData == null) return;

        float mapWidth = currentMapData.width * cellSize;
        float mapHeight = currentMapData.height * cellSize;

        float killZoneY = -20f;
        float killZoneThickness = 1f;

        GameObject killZone = new GameObject("KillZone");
        killZone.transform.SetParent(mapRoot);
        killZone.tag = "KillZone";

        // Zentriert unter der Map positionieren
        killZone.transform.localPosition = new Vector3(
            (mapWidth - cellSize) / 2f,
            killZoneY,
            (mapHeight - cellSize) / 2f
        );

        BoxCollider col = killZone.AddComponent<BoxCollider>();
        col.isTrigger = true;
        col.size = new Vector3(mapWidth, killZoneThickness, mapHeight);
        col.center = Vector3.zero;
    }

    private GameObject GetRuntimeObstaclePrefab()
    {
        if (obstaclePrefabs == null || obstaclePrefabs.Length == 0)
            return null;

        if (!randomizeObstaclePrefab || obstaclePrefabs.Length == 1)
            return obstaclePrefabs[0];

        return obstaclePrefabs[Random.Range(0, obstaclePrefabs.Length)];
    }

    private void PlaceRuntimeObstacles(MapData mapData, Vector2Int spawnCell, Vector2Int goalCell)
    {
        if (runtimeObstacleCount <= 0)
            return;

        List<Vector2Int> candidates = GetObstacleCandidateCells(mapData, spawnCell, goalCell);
        Shuffle(candidates);

        int requestedCount = Mathf.Min(runtimeObstacleCount, candidates.Count);

        for (int i = 0; i < candidates.Count && currentRuntimeObstacleCells.Count < requestedCount; i++)
        {
            Vector2Int candidate = candidates[i];
            currentRuntimeObstacleCells.Add(candidate);

            if (!HasWalkablePath(mapData, spawnCell, goalCell, currentRuntimeObstacleCells))
            {
                currentRuntimeObstacleCells.RemoveAt(currentRuntimeObstacleCells.Count - 1);
            }
        }

        if (requestedCount > 0 && currentRuntimeObstacleCells.Count < requestedCount)
        {
            Debug.LogWarning(
                $"MapGenerator: Es konnten nur {currentRuntimeObstacleCells.Count} von {requestedCount} Hindernissen platziert werden, damit der Pfad zwischen Spawn und Ziel begehbar bleibt.");
        }
    }

    /// <summary>
    /// Gibt die Kandidaten-Zellen für Hindernisse zurück, abhängig vom gewählten ObstaclePlacementMode.
    /// 
    /// RandomOnFloor: Alle begehbaren Zellen (Floor, SpawnPoint, Goal, Obstacle) außer Spawn- und Goal-Zelle.
    /// PredefinedSpawnPoints: Nur CellType.Obstacle-Zellen aus dem Layout, außer Spawn- und Goal-Zelle.
    /// </summary>
    private List<Vector2Int> GetObstacleCandidateCells(MapData mapData, Vector2Int spawnCell, Vector2Int goalCell)
    {
        List<Vector2Int> candidates = new List<Vector2Int>();

        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType cellType = mapData.GetCell(x, y);
                Vector2Int candidate = new Vector2Int(x, y);

                if (candidate == spawnCell || candidate == goalCell)
                    continue;

                if (obstaclePlacementMode == ObstaclePlacementMode.PredefinedSpawnPoints)
                {
                    // Nur Zellen mit CellType.Obstacle sind gültige Hindernis-Spawnpunkte
                    if (cellType != CellType.Obstacle)
                        continue;
                }
                else
                {
                    // RandomOnFloor: Alle begehbaren Zellen sind Kandidaten
                    if (!IsWalkableCellType(cellType))
                        continue;
                }

                candidates.Add(candidate);
            }
        }

        return candidates;
    }

    private bool HasWalkablePath(MapData mapData, Vector2Int start, Vector2Int goal, List<Vector2Int> blockedCells)
    {
        if (!IsValidCell(start) || !IsValidCell(goal))
            return false;

        HashSet<Vector2Int> blocked = new HashSet<Vector2Int>(blockedCells);
        if (blocked.Contains(start) || blocked.Contains(goal))
            return false;

        Queue<Vector2Int> queue = new Queue<Vector2Int>();
        HashSet<Vector2Int> visited = new HashSet<Vector2Int>();

        queue.Enqueue(start);
        visited.Add(start);

        Vector2Int[] directions =
        {
            Vector2Int.up,
            Vector2Int.down,
            Vector2Int.left,
            Vector2Int.right
        };

        while (queue.Count > 0)
        {
            Vector2Int current = queue.Dequeue();
            if (current == goal)
                return true;

            for (int i = 0; i < directions.Length; i++)
            {
                Vector2Int next = current + directions[i];

                if (visited.Contains(next) || blocked.Contains(next))
                    continue;

                if (next.x < 0 || next.x >= mapData.width || next.y < 0 || next.y >= mapData.height)
                    continue;

                if (!IsWalkableCellType(mapData.GetCell(next.x, next.y)))
                    continue;

                visited.Add(next);
                queue.Enqueue(next);
            }
        }

        return false;
    }

    private bool IsWalkableCellType(CellType cellType)
    {
        return cellType == CellType.Floor
            || cellType == CellType.SpawnPoint
            || cellType == CellType.Goal
            || cellType == CellType.Obstacle
            || cellType == CellType.Lava      // überspringbar (Semantik wird im SemanticPathfinder verfeinert)
            || cellType == CellType.Platform; // schwebendes Bodenfeld
        // CellType.Hole: bewusst ausgeschlossen — nie begehbar
    }

    private bool IsValidCell(Vector2Int cell)
    {
        return cell.x >= 0 && cell.y >= 0;
    }

    private Vector3 CellToWorld(Vector2Int cell)
    {
        return new Vector3(cell.x * cellSize, 0f, cell.y * cellSize);
    }

    private void Shuffle<T>(List<T> list)
    {
        for (int i = list.Count - 1; i > 0; i--)
        {
            int j = Random.Range(0, i + 1);
            T temp = list[i];
            list[i] = list[j];
            list[j] = temp;
        }
    }

    public void ClearMap()
    {
        EnsureMapRoot();

        for (int i = mapRoot.childCount - 1; i >= 0; i--)
        {
            GameObject child = mapRoot.GetChild(i).gameObject;

            if (Application.isPlaying)
                Destroy(child);
            else
                DestroyImmediate(child);
        }

        spawnedObjects.Clear();
        currentSpawnCell = new Vector2Int(-1, -1);
        currentSpawnWorldPosition = Vector3.zero;
        currentGoalCell = new Vector2Int(-1, -1);
        currentGoalWorldPosition = Vector3.zero;
        currentRuntimeObstacleCells.Clear();
    }

    public void ResetMap()
    {
        GenerateRuntimeMap();
    }

    public void NextLayout()
    {
        if (mapLayouts == null || mapLayouts.Length == 0)
            return;

        selectedLayoutIndex = (selectedLayoutIndex + 1) % mapLayouts.Length;
        GenerateSelectedMap();
    }

    public void PreviousLayout()
    {
        if (mapLayouts == null || mapLayouts.Length == 0)
            return;

        selectedLayoutIndex--;

        if (selectedLayoutIndex < 0)
            selectedLayoutIndex = mapLayouts.Length - 1;

        GenerateSelectedMap();
    }

    private GameObject GetPrefabForCell(CellType type)
    {
        switch (type)
        {
            case CellType.Floor:
                return floorPrefab;

            case CellType.Wall:
                return wallPrefab;

            case CellType.Obstacle:
                return floorPrefab;

            case CellType.Goal:
                return floorPrefab;

            case CellType.SpawnPoint:
                return floorPrefab;

            case CellType.Lava:
                return lavaPrefab;

            case CellType.Hole:
                return holePrefab;

            case CellType.Platform:
                return platformPrefab;

            default:
                return null;
        }
    }

    /// <summary>
    /// Wählt eine Spawn-Zelle für den Agenten abhängig vom SpawnPlacementMode.
    ///
    /// PredefinedSpawnPoints: Nur CellType.SpawnPoint-Zellen aus dem Layout.
    ///   Enthält das Layout keine SpawnPoint-Zellen, wird eine Warning geloggt
    ///   und auf zufällige begehbare Zellen zurückgefallen.
    /// RandomSpawnPoints: Alle begehbaren Zellen; CellType.Obstacle-Zellen werden
    ///   ausgeschlossen, wenn obstaclePlacementMode == PredefinedSpawnPoints,
    ///   da diese für Hindernisse reserviert sind.
    /// </summary>
    private Vector2Int SelectRandomSpawnCell(MapData mapData)
    {
        if (mapData == null || mapData.cells == null || mapData.cells.Length != mapData.width * mapData.height)
            return new Vector2Int(-1, -1);

        if (spawnPlacementMode == SpawnPlacementMode.PredefinedSpawnPoints)
        {
            List<Vector2Int> predefinedCells = new List<Vector2Int>();

            for (int y = 0; y < mapData.height; y++)
            {
                for (int x = 0; x < mapData.width; x++)
                {
                    if (mapData.GetCell(x, y) == CellType.SpawnPoint)
                        predefinedCells.Add(new Vector2Int(x, y));
                }
            }

            if (predefinedCells.Count > 0)
                return predefinedCells[Random.Range(0, predefinedCells.Count)];

            Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' enthält keine SpawnPoint-Zellen. Fallback auf zufällige begehbare Zelle.");
        }

        // RandomSpawnPoints oder Fallback aus PredefinedSpawnPoints
        List<Vector2Int> validSpawnCells = new List<Vector2Int>();

        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType cellType = mapData.GetCell(x, y);

                if (obstaclePlacementMode == ObstaclePlacementMode.PredefinedSpawnPoints)
                {
                    // Obstacle-Zellen sind für Hindernisse reserviert, nicht für Agent-Spawn
                    if (cellType == CellType.Floor || cellType == CellType.SpawnPoint || cellType == CellType.Goal)
                        validSpawnCells.Add(new Vector2Int(x, y));
                }
                else
                {
                    // RandomOnFloor: Alle begehbaren Zellen inkl. Obstacle
                    if (cellType == CellType.Floor || cellType == CellType.SpawnPoint || cellType == CellType.Goal || cellType == CellType.Obstacle)
                        validSpawnCells.Add(new Vector2Int(x, y));
                }
            }
        }

        if (validSpawnCells.Count == 0)
        {
            Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' enthält keine gültige Floor-Zelle für den Spawnpunkt.");
            return new Vector2Int(-1, -1);
        }

        return validSpawnCells[Random.Range(0, validSpawnCells.Count)];
    }

    /// <summary>
    /// Wählt eine zufällige Goal-Zelle.
    /// 
    /// Im Modus PredefinedSpawnPoints werden CellType.Obstacle-Zellen ausgeschlossen,
    /// damit Hindernis-Spawnpunkte nicht als Zielposition verwendet werden.
    /// </summary>
    private Vector2Int SelectRandomGoalCell(MapData mapData, Vector2Int spawnCell)
    {
        if (mapData == null || mapData.cells == null || mapData.cells.Length != mapData.width * mapData.height)
            return new Vector2Int(-1, -1);

        List<Vector2Int> validGoalCells = new List<Vector2Int>();
        List<Vector2Int> fallbackGoalCells = new List<Vector2Int>();

        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType cellType = mapData.GetCell(x, y);

                bool isValidGoalType;

                if (obstaclePlacementMode == ObstaclePlacementMode.PredefinedSpawnPoints)
                {
                    // Obstacle-Zellen sind für Hindernisse reserviert, nicht für Goal
                    isValidGoalType = (cellType == CellType.Floor || cellType == CellType.Goal || cellType == CellType.SpawnPoint);
                }
                else
                {
                    // RandomOnFloor: Alle begehbaren Zellen inkl. Obstacle
                    isValidGoalType = (cellType == CellType.Floor || cellType == CellType.Goal || cellType == CellType.SpawnPoint || cellType == CellType.Obstacle);
                }

                if (isValidGoalType)
                {
                    Vector2Int candidate = new Vector2Int(x, y);
                    fallbackGoalCells.Add(candidate);

                    if (candidate != spawnCell)
                    {
                        validGoalCells.Add(candidate);
                    }
                }
            }
        }

        if (validGoalCells.Count > 0)
            return validGoalCells[Random.Range(0, validGoalCells.Count)];

        if (fallbackGoalCells.Count > 0)
        {
            Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' enthält nur eine gültige Ziel-Zelle. Spawn und Ziel können identisch sein.");
            return fallbackGoalCells[Random.Range(0, fallbackGoalCells.Count)];
        }

        Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' enthält keine gültige Floor-Zelle für das Zielobjekt.");
        return new Vector2Int(-1, -1);
    }

    public Vector3 GetSpawnPosition()
    {
        if (currentSpawnCell.x >= 0 && currentSpawnCell.y >= 0)
            return currentSpawnWorldPosition;

        if (currentMapData == null)
        {
            Debug.LogWarning("MapGenerator: Kein aktuelles Map-Layout ausgewählt!");
            return GetFallbackPosition();
        }

        Vector2Int fallbackSpawnCell = SelectRandomSpawnCell(currentMapData);

        if (fallbackSpawnCell.x >= 0 && fallbackSpawnCell.y >= 0)
        {
            currentSpawnCell = fallbackSpawnCell;
            currentSpawnWorldPosition = CellToWorld(fallbackSpawnCell);
            return currentSpawnWorldPosition;
        }

        Debug.LogWarning("MapGenerator: Keine gültige Spawn-Position gefunden!");
        return GetFallbackPosition();
    }

    public Vector3 GetGoalPosition()
    {
        if (currentGoalCell.x >= 0 && currentGoalCell.y >= 0)
            return currentGoalWorldPosition;

        if (currentMapData == null)
        {
            Debug.LogWarning("MapGenerator: Kein aktuelles Map-Layout ausgewählt!");
            return Vector3.zero;
        }

        Vector2Int fallbackGoalCell = SelectRandomGoalCell(currentMapData, currentSpawnCell);

        if (fallbackGoalCell.x >= 0 && fallbackGoalCell.y >= 0)
        {
            currentGoalCell = fallbackGoalCell;
            currentGoalWorldPosition = CellToWorld(fallbackGoalCell);
            return currentGoalWorldPosition;
        }

        Debug.LogWarning("MapGenerator: Keine gültige Ziel-Position gefunden!");
        return Vector3.zero;
    }

    private Vector3 GetFallbackPosition()
    {
        if (useCenterFallback && currentMapData != null)
        {
            float centerX = (currentMapData.width - 1) * cellSize * 0.5f;
            float centerZ = (currentMapData.height - 1) * cellSize * 0.5f;
            return new Vector3(centerX, 0f, centerZ);
        }

        return Vector3.zero;
    }

    private void FrameCameraToCurrentMap()
    {
        if (!autoFrameCamera || currentMapData == null)
            return;

        Camera cam = targetCamera != null ? targetCamera : Camera.main;
        if (cam == null)
        {
            Debug.LogWarning("MapGenerator: Keine Kamera gefunden. Weise targetCamera zu oder tagge die Kamera als MainCamera.");
            return;
        }

        float worldWidth = Mathf.Max(1f, currentMapData.width * cellSize);
        float worldHeight = Mathf.Max(1f, currentMapData.height * cellSize);

        Vector3 mapCenter = new Vector3(
            (currentMapData.width - 1) * cellSize * 0.5f,
            0f,
            (currentMapData.height - 1) * cellSize * 0.5f
        );

        cam.transform.rotation = Quaternion.Euler(cameraPitch, 0f, 0f);

        if (cam.orthographic)
        {
            float sizeFromHeight = worldHeight * 0.5f;
            float sizeFromWidth = worldWidth / (2f * Mathf.Max(0.01f, cam.aspect));
            cam.orthographicSize = Mathf.Max(sizeFromHeight, sizeFromWidth) * cameraPadding;

            Vector3 cameraPos = mapCenter - cam.transform.forward * minCameraDistance;
            cameraPos.y = Mathf.Max(minCameraHeight, cameraPos.y);
            cam.transform.position = cameraPos;
        }
        else
        {
            float halfVerticalFov = cam.fieldOfView * 0.5f * Mathf.Deg2Rad;
            float halfHorizontalFov = Mathf.Atan(Mathf.Tan(halfVerticalFov) * cam.aspect);

            float distanceForHeight = (worldHeight * 0.5f * cameraPadding) / Mathf.Tan(halfVerticalFov);
            float distanceForWidth = (worldWidth * 0.5f * cameraPadding) / Mathf.Tan(halfHorizontalFov);
            float requiredDistance = Mathf.Max(distanceForHeight, distanceForWidth, minCameraDistance);

            Vector3 cameraPos = mapCenter - cam.transform.forward * requiredDistance;
            cameraPos.y = Mathf.Max(minCameraHeight, cameraPos.y);
            cam.transform.position = cameraPos;
        }

#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            EditorUtility.SetDirty(cam);
        }
#endif
    }
}