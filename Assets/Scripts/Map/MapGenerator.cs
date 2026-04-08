using System.Collections.Generic;
using UnityEngine;

public class MapGenerator : MonoBehaviour
{
    [Header("Map Layouts")]
    public MapData[] mapLayouts;

    [Header("Preview Selection")]
    public int selectedLayoutIndex = 0;

    [Header("Prefabs")]
    public GameObject floorPrefab;
    public GameObject wallPrefab;
    public GameObject[] obstaclePrefabs;
    public GameObject goalPrefab;
    public GameObject spawnPointPrefab;

    [Header("Settings")]
    public float cellSize = 1f;

    [Header("Spawn Settings")]
    [Tooltip("false = erster SpawnPoint wird verwendet, true = zufaelliger SpawnPoint")]
    public bool useRandomSpawnPoint = false;
    [Tooltip("false = Vector3.zero bei fehlendem SpawnPoint, true = Mitte der Map")]
    public bool useCenterFallback = false;

    private Transform mapRoot;
    private List<GameObject> spawnedObjects = new List<GameObject>();

    void Awake()
    {
        if (mapRoot == null)
        {
            Transform existing = transform.Find("MapRoot");
            if (existing != null)
            {
                mapRoot = existing;
            }
            else
            {
                mapRoot = new GameObject("MapRoot").transform;
                mapRoot.SetParent(this.transform);
            }
        }
    }

    void Start()
    {
        GenerateSelectedMap();
    }

    public void GenerateSelectedMap()
    {
        if (mapLayouts == null || mapLayouts.Length == 0)
        {
            Debug.LogError("MapGenerator: Keine Map-Layouts zugewiesen!");
            return;
        }

        if (selectedLayoutIndex < 0 || selectedLayoutIndex >= mapLayouts.Length)
        {
            Debug.LogError("MapGenerator: selectedLayoutIndex ist ausserhalb des gueltigen Bereichs!");
            return;
        }

        MapData selectedMap = mapLayouts[selectedLayoutIndex];

        if (selectedMap == null)
        {
            Debug.LogError("MapGenerator: Ausgewaehltes Layout ist null!");
            return;
        }

        if (selectedMap.cells == null || selectedMap.cells.Length != selectedMap.width * selectedMap.height)
        {
            Debug.LogError($"MapGenerator: Layout '{selectedMap.name}' hat keine gueltigen cells!");
            return;
        }

        GenerateMap(selectedMap);
    }

    public void GenerateMap(MapData mapData)
    {
        ClearMap();

        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType cellType = mapData.GetCell(x, y);
                GameObject prefab = GetPrefabForCell(cellType);

                if (prefab == null) continue;

                Vector3 position = new Vector3(x * cellSize, 0, y * cellSize);
                GameObject instance = Instantiate(prefab, position, Quaternion.identity, mapRoot);
                instance.name = $"{cellType}_{x}_{y}";
                spawnedObjects.Add(instance);
            }
        }
    }

    public void ClearMap()
    {
        foreach (var obj in spawnedObjects)
        {
            if (obj != null)
                DestroyImmediate(obj);
        }

        spawnedObjects.Clear();
    }

    public void ResetMap()
    {
        ClearMap();
        GenerateSelectedMap();
    }

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
                if (obstaclePrefabs == null || obstaclePrefabs.Length == 0) return null;
                return obstaclePrefabs[0];
            case CellType.Goal:
                return goalPrefab;
            case CellType.SpawnPoint:
                return spawnPointPrefab;
            default:
                return null;
        }
    }

    public Vector3 GetSpawnPosition()
    {
        if (mapLayouts == null || selectedLayoutIndex < 0 || selectedLayoutIndex >= mapLayouts.Length)
        {
            Debug.LogWarning("MapGenerator: Kein aktuelles Map-Layout ausgewaehlt!");
            return Vector3.zero;
        }

        MapData selectedMap = mapLayouts[selectedLayoutIndex];

        if (selectedMap == null)
        {
            Debug.LogWarning("MapGenerator: Kein aktuelles Map-Layout ausgewaehlt!");
            return Vector3.zero;
        }

        if (selectedMap.cells == null || selectedMap.cells.Length != selectedMap.width * selectedMap.height)
        {
            selectedMap.Init();
        }

        // Alle SpawnPoints sammeln
        List<Vector3> spawnPositions = new List<Vector3>();

        for (int y = 0; y < selectedMap.height; y++)
        {
            for (int x = 0; x < selectedMap.width; x++)
            {
                if (selectedMap.GetCell(x, y) == CellType.SpawnPoint)
                {
                    spawnPositions.Add(new Vector3(x * cellSize, 0f, y * cellSize));
                }
            }
        }

        // SpawnPoint(s) gefunden
        if (spawnPositions.Count > 0)
        {
            if (useRandomSpawnPoint)
            {
                return spawnPositions[Random.Range(0, spawnPositions.Count)];
            }
            else
            {
                return spawnPositions[0];
            }
        }

        // Kein SpawnPoint gefunden — Fallback
        Debug.LogWarning($"MapGenerator: Kein SpawnPoint in Layout '{selectedMap.name}' definiert!");

        if (useCenterFallback)
        {
            float centerX = (selectedMap.width - 1) * cellSize * 0.5f;
            float centerZ = (selectedMap.height - 1) * cellSize * 0.5f;
            return new Vector3(centerX, 0f, centerZ);
        }

        return Vector3.zero;
    }
}