using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public enum MapSelectionMode
{
    Fixed,
    Random,
    Sequential
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

public enum GoalPlacementMode
{
    RandomGoalCells,
    PredefinedGoalSpawnPoints
}

public class MapGenerator : MonoBehaviour
{
    [Header("Training Mode")]
    public TrainingMode trainingMode = TrainingMode.Standard;
    public CurriculumConfig curriculumConfig;

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

    [Header("Map Settings")]
    public float cellSize = 1f;

    [Header("Spawn Settings")]
    public SpawnPlacementMode spawnPlacementMode = SpawnPlacementMode.RandomSpawnPoints;
    [Tooltip("false = Vector3.zero bei fehlendem SpawnPoint, true = Mitte der Map")]
    public bool useCenterFallback = false;

    [Header("Goal Settings")]
    public GoalPlacementMode goalPlacementMode = GoalPlacementMode.RandomGoalCells;

    [Header("Camera Framing")]
    public bool autoFrameCamera = true;
    public Camera targetCamera;
    [Range(20f, 80f)] public float cameraPitch = 60f;
    public float cameraPadding = 1.2f;
    public float minCameraDistance = 8f;
    public float minCameraHeight = 6f;

    // ── Interne State ─────────────────────────────────────────────────────────

    private Transform mapRoot;
    private TilePool tilePool;
    private GameObject killZone;
    private BoxCollider killZoneCollider;

    // Marker-Objekte (Goal, SpawnPoint) — separat vom Pool verwaltet
    private readonly List<GameObject> markerObjects = new List<GameObject>();

    private MapData currentMapData;
    private int currentLayoutIndex = -1;
    private Transform currentGoalTransform;

    private Vector2Int currentSpawnCell = new Vector2Int(-1, -1);
    private Vector3 currentSpawnWorldPosition = Vector3.zero;
    private Vector2Int currentGoalCell = new Vector2Int(-1, -1);
    private Vector3 currentGoalWorldPosition = Vector3.zero;

    // BFS-Pfad-Distanz von jeder begehbaren Zelle zur Goal-Zelle.
    // Lava und Hole als Wand behandeln → realistische "Wenn ich nicht springen kann"-Distanz.
    // -1 = nicht erreichbar. Wird in GenerateMap einmal berechnet und gecacht.
    private int[,] pathDistanceField;
    private int maxPathDistance = 1;

    // ── Initialisierung ───────────────────────────────────────────────────────

    private void Awake()
    {
        EnsureMapRoot();
        EnsureTilePool();
        EnsureKillZone();

        if (trainingMode == TrainingMode.Curriculum)
            CurriculumTracker.Initialize(curriculumConfig);
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
            mapRoot.localScale    = Vector3.one;
        }
    }

    private void EnsureTilePool()
    {
        if (tilePool != null) return;

        tilePool = GetComponent<TilePool>();
        if (tilePool == null)
            tilePool = gameObject.AddComponent<TilePool>();

        tilePool.Initialize(BuildPrefabMap());
    }

    private Dictionary<CellType, GameObject> BuildPrefabMap()
    {
        return new Dictionary<CellType, GameObject>
        {
            { CellType.Floor,     floorPrefab    },
            { CellType.Obstacle,  floorPrefab    }, // Obstacle nutzt Floor-Prefab
            { CellType.Goal,      floorPrefab    }, // Goal-Tile ist Floor
            { CellType.SpawnPoint,floorPrefab    }, // SpawnPoint-Tile ist Floor
            { CellType.Wall,      wallPrefab     },
            { CellType.Lava,      lavaPrefab     },
            { CellType.Hole,      holePrefab     },
            { CellType.Platform,  platformPrefab },
        };
    }

    // Persistentes KillZone-Objekt — wird pro Episode nur repositioniert, nie neu erstellt.
    private void EnsureKillZone()
    {
        if (killZone != null) return;

        killZone = new GameObject("KillZone");
        killZone.transform.SetParent(mapRoot);
        killZone.tag = "KillZone";
        killZoneCollider = killZone.AddComponent<BoxCollider>();
        killZoneCollider.isTrigger = true;
        killZone.SetActive(false);
    }

    // ── Öffentliche API ───────────────────────────────────────────────────────

    public void GenerateRuntimeMap()
    {
        SelectMapLayout();
        if (currentMapData == null) return;
        GenerateMap(currentMapData);
    }

    public void GenerateSelectedMap()
    {
        if (!TryGetLayoutByIndex(selectedLayoutIndex, out MapData selectedMap))
            return;
        currentLayoutIndex = selectedLayoutIndex;
        currentMapData     = selectedMap;
        GenerateMap(currentMapData);
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
        EnsureTilePool();
        EnsureKillZone();
        ClearMap();

        currentMapData = mapData;

        currentSpawnCell         = SelectRandomSpawnCell(mapData);
        currentSpawnWorldPosition = currentSpawnCell.x >= 0
            ? CellToWorld(currentSpawnCell) : Vector3.zero;

        currentGoalCell         = SelectRandomGoalCell(mapData, currentSpawnCell);
        currentGoalWorldPosition = currentGoalCell.x >= 0
            ? CellToWorld(currentGoalCell) + new Vector3(0f, 0.5f, 0f) : Vector3.zero;

        // Tiles aus Pool
        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType type = mapData.GetCell(x, y);
                if (type == CellType.Empty) continue;

                float yOffset = type == CellType.Platform
                    ? (mapData.cellHeightOffsets.TryGetValue(new Vector2Int(x, y), out float h) ? h : 0.75f)
                    : 0f;

                Vector3 pos = mapRoot.position + new Vector3(x * cellSize, yOffset, y * cellSize);
                tilePool.Get(type, pos, mapRoot, $"{type}_{x}_{y}");
            }
        }

        SpawnMarkers();
        RepositionKillZone();
        ComputePathDistanceField();
        FrameCameraToCurrentMap();
    }

    public void ClearMap()
    {
        EnsureMapRoot();
        EnsureTilePool();

        // Tile-Pool: alle zurückgeben (kein Destroy)
        tilePool.ReturnAll();

        // Marker-Objekte (Goal, SpawnPoint): im Editor DestroyImmediate,
        // im PlayMode deaktivieren + Destroy für nächsten Frame
        foreach (GameObject m in markerObjects)
        {
            if (m == null) continue;
            if (Application.isPlaying)
            {
                m.SetActive(false);
                Destroy(m);
            }
            else
            {
                DestroyImmediate(m);
            }
        }
        markerObjects.Clear();

        currentSpawnCell         = new Vector2Int(-1, -1);
        currentSpawnWorldPosition = Vector3.zero;
        currentGoalCell          = new Vector2Int(-1, -1);
        currentGoalWorldPosition  = Vector3.zero;
        currentGoalTransform      = null;

        if (killZone != null) killZone.SetActive(false);
    }

    public void ResetMap()   => GenerateRuntimeMap();
    public void NextLayout()
    {
        if (mapLayouts == null || mapLayouts.Length == 0) return;
        selectedLayoutIndex = (selectedLayoutIndex + 1) % mapLayouts.Length;
        GenerateSelectedMap();
    }
    public void PreviousLayout()
    {
        if (mapLayouts == null || mapLayouts.Length == 0) return;
        selectedLayoutIndex--;
        if (selectedLayoutIndex < 0) selectedLayoutIndex = mapLayouts.Length - 1;
        GenerateSelectedMap();
    }

    public Transform GetGoalTransform()  => currentGoalTransform;
    public Vector3   GetGoalPosition()   => currentGoalWorldPosition;
    public Vector3   GetSpawnPosition()
    {
        if (currentSpawnCell.x >= 0) return currentSpawnWorldPosition;
        if (currentMapData == null) return GetFallbackPosition();
        currentSpawnCell = SelectRandomSpawnCell(currentMapData);
        currentSpawnWorldPosition = currentSpawnCell.x >= 0
            ? CellToWorld(currentSpawnCell) : GetFallbackPosition();
        return currentSpawnWorldPosition;
    }

    // ── Layout-Auswahl ────────────────────────────────────────────────────────

    private void SelectMapLayout()
    {
        if (trainingMode == TrainingMode.Curriculum)
        {
            currentMapData = CurriculumTracker.GetNextLayout();
            if (currentMapData == null)
                Debug.LogError("MapGenerator: CurriculumTracker.GetNextLayout() hat null zurückgegeben!");
            return;
        }

        if (mapLayouts == null || mapLayouts.Length == 0)
        {
            Debug.LogError("MapGenerator: Keine Map-Layouts zugewiesen!");
            currentMapData = null;
            return;
        }

        switch (selectionMode)
        {
            case MapSelectionMode.Fixed:
                selectedLayoutIndex = Mathf.Clamp(selectedLayoutIndex, 0, mapLayouts.Length - 1);
                TryGetLayoutByIndex(selectedLayoutIndex, out currentMapData);
                currentLayoutIndex = selectedLayoutIndex;
                break;

            case MapSelectionMode.Sequential:
                int next = (currentLayoutIndex + 1) % mapLayouts.Length;
                if (TryGetLayoutByIndex(next, out currentMapData))
                {
                    currentLayoutIndex  = next;
                    selectedLayoutIndex = next;
                }
                break;

            default: // Random
                int rnd = GetRandomLayoutIndex();
                if (TryGetLayoutByIndex(rnd, out currentMapData))
                {
                    currentLayoutIndex  = rnd;
                    selectedLayoutIndex = rnd;
                }
                break;
        }
    }

    private int GetRandomLayoutIndex()
    {
        if (mapLayouts == null || mapLayouts.Length == 0) return -1;
        if (mapLayouts.Length == 1) return 0;
        int idx = Random.Range(0, mapLayouts.Length);
        if (avoidImmediateRepeat && currentLayoutIndex >= 0)
            while (idx == currentLayoutIndex)
                idx = Random.Range(0, mapLayouts.Length);
        return idx;
    }

    private bool TryGetLayoutByIndex(int index, out MapData mapData)
    {
        mapData = null;
        if (mapLayouts == null || mapLayouts.Length == 0)
        { Debug.LogError("MapGenerator: Keine Map-Layouts zugewiesen!"); return false; }
        if (index < 0 || index >= mapLayouts.Length)
        { Debug.LogError($"MapGenerator: Index {index} außerhalb des gültigen Bereichs!"); return false; }
        mapData = mapLayouts[index];
        if (mapData == null)
        { Debug.LogError($"MapGenerator: Layout an Index {index} ist null!"); return false; }
        if (mapData.cells == null || mapData.cells.Length != mapData.width * mapData.height)
        { Debug.LogError($"MapGenerator: Layout '{mapData.name}' hat keine gültigen cells!"); return false; }
        return true;
    }

    // ── Marker & KillZone ─────────────────────────────────────────────────────

    private void SpawnMarkers()
    {
        if (spawnPointPrefab != null && IsValidCell(currentSpawnCell))
        {
            GameObject sp = Instantiate(spawnPointPrefab, CellToWorld(currentSpawnCell),
                Quaternion.identity, mapRoot);
            sp.name = $"RuntimeSpawnPoint_{currentSpawnCell.x}_{currentSpawnCell.y}";
            markerObjects.Add(sp);
        }

        if (goalPrefab != null && IsValidCell(currentGoalCell))
        {
            GameObject gp = Instantiate(goalPrefab, currentGoalWorldPosition,
                Quaternion.identity, mapRoot);
            gp.name = $"RuntimeGoal_{currentGoalCell.x}_{currentGoalCell.y}";
            markerObjects.Add(gp);
            currentGoalTransform = gp.transform;
        }
    }

    private void RepositionKillZone()
    {
        if (currentMapData == null || killZone == null) return;

        float mapW = currentMapData.width  * cellSize;
        float mapH = currentMapData.height * cellSize;

        killZone.transform.localPosition = new Vector3(
            (mapW - cellSize) / 2f, -20f, (mapH - cellSize) / 2f);

        killZoneCollider.size   = new Vector3(mapW, 1f, mapH);
        killZoneCollider.center = Vector3.zero;
        killZone.SetActive(true);
    }

    // ── Pfad-Distanz (BFS) ────────────────────────────────────────────────────

    /// <summary>
    /// Liefert die normalisierte Pfad-Distanz (0..1) von der gegebenen Weltposition zur Goal-Zelle.
    /// Lava/Hole werden als Wand behandelt. 1 = nicht erreichbar / sehr weit.
    /// </summary>
    public float GetNormalizedPathDistance(Vector3 worldPos)
    {
        int d = GetPathDistanceCells(worldPos);
        if (d < 0 || maxPathDistance <= 0) return 1f;
        return Mathf.Clamp01((float)d / (float)maxPathDistance);
    }

    /// <summary>
    /// Roh-Distanz in Zellen. -1 = nicht erreichbar oder kein Pfad-Feld berechnet.
    /// </summary>
    public int GetPathDistanceCells(Vector3 worldPos)
    {
        if (pathDistanceField == null || currentMapData == null) return -1;
        int cx = Mathf.RoundToInt((worldPos.x - mapRoot.position.x) / cellSize);
        int cy = Mathf.RoundToInt((worldPos.z - mapRoot.position.z) / cellSize);
        if (cx < 0 || cx >= currentMapData.width || cy < 0 || cy >= currentMapData.height) return -1;
        return pathDistanceField[cx, cy];
    }

    public int MaxPathDistance => maxPathDistance;

    private void ComputePathDistanceField()
    {
        if (currentMapData == null) { pathDistanceField = null; return; }

        int W = currentMapData.width, H = currentMapData.height;
        pathDistanceField = new int[W, H];
        for (int y = 0; y < H; y++)
            for (int x = 0; x < W; x++)
                pathDistanceField[x, y] = -1;

        if (currentGoalCell.x < 0) { maxPathDistance = 1; return; }

        // BFS von Goal aus
        var queue = new System.Collections.Generic.Queue<Vector2Int>();
        pathDistanceField[currentGoalCell.x, currentGoalCell.y] = 0;
        queue.Enqueue(currentGoalCell);

        int maxD = 0;
        Vector2Int[] dirs = {
            new Vector2Int(1, 0),  new Vector2Int(-1, 0),
            new Vector2Int(0, 1),  new Vector2Int(0, -1),
        };

        while (queue.Count > 0)
        {
            Vector2Int c = queue.Dequeue();
            int cd = pathDistanceField[c.x, c.y];
            for (int i = 0; i < 4; i++)
            {
                int nx = c.x + dirs[i].x;
                int ny = c.y + dirs[i].y;
                if (nx < 0 || nx >= W || ny < 0 || ny >= H) continue;
                if (pathDistanceField[nx, ny] >= 0) continue;
                if (!IsPathable(currentMapData.GetCell(nx, ny))) continue;
                pathDistanceField[nx, ny] = cd + 1;
                if (cd + 1 > maxD) maxD = cd + 1;
                queue.Enqueue(new Vector2Int(nx, ny));
            }
        }

        maxPathDistance = Mathf.Max(1, maxD);
    }

    private static bool IsPathable(CellType t)
    {
        // Lava und Hole sind nicht überquerbar im Sinne der A*-Distanz.
        // Empty und Wall blockieren ebenfalls. Platform ist begehbar.
        return t == CellType.Floor
            || t == CellType.SpawnPoint
            || t == CellType.Goal
            || t == CellType.Obstacle
            || t == CellType.Platform;
    }

    // ── Spawn / Goal Selektion ────────────────────────────────────────────────

    private Vector2Int SelectRandomSpawnCell(MapData mapData)
    {
        if (mapData?.cells == null || mapData.cells.Length != mapData.width * mapData.height)
            return new Vector2Int(-1, -1);

        if (spawnPlacementMode == SpawnPlacementMode.PredefinedSpawnPoints)
        {
            var predefined = new List<Vector2Int>();
            for (int y = 0; y < mapData.height; y++)
                for (int x = 0; x < mapData.width; x++)
                    if (mapData.GetCell(x, y) == CellType.SpawnPoint)
                        predefined.Add(new Vector2Int(x, y));

            if (predefined.Count > 0)
                return predefined[Random.Range(0, predefined.Count)];

            Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' hat keine SpawnPoint-Zellen. Fallback.");
        }

        var valid = new List<Vector2Int>();
        for (int y = 0; y < mapData.height; y++)
            for (int x = 0; x < mapData.width; x++)
            {
                CellType t = mapData.GetCell(x, y);
                bool ok = obstaclePlacementMode == ObstaclePlacementMode.PredefinedSpawnPoints
                    ? (t == CellType.Floor || t == CellType.SpawnPoint || t == CellType.Goal)
                    : (t == CellType.Floor || t == CellType.SpawnPoint || t == CellType.Goal || t == CellType.Obstacle);
                if (ok) valid.Add(new Vector2Int(x, y));
            }

        if (valid.Count == 0)
        {
            Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' hat keine gültige Spawn-Zelle.");
            return new Vector2Int(-1, -1);
        }
        return valid[Random.Range(0, valid.Count)];
    }

    private Vector2Int SelectRandomGoalCell(MapData mapData, Vector2Int spawnCell)
    {
        if (mapData?.cells == null || mapData.cells.Length != mapData.width * mapData.height)
            return new Vector2Int(-1, -1);

        var valid    = new List<Vector2Int>();
        var fallback = new List<Vector2Int>();

        if (goalPlacementMode == GoalPlacementMode.PredefinedGoalSpawnPoints)
        {
            for (int y = 0; y < mapData.height; y++)
                for (int x = 0; x < mapData.width; x++)
                    if (mapData.GetCell(x, y) == CellType.Goal)
                    {
                        var c = new Vector2Int(x, y);
                        fallback.Add(c);
                        if (c != spawnCell) valid.Add(c);
                    }

            if (valid.Count == 0 && fallback.Count == 0)
            {
                Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' hat keine Goal-Zelle. Fallback auf Random.");
                goalPlacementMode = GoalPlacementMode.RandomGoalCells;
                return SelectRandomGoalCell(mapData, spawnCell);
            }
        }
        else
        {
            for (int y = 0; y < mapData.height; y++)
                for (int x = 0; x < mapData.width; x++)
                {
                    CellType t = mapData.GetCell(x, y);
                    bool ok = obstaclePlacementMode == ObstaclePlacementMode.PredefinedSpawnPoints
                        ? (t == CellType.Floor || t == CellType.Goal || t == CellType.SpawnPoint)
                        : (t == CellType.Floor || t == CellType.Goal || t == CellType.SpawnPoint || t == CellType.Obstacle);
                    if (ok)
                    {
                        var c = new Vector2Int(x, y);
                        fallback.Add(c);
                        if (c != spawnCell) valid.Add(c);
                    }
                }
        }

        if (valid.Count    > 0) return valid[Random.Range(0, valid.Count)];
        if (fallback.Count > 0) return fallback[Random.Range(0, fallback.Count)];

        Debug.LogWarning($"MapGenerator: Layout '{mapData.name}' hat keine gültige Goal-Zelle.");
        return new Vector2Int(-1, -1);
    }

    // ── Hilfsmethoden ─────────────────────────────────────────────────────────

    private bool IsValidCell(Vector2Int cell) => cell.x >= 0 && cell.y >= 0;

    private Vector3 CellToWorld(Vector2Int cell) =>
        mapRoot.position + new Vector3(cell.x * cellSize, 0f, cell.y * cellSize);

    private Vector3 GetFallbackPosition()
    {
        if (useCenterFallback && currentMapData != null)
            return new Vector3(
                (currentMapData.width  - 1) * cellSize * 0.5f, 0f,
                (currentMapData.height - 1) * cellSize * 0.5f);
        return Vector3.zero;
    }

    // ── Kamera-Framing ────────────────────────────────────────────────────────

    private void FrameCameraToCurrentMap()
    {
        if (!autoFrameCamera || currentMapData == null) return;

        Camera cam = targetCamera != null ? targetCamera : Camera.main;
        if (cam == null)
        {
            Debug.LogWarning("MapGenerator: Keine Kamera gefunden.");
            return;
        }

        float worldWidth  = Mathf.Max(1f, currentMapData.width  * cellSize);
        float worldHeight = Mathf.Max(1f, currentMapData.height * cellSize);
        Vector3 mapCenter = new Vector3(
            (currentMapData.width  - 1) * cellSize * 0.5f, 0f,
            (currentMapData.height - 1) * cellSize * 0.5f);

        cam.transform.rotation = Quaternion.Euler(cameraPitch, 0f, 0f);

        if (cam.orthographic)
        {
            float sizeH = worldHeight * 0.5f;
            float sizeW = worldWidth / (2f * Mathf.Max(0.01f, cam.aspect));
            cam.orthographicSize = Mathf.Max(sizeH, sizeW) * cameraPadding;
            Vector3 pos = mapCenter - cam.transform.forward * minCameraDistance;
            pos.y = Mathf.Max(minCameraHeight, pos.y);
            cam.transform.position = pos;
        }
        else
        {
            float halfV = cam.fieldOfView * 0.5f * Mathf.Deg2Rad;
            float halfH = Mathf.Atan(Mathf.Tan(halfV) * cam.aspect);
            float dH    = worldHeight * 0.5f * cameraPadding / Mathf.Tan(halfV);
            float dW    = worldWidth  * 0.5f * cameraPadding / Mathf.Tan(halfH);
            float dist  = Mathf.Max(dH, dW, minCameraDistance);
            Vector3 pos = mapCenter - cam.transform.forward * dist;
            pos.y = Mathf.Max(minCameraHeight, pos.y);
            cam.transform.position = pos;
        }

#if UNITY_EDITOR
        if (!Application.isPlaying)
            EditorUtility.SetDirty(cam);
#endif
    }
}
