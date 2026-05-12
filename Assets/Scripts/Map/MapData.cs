using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "MapData", menuName = "Map/MapData")]
public class MapData : ScriptableObject
{
    public int width = 10;
    public int height = 10;
    public CellType[] cells;

    // Höhen-Offsets für Zellen die nicht auf Y=0 liegen (z.B. Platform).
    // Wird nur zur Laufzeit befüllt und nicht serialisiert.
    [System.NonSerialized]
    public Dictionary<Vector2Int, float> cellHeightOffsets = new Dictionary<Vector2Int, float>();

    // Wenn true, überspringt MapGenerator die Runtime-Obstacle-Platzierung.
    // Wird von GenerateTrivialLayout gesetzt.
    [System.NonSerialized]
    public bool noRuntimeObstacles = false;

    public void Init()
    {
        cells = new CellType[width * height];
        cellHeightOffsets = new Dictionary<Vector2Int, float>();
    }

   public CellType GetCell(int x, int y)
{
    if (cells == null || cells.Length != width * height)
    {
        Debug.LogError($"MapData ist nicht korrekt initialisiert. Erwartet: {width * height}, Tatsächlich: {(cells == null ? 0 : cells.Length)}");
        return CellType.Empty;
    }

    return cells[y * width + x];
}

    public void SetCell(int x, int y, CellType type)
    {
        cells[y * width + x] = type;
    }
}