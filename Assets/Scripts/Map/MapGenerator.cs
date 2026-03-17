using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
#endif

[ExecuteAlways]
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

    [Header("Editor Preview")]
    public bool previewInEditMode = true;
    public bool ignoreDynamicElements = true;

    private Transform mapRoot;
    private readonly List<GameObject> spawnedObjects = new List<GameObject>();

    private void Awake()
    {
        EnsureMapRoot();
    }

    private void OnEnable()
    {
        EnsureMapRoot();

    }

    #if UNITY_EDITOR
    private void OnValidate()
    {
        if (selectedLayoutIndex < 0)
            selectedLayoutIndex = 0;

        if (cellSize < 0.01f)
            cellSize = 0.01f;
    }
    #endif

    private void EnsureMapRoot()
    {
        if (mapRoot != null) return;

        Transform existing = transform.Find("MapRoot");
        if (existing != null)
        {
            mapRoot = existing;
            CacheExistingChildren();
            return;
        }

        GameObject root = new GameObject("MapRoot");
        root.transform.SetParent(transform);
        root.transform.localPosition = Vector3.zero;
        root.transform.localRotation = Quaternion.identity;
        root.transform.localScale = Vector3.one;
        mapRoot = root.transform;
    }

    private void CacheExistingChildren()
    {
        spawnedObjects.Clear();

        if (mapRoot == null) return;

        foreach (Transform child in mapRoot)
        {
            if (child != null)
            {
                spawnedObjects.Add(child.gameObject);
            }
        }
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
            Debug.LogError("MapGenerator: selectedLayoutIndex ist außerhalb des gültigen Bereichs!");
            return;
        }

        MapData selectedMap = mapLayouts[selectedLayoutIndex];

        if (selectedMap == null)
        {
            Debug.LogError("MapGenerator: Ausgewähltes Layout ist null!");
            return;
        }

        if (selectedMap.cells == null || selectedMap.cells.Length != selectedMap.width * selectedMap.height)
        {
            Debug.LogError($"MapGenerator: Layout '{selectedMap.name}' hat keine gültigen cells!");
            return;
        }

        MapData runtimeMap = selectedMap;

        if (Application.isPlaying)
        {
            runtimeMap = Instantiate(selectedMap);
        }

        GenerateMap(selectedMap);
    }

    public void GenerateMap(MapData mapData)
    {
        EnsureMapRoot();

        if (mapData == null)
        {
            Debug.LogError("MapGenerator: mapData ist null!");
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

                Vector3 position = new Vector3(x * cellSize, 0f, y * cellSize);
                GameObject instance;

#if UNITY_EDITOR
                if (!Application.isPlaying)
                {
                    instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab, mapRoot);
                    if (instance == null)
                    {
                        instance = Instantiate(prefab, mapRoot);
                    }
                }
                else
                {
                    instance = Instantiate(prefab, mapRoot);
                }
#else
                instance = Instantiate(prefab, mapRoot);
#endif

                instance.transform.localPosition = position;
                instance.transform.localRotation = Quaternion.identity;
                instance.name = $"{cellType}_{x}_{y}";
                spawnedObjects.Add(instance);
            }
        }

#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            EditorSceneManager.MarkSceneDirty(gameObject.scene);
        }
#endif
    }

    public void ClearMap()
    {
        EnsureMapRoot();
        CacheExistingChildren();

        for (int i = spawnedObjects.Count - 1; i >= 0; i--)
        {
            GameObject obj = spawnedObjects[i];
            if (obj == null) continue;

#if UNITY_EDITOR
            if (!Application.isPlaying)
            {
                DestroyImmediate(obj);
            }
            else
            {
                Destroy(obj);
            }
#else
            Destroy(obj);
#endif
        }

        spawnedObjects.Clear();

#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            EditorSceneManager.MarkSceneDirty(gameObject.scene);
        }
#endif
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
            case CellType.Goal:
            case CellType.SpawnPoint:
                if (ignoreDynamicElements)
                    return null;
                break;
        }

        switch (type)
        {
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
}