using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

[CustomEditor(typeof(MapData))]
public class MapDataEditor : Editor
{
    private CellType paintType = CellType.Wall;

    public override void OnInspectorGUI()
    {
        MapData data = (MapData)target;

        serializedObject.Update();

        EditorGUILayout.LabelField("Map Settings", EditorStyles.boldLabel);

        data.width = EditorGUILayout.IntField("Width", data.width);
        data.height = EditorGUILayout.IntField("Height", data.height);

        if (data.width < 1) data.width = 1;
        if (data.height < 1) data.height = 1;

        if (data.cells == null || data.cells.Length != data.width * data.height)
        {
            EditorGUILayout.HelpBox("Cells array size does not match Width x Height.", MessageType.Warning);

            if (GUILayout.Button("Resize / Init Grid"))
            {
                Undo.RecordObject(data, "Resize Grid");

                CellType[] newCells = new CellType[data.width * data.height];

                if (data.cells != null)
                {
                    int minWidth = Mathf.Min(data.width, data.cells.Length > 0 ? data.width : 0);
                    int copyCount = Mathf.Min(newCells.Length, data.cells.Length);
                    for (int i = 0; i < copyCount; i++)
                    {
                        newCells[i] = data.cells[i];
                    }
                }

                data.cells = newCells;
                EditorUtility.SetDirty(data);
            }

            serializedObject.ApplyModifiedProperties();
            return;
        }

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Paint Tool", EditorStyles.boldLabel);

        paintType = (CellType)EditorGUILayout.EnumPopup("Selected Type", paintType);

        EditorGUILayout.BeginHorizontal();

        if (GUILayout.Button("Fill All Floor"))
        {
            Undo.RecordObject(data, "Fill All Floor");
            for (int i = 0; i < data.cells.Length; i++)
                data.cells[i] = CellType.Floor;

            EditorUtility.SetDirty(data);
            RefreshPreview(data);
        }

        if (GUILayout.Button("Fill All Wall"))
        {
            Undo.RecordObject(data, "Fill All Wall");
            for (int i = 0; i < data.cells.Length; i++)
                data.cells[i] = CellType.Wall;

            EditorUtility.SetDirty(data);
            RefreshPreview(data);
        }

        EditorGUILayout.EndHorizontal();

        if (GUILayout.Button("Create Border Walls"))
        {
            Undo.RecordObject(data, "Create Border Walls");

            for (int y = 0; y < data.height; y++)
            {
                for (int x = 0; x < data.width; x++)
                {
                    bool border = x == 0 || y == 0 || x == data.width - 1 || y == data.height - 1;
                    data.SetCell(x, y, border ? CellType.Wall : CellType.Floor);
                }
            }

            EditorUtility.SetDirty(data);
            RefreshPreview(data);
        }

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Grid", EditorStyles.boldLabel);

        for (int y = data.height - 1; y >= 0; y--)
        {
            EditorGUILayout.BeginHorizontal();

            for (int x = 0; x < data.width; x++)
            {
                int index = y * data.width + x;
                CellType current = data.cells[index];

                Color oldColor = GUI.backgroundColor;
                GUI.backgroundColor = GetColor(current);

                string label = GetShortLabel(current);

                if (GUILayout.Button(label, GUILayout.Width(30), GUILayout.Height(30)))
                {
                    Undo.RecordObject(data, "Paint Cell");
                    data.SetCell(x, y, paintType);
                    EditorUtility.SetDirty(data);
                    RefreshPreview(data);
                }

                GUI.backgroundColor = oldColor;
            }

            EditorGUILayout.EndHorizontal();
        }

        serializedObject.ApplyModifiedProperties();
    }

    private void RefreshPreview(MapData data)
    {
        MapGenerator[] generators = Object.FindObjectsOfType<MapGenerator>();

        foreach (MapGenerator generator in generators)
        {
            if (generator != null)
            {
                generator.GenerateMap(data);
                EditorUtility.SetDirty(generator);
                EditorSceneManager.MarkSceneDirty(generator.gameObject.scene);
            }
        }
    }

    private string GetShortLabel(CellType type)
    {
        switch (type)
        {
            case CellType.Empty:      return "E";
            case CellType.Floor:      return "F";
            case CellType.Wall:       return "W";
            case CellType.Obstacle:   return "O";
            case CellType.Goal:       return "G";
            case CellType.SpawnPoint: return "S";
            case CellType.Lava:       return "L";
            case CellType.Hole:       return "H";
            case CellType.Platform:   return "P";
            default:                  return "?";
        }
    }

    private Color GetColor(CellType type)
    {
        switch (type)
        {
            case CellType.Empty:      return Color.gray;
            case CellType.Floor:      return Color.green;
            case CellType.Wall:       return Color.white;
            case CellType.Obstacle:   return new Color(1f, 0.6f, 0f);
            case CellType.Goal:       return Color.yellow;
            case CellType.SpawnPoint: return Color.cyan;
            case CellType.Lava:       return new Color(1f, 0.3f, 0f);
            case CellType.Hole:       return Color.black;
            case CellType.Platform:   return new Color(0.4f, 0.8f, 1f);
            default:                  return Color.magenta;
        }
    }
}