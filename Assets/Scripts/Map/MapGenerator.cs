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

    [Header("Map Settings")]
    public float cellSize = 1f;

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
        if (mapRoot != null)
            return;

        Transform existing = transform.Find("MapRoot");
        if (existing != null)
        {
            mapRoot = existing;
            return;
        }

        GameObject root = new GameObject("MapRoot");
        mapRoot = root.transform;
        mapRoot.SetParent(transform);
        mapRoot.localPosition = Vector3.zero;
        mapRoot.localRotation = Quaternion.identity;
        mapRoot.localScale = Vector3.one;
    }

    public void GenerateRuntimeMap()
    {
        ResetMap();
    }

    public void GenerateSelectedMap()
    {
        if (!TryGetLayoutByIndex(selectedLayoutIndex, out MapData selectedMap))
            return;

        currentLayoutIndex = selectedLayoutIndex;
        currentMapData = selectedMap;

        GenerateMap(currentMapData);
    }

    public void ResetMap()
    {
        EnsureMapRoot();

        // 1) Entfernen aller bestehenden Map-Objekte unter dem MapRoot
        ClearMap();

        // 2) Auswahl eines Layouts aus der Layout-Sammlung
        SelectMapLayout();

        if (currentMapData == null)
            return;

        // 3) Generierung der Map auf Basis dieses Layouts
        BuildMap(currentMapData);
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
        BuildMap(mapData);
    }

    private void BuildMap(MapData mapData)
    {
        for (int y = 0; y < mapData.height; y++)
        {
            for (int x = 0; x < mapData.width; x++)
            {
                CellType cellType = mapData.GetCell(x, y);
                GameObject prefab = GetPrefabForCell(cellType);

                if (prefab == null)
                    continue;

                Vector3 position = new Vector3(x * cellSize, 0f, y * cellSize);
                GameObject instance = Instantiate(prefab, position, Quaternion.identity, mapRoot);
                instance.name = $"{cellType}_{x}_{y}";
                spawnedObjects.Add(instance);
            }
        }

        FrameCameraToCurrentMap();
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
                if (obstaclePrefabs == null || obstaclePrefabs.Length == 0)
                    return null;
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
        if (currentMapData == null)
        {
            Debug.LogWarning("MapGenerator: Kein aktuelles Map-Layout ausgewählt!");
            return Vector3.zero;
        }

        if (currentMapData.cells == null || currentMapData.cells.Length != currentMapData.width * currentMapData.height)
        {
            Debug.LogWarning("MapGenerator: currentMapData hat keine gültigen cells.");
            return Vector3.zero;
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

        for (int y = 0; y < currentMapData.height; y++)
        {
            for (int x = 0; x < currentMapData.width; x++)
            {
                if (currentMapData.GetCell(x, y) == CellType.Floor)
                {
                    return new Vector3(x * cellSize, 0f, y * cellSize);
                }
            }
        }

        Debug.LogWarning("MapGenerator: Kein SpawnPoint und keine Floor-Zelle gefunden!");
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
