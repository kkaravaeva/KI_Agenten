using System.Collections.Generic;
using UnityEngine;

public class MapGenerator : MonoBehaviour
{
    [Header("Map Data")]
    public MapData[] availableMaps;
    private MapData currentMapData;
    [Header("Prefabs")]
    public GameObject floorPrefab;
    public GameObject wallPrefab;
    public GameObject[] obstaclePrefabs;
    public GameObject goalPrefab;
    public GameObject spawnPointPrefab;

    [Header("Settings")]
    public float cellSize = 1f;

    private Transform mapRoot;
    private List<GameObject> spawnedObjects = new List<GameObject>();

    void Awake()
    {
        mapRoot = new GameObject("MapRoot").transform;
        mapRoot.SetParent(this.transform);
    }

    void Start()
    {
        SelectMapLayout();
        GenerateMap();
    }

    public void GenerateMap()
    {
        if (currentMapData == null)
        {
            Debug.LogError("MapGenerator: Kein aktuelles Map-Layout ausgewählt!");
            return;
        }

        if (currentMapData.cells == null || currentMapData.cells.Length != currentMapData.width * currentMapData.height)
        {
            currentMapData.Init();
        }

        ClearMap();

        for (int y = 0; y < currentMapData.height; y++)
        {
            for (int x = 0; x < currentMapData.width; x++)
            {
                CellType cellType = currentMapData.GetCell(x, y);
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
                Destroy(obj);
        }
        spawnedObjects.Clear();
    }
    public void ResetMap()
    {
        ClearMap();
        GenerateMap();
    }

    //Diese Methode dient nur zum manuellen Testen des Resets per Tastendruck
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            ResetMap();
            Debug.Log("ResetMap wird aufgerufen");
        }
    }
    private GameObject GetPrefabForCell(CellType type)
    {
        switch (type)
        {
            case CellType.Floor: return floorPrefab;
            case CellType.Wall: return wallPrefab;
            case CellType.Obstacle:
                if (obstaclePrefabs == null || obstaclePrefabs.Length == 0) return null;
                return obstaclePrefabs[Random.Range(0, obstaclePrefabs.Length)];
            case CellType.Goal: return goalPrefab;
            case CellType.SpawnPoint: return spawnPointPrefab;
            default: return null;
        }
    }
  
    public Vector3 GetSpawnPosition()
    {
        if (currentMapData == null)
        {
            Debug.LogWarning("Kein aktuelles Map-Layout ausgewählt!");
            return Vector3.zero;
        }
        if (currentMapData.cells == null || currentMapData.cells.Length != currentMapData.width * currentMapData.height)
        {
            currentMapData.Init();
        }
        for (int y = 0; y < currentMapData.height; y++)
        {
            for (int x = 0; x < currentMapData.width; x++)
            {
                if (currentMapData.GetCell(x, y) == CellType.SpawnPoint)
                {
                    return new Vector3(x * cellSize, 0f, y * cellSize);
                }
            }
        }

        Debug.LogWarning("Kein SpawnPoint definiert!");
        return Vector3.zero;
    }
    private void SelectMapLayout()
    {
        if (availableMaps == null || availableMaps.Length == 0)
        {
            Debug.LogError("MapGenerator: Keine Map-Layouts im Inspector zugewiesen!");
            currentMapData = null;
            return;
        }

        if (availableMaps[0] == null)
        {
            Debug.LogError("MapGenerator: Das erste Map-Layout ist null!");
            currentMapData = null;
            return;
        }

        currentMapData = availableMaps[0];
    }
}