using System.IO;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(MapGenerator))]
public class MapGeneratorEditor : Editor
{
    // Persistente Editor-Felder für die prozedurale Generierung
    private int    _layoutCount    = 10;
    private bool   _autoFill       = true;
    private bool   _clearExisting  = true;
    private string _outputFolder   = "Assets/Layouts/Procedural";

    private const int MAX_LAYOUTS = 1000;

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        MapGenerator generator = (MapGenerator)target;

        // ── Bestehende Buttons ────────────────────────────────────────────────
        EditorGUILayout.Space();

        if (GUILayout.Button("Generate Selected Layout"))
            generator.GenerateSelectedMap();

        if (GUILayout.Button("Generate Runtime Layout / Reset"))
            generator.ResetMap();

        if (GUILayout.Button("Previous Layout"))
            generator.PreviousLayout();

        if (GUILayout.Button("Next Layout"))
            generator.NextLayout();

        if (GUILayout.Button("Clear Preview"))
            generator.ClearMap();

        // ── Prozedurale Layout-Generierung ────────────────────────────────────
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Prozedurale Layout-Generierung", EditorStyles.boldLabel);

        _layoutCount   = EditorGUILayout.IntSlider("Anzahl Layouts", _layoutCount, 1, MAX_LAYOUTS);
        _outputFolder  = EditorGUILayout.TextField("Ausgabe-Ordner", _outputFolder);
        _clearExisting = EditorGUILayout.Toggle("Bestehende löschen", _clearExisting);
        _autoFill      = EditorGUILayout.Toggle("mapLayouts[] befüllen", _autoFill);

        EditorGUILayout.HelpBox(
            $"Generiert {_layoutCount} prozedurale Layout(s) und speichert sie als .asset-Dateien.",
            MessageType.Info);

        GUI.backgroundColor = new Color(0.6f, 0.9f, 0.6f);
        if (GUILayout.Button($"▶  {_layoutCount} Layouts generieren & speichern"))
            GenerateAndSave(generator);
        GUI.backgroundColor = Color.white;
    }

    // ── Generierungs-Logik ────────────────────────────────────────────────────

    private void GenerateAndSave(MapGenerator generator)
    {
        // Ausgabe-Ordner anlegen
        if (!AssetDatabase.IsValidFolder(_outputFolder))
        {
            string parent = Path.GetDirectoryName(_outputFolder).Replace('\\', '/');
            string folder = Path.GetFileName(_outputFolder);
            AssetDatabase.CreateFolder(parent, folder);
        }

        // Bestehende prozedurale Layouts löschen
        if (_clearExisting)
        {
            string[] existing = AssetDatabase.FindAssets("Layout_P_", new[] { _outputFolder });
            foreach (string guid in existing)
                AssetDatabase.DeleteAsset(AssetDatabase.GUIDToAssetPath(guid));
        }

        int saved    = 0;
        int failed   = 0;
        int baseSeed = Random.Range(0, 999999);

        try
        {
            for (int i = 0; i < _layoutCount; i++)
            {
                EditorUtility.DisplayProgressBar(
                    "Layouts generieren",
                    $"Layout {i + 1} / {_layoutCount}  (gespeichert: {saved}, fehlgeschlagen: {failed})",
                    (float)i / _layoutCount);

                // Kein Fallback – bei Misserfolg wird gezählt statt ein bestehendes Asset zu recyceln
                MapData layout = ProceduralLayoutGenerator.GenerateLayout(baseSeed + i * 7, null);

                if (layout == null)
                {
                    failed++;
                    continue;
                }

                string assetPath = $"{_outputFolder}/Layout_P_{saved + 1:D3}.asset";
                AssetDatabase.CreateAsset(layout, assetPath);
                saved++;
            }
        }
        finally
        {
            EditorUtility.ClearProgressBar();
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        // mapLayouts[] automatisch befüllen
        if (_autoFill && saved > 0)
            FillMapLayouts(generator);

        Debug.Log($"Prozedurale Generierung abgeschlossen: {saved} gespeichert, {failed} fehlgeschlagen.");
        EditorUtility.DisplayDialog(
            "Generierung abgeschlossen",
            $"✓ {saved} Layouts gespeichert\n" +
            (failed > 0 ? $"✗ {failed} Layouts fehlgeschlagen (zu wenig Platz im Grid)" : "") +
            (_autoFill ? "\n\nmapLayouts[] wurde aktualisiert." : ""),
            "OK");
    }

    private void FillMapLayouts(MapGenerator generator)
    {
        string[] guids  = AssetDatabase.FindAssets("Layout_P_", new[] { _outputFolder });
        var      assets = new MapData[guids.Length];

        for (int i = 0; i < guids.Length; i++)
        {
            string path = AssetDatabase.GUIDToAssetPath(guids[i]);
            assets[i] = AssetDatabase.LoadAssetAtPath<MapData>(path);
        }

        Undo.RecordObject(generator, "Fill mapLayouts with procedural assets");
        generator.mapLayouts = assets;
        EditorUtility.SetDirty(generator);
    }
}
