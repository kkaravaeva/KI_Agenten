using System.Collections.Generic;
using UnityEngine;

public class MapGenerator : MonoBehaviour
{
    [Header("Map Data")]
    public MapData mapData;

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
        GenerateMap();
    }

    public void GenerateMap()
    {
        if (mapData == null)
        {
            Debug.LogError("MapGenerator: Kein MapData zugewiesen!");
            return;
        }

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
                Destroy(obj);
        }
        spawnedObjects.Clear();
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
}