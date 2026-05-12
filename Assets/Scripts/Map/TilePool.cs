using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// GameObject-Pool für Map-Tiles. Verhindert Instantiate/Destroy pro Episode.
/// Tiles werden per CellType gepoolt — beim Return deaktiviert, beim Get reaktiviert.
/// </summary>
public class TilePool : MonoBehaviour
{
    private readonly Dictionary<CellType, Queue<GameObject>> _available =
        new Dictionary<CellType, Queue<GameObject>>();

    private readonly List<(GameObject go, CellType type)> _active =
        new List<(GameObject go, CellType type)>();

    private Dictionary<CellType, GameObject> _prefabs;

    public void Initialize(Dictionary<CellType, GameObject> prefabMap)
    {
        _prefabs = prefabMap;
    }

    /// <summary>
    /// Gibt ein Tile aus dem Pool zurück (oder instanziiert es neu).
    /// Setzt Position, Parent und aktiviert das Objekt.
    /// </summary>
    public GameObject Get(CellType type, Vector3 position, Transform parent, string name = null)
    {
        if (_prefabs == null || !_prefabs.TryGetValue(type, out GameObject prefab) || prefab == null)
            return null;

        if (!_available.TryGetValue(type, out Queue<GameObject> queue))
        {
            queue = new Queue<GameObject>();
            _available[type] = queue;
        }

        GameObject go;
        if (queue.Count > 0)
        {
            go = queue.Dequeue();
            go.transform.SetParent(parent);
            go.transform.position = position;
            go.transform.rotation = Quaternion.identity;
            go.SetActive(true);
        }
        else
        {
            go = Instantiate(prefab, position, Quaternion.identity, parent);
        }

        if (name != null)
            go.name = name;

        _active.Add((go, type));
        return go;
    }

    /// <summary>
    /// Deaktiviert alle aktiven Tiles und gibt sie zurück in ihre Queues.
    /// Kein Destroy — Objekte bleiben im Speicher für die nächste Episode.
    /// </summary>
    public void ReturnAll()
    {
        foreach (var (go, type) in _active)
        {
            if (go == null) continue;
            go.SetActive(false);

            if (!_available.TryGetValue(type, out Queue<GameObject> queue))
            {
                queue = new Queue<GameObject>();
                _available[type] = queue;
            }
            queue.Enqueue(go);
        }
        _active.Clear();
    }

    /// <summary>
    /// Zerstört alle gepoolten und aktiven Objekte vollständig (z.B. bei Szenen-Wechsel).
    /// </summary>
    public void DestroyAll()
    {
        foreach (var (go, _) in _active)
            if (go != null) Destroy(go);
        _active.Clear();

        foreach (var queue in _available.Values)
            foreach (var go in queue)
                if (go != null) Destroy(go);
        _available.Clear();
    }
}
