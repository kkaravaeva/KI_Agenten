using UnityEngine;

[CreateAssetMenu(fileName = "MapData", menuName = "Map/MapData")]
public class MapData : ScriptableObject
{
    public int width = 10;
    public int height = 10;
    public CellType[] cells;

    public void Init()
    {
        cells = new CellType[width * height];
    }

    public CellType GetCell(int x, int y)
    {
        return cells[y * width + x];
    }

    public void SetCell(int x, int y, CellType type)
    {
        cells[y * width + x] = type;
    }
}