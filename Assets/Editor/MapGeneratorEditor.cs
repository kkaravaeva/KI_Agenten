using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(MapGenerator))]
public class MapGeneratorEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        MapGenerator generator = (MapGenerator)target;

        EditorGUILayout.Space();

        if (GUILayout.Button("Generate Selected Layout"))
        {
            generator.GenerateSelectedMap();
        }

        if (GUILayout.Button("Generate Runtime Layout / Reset"))
        {
            generator.ResetMap();
        }

        if (GUILayout.Button("Previous Layout"))
        {
            generator.PreviousLayout();
        }

        if (GUILayout.Button("Next Layout"))
        {
            generator.NextLayout();
        }

        if (GUILayout.Button("Clear Preview"))
        {
            generator.ClearMap();
        }
    }
}
