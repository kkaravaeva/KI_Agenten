using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(MapGenerator))]
public class MapGeneratorEditor : Editor
{
    // Batch-Generierung
    private int    _layoutCount   = 10;
    private bool   _autoFill      = true;
    private bool   _clearExisting = true;
    private string _outputFolder  = "Assets/Layouts/Procedural";

    private DifficultyLevel _selectedDiff = DifficultyLevel.Easy;

    // Laden / Entladen
    private DifficultyMask _loadFilter   = DifficultyMask.All;
    private DifficultyMask _unloadFilter = DifficultyMask.All;

    private const int MAX_LAYOUTS = 1000;

    [System.Flags]
    private enum DifficultyMask
    {
        None                 = 0,
        Trivial              = 1 << 0,
        TrivialCorr          = 1 << 1,
        TrivialBranch        = 1 << 2,
        TrivialHole          = 1 << 3,
        TrivialHazard        = 1 << 4,
        Easy                 = 1 << 5,
        Medium               = 1 << 6,
        Hard                 = 1 << 7,
        TrivialLavaSurround  = 1 << 8,
        TrivialLavaCrossable = 1 << 9,
        TrivialLavaWide      = 1 << 10,
        TrivialJumpWarmup    = 1 << 11,
        All                  = ~0
    }

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

        // Schwierigkeit aus dem MapGenerator-Feld lesen — wird im DefaultInspector angezeigt,
        // aber wir brauchen es auch hier für den Generator-Button
        _selectedDiff = (DifficultyLevel)EditorGUILayout.EnumPopup(
            "Schwierigkeit", _selectedDiff);

        _layoutCount   = EditorGUILayout.IntSlider("Anzahl Layouts", _layoutCount, 1, MAX_LAYOUTS);
        _outputFolder  = EditorGUILayout.TextField("Ausgabe-Ordner", _outputFolder);
        _clearExisting = EditorGUILayout.Toggle("Bestehende löschen", _clearExisting);
        _autoFill      = EditorGUILayout.Toggle("mapLayouts[] befüllen", _autoFill);

        EditorGUILayout.HelpBox(
            $"Generiert {_layoutCount} Layout(s) der Schwierigkeit '{_selectedDiff}' " +
            $"und speichert sie als .asset-Dateien.",
            MessageType.Info);

        GUI.backgroundColor = new Color(0.6f, 0.9f, 0.6f);
        if (GUILayout.Button($"▶  {_layoutCount} Layouts generieren & speichern"))
            GenerateAndSave(generator, _selectedDiff);
        GUI.backgroundColor = Color.white;

        // ── Procedural Layouts laden ──────────────────────────────────────────
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Procedural Layouts laden", EditorStyles.boldLabel);

        _loadFilter = (DifficultyMask)EditorGUILayout.EnumFlagsField("Schwierigkeiten laden", _loadFilter);

        int loadCount = CountMatchingAssets(_outputFolder, _loadFilter);
        EditorGUILayout.HelpBox(
            $"{loadCount} passende Layout(s) in \"{_outputFolder}\" gefunden.\n" +
            "Vorhandene Einträge der gewählten Schwierigkeiten in mapLayouts[] werden ersetzt.",
            MessageType.Info);

        GUI.backgroundColor = new Color(0.6f, 0.8f, 1f);
        if (GUILayout.Button("↻  Layouts in mapLayouts[] laden"))
        {
            if (_loadFilter == DifficultyMask.None)
            {
                EditorUtility.DisplayDialog("Keine Schwierigkeit gewählt",
                    "Bitte mindestens eine Schwierigkeit auswählen.", "OK");
            }
            else if (!AssetDatabase.IsValidFolder(_outputFolder))
            {
                EditorUtility.DisplayDialog("Ordner nicht gefunden",
                    $"Der Ordner \"{_outputFolder}\" existiert nicht.", "OK");
            }
            else
            {
                LoadProceduralLayouts(generator, _outputFolder, _loadFilter,
                    "Load procedural layouts into mapLayouts");
            }
        }
        GUI.backgroundColor = Color.white;

        // ── Procedural Layouts entladen ───────────────────────────────────────
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Procedural Layouts entladen", EditorStyles.boldLabel);

        _unloadFilter = (DifficultyMask)EditorGUILayout.EnumFlagsField("Schwierigkeiten entladen", _unloadFilter);

        int unloadCount = CountLoadedMatchingLayouts(generator, _unloadFilter);
        EditorGUILayout.HelpBox(
            $"{unloadCount} Layout(s) der gewählten Schwierigkeit(en) aktuell in mapLayouts[].",
            MessageType.Info);

        GUI.backgroundColor = new Color(1f, 0.75f, 0.6f);
        if (GUILayout.Button("✕  Layouts aus mapLayouts[] entladen"))
        {
            if (_unloadFilter == DifficultyMask.None)
            {
                EditorUtility.DisplayDialog("Keine Schwierigkeit gewählt",
                    "Bitte mindestens eine Schwierigkeit auswählen.", "OK");
            }
            else
            {
                UnloadDifficulties(generator, _unloadFilter, "Unload procedural layouts from mapLayouts");
            }
        }
        GUI.backgroundColor = Color.white;
    }

    // ── Generierungs-Logik ────────────────────────────────────────────────────

    private void GenerateAndSave(MapGenerator generator, DifficultyLevel difficulty)
    {
        string diffName = difficulty.ToString();
        string prefix   = $"Layout_P_{diffName}_";

        if (!AssetDatabase.IsValidFolder(_outputFolder))
        {
            string parent = Path.GetDirectoryName(_outputFolder).Replace('\\', '/');
            string folder = Path.GetFileName(_outputFolder);
            AssetDatabase.CreateFolder(parent, folder);
        }

        if (_clearExisting)
        {
            string[] existing = AssetDatabase.FindAssets(prefix, new[] { _outputFolder });
            foreach (string guid in existing)
                AssetDatabase.DeleteAsset(AssetDatabase.GUIDToAssetPath(guid));
        }

        int existingCount = _clearExisting ? 0
            : AssetDatabase.FindAssets(prefix, new[] { _outputFolder }).Length;

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

                MapData layout = ProceduralLayoutGenerator.GenerateLayout(
                    baseSeed + i * 7, difficulty, null);

                if (layout == null) { failed++; continue; }

                string assetPath = $"{_outputFolder}/{prefix}{existingCount + saved + 1:D3}.asset";
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

        if (_autoFill && saved > 0)
        {
            DifficultyMask mask = DifficultyToMask(difficulty);
            LoadProceduralLayouts(generator, _outputFolder, mask,
                "Fill mapLayouts with procedural assets");
        }

        Debug.Log($"Prozedurale Generierung abgeschlossen: {saved} gespeichert, {failed} fehlgeschlagen.");
        EditorUtility.DisplayDialog(
            "Generierung abgeschlossen",
            $"✓ {saved} Layouts gespeichert\n" +
            (failed > 0 ? $"✗ {failed} Layouts fehlgeschlagen\n" : "") +
            (_autoFill ? "\nmapLayouts[] wurde aktualisiert." : ""),
            "OK");
    }

    // ── Laden ─────────────────────────────────────────────────────────────────

    private void LoadProceduralLayouts(MapGenerator generator, string folder,
                                        DifficultyMask filter, string undoLabel)
    {
        var newPaths = new List<string>();
        foreach (DifficultyLevel diff in System.Enum.GetValues(typeof(DifficultyLevel)))
        {
            if (!FilterContains(filter, diff)) continue;
            string prefix  = $"Layout_P_{diff}_";
            string[] guids = AssetDatabase.FindAssets(prefix, new[] { folder });
            foreach (string guid in guids)
                newPaths.Add(AssetDatabase.GUIDToAssetPath(guid));
        }
        newPaths.Sort(CompareDifficultyThenName);

        var merged = new List<MapData>();
        if (generator.mapLayouts != null)
            foreach (MapData m in generator.mapLayouts)
                if (m != null && !IsMatchingFilter(m.name, filter))
                    merged.Add(m);

        foreach (string path in newPaths)
        {
            MapData asset = AssetDatabase.LoadAssetAtPath<MapData>(path);
            if (asset != null) merged.Add(asset);
        }

        merged.Sort((a, b) => CompareDifficultyThenName(a?.name, b?.name));

        Undo.RecordObject(generator, undoLabel);
        generator.mapLayouts = merged.ToArray();
        EditorUtility.SetDirty(generator);

        Debug.Log($"mapLayouts[]: {merged.Count} Layout(s) geladen (Filter: {filter}).");
    }

    // ── Entladen ──────────────────────────────────────────────────────────────

    private void UnloadDifficulties(MapGenerator generator, DifficultyMask filter, string undoLabel)
    {
        if (generator.mapLayouts == null || generator.mapLayouts.Length == 0)
        {
            EditorUtility.DisplayDialog("Nichts zu entladen", "mapLayouts[] ist bereits leer.", "OK");
            return;
        }

        var remaining = new List<MapData>();
        int removed   = 0;
        foreach (MapData m in generator.mapLayouts)
        {
            if (m != null && IsMatchingFilter(m.name, filter)) removed++;
            else remaining.Add(m);
        }

        Undo.RecordObject(generator, undoLabel);
        generator.mapLayouts = remaining.ToArray();
        EditorUtility.SetDirty(generator);

        Debug.Log($"mapLayouts[]: {removed} Layout(s) entladen. Verbleibend: {remaining.Count}.");
    }

    // ── Hilfsmethoden ─────────────────────────────────────────────────────────

    private static bool FilterContains(DifficultyMask filter, DifficultyLevel diff)
        => (filter & DifficultyToMask(diff)) != 0;

    private static DifficultyMask DifficultyToMask(DifficultyLevel diff)
    {
        switch (diff)
        {
            case DifficultyLevel.Trivial:              return DifficultyMask.Trivial;
            case DifficultyLevel.TrivialCorr:          return DifficultyMask.TrivialCorr;
            case DifficultyLevel.TrivialBranch:        return DifficultyMask.TrivialBranch;
            case DifficultyLevel.TrivialHole:          return DifficultyMask.TrivialHole;
            case DifficultyLevel.TrivialHazard:        return DifficultyMask.TrivialHazard;
            case DifficultyLevel.TrivialLavaSurround:  return DifficultyMask.TrivialLavaSurround;
            case DifficultyLevel.TrivialLavaCrossable: return DifficultyMask.TrivialLavaCrossable;
            case DifficultyLevel.TrivialLavaWide:      return DifficultyMask.TrivialLavaWide;
            case DifficultyLevel.TrivialJumpWarmup:    return DifficultyMask.TrivialJumpWarmup;
            case DifficultyLevel.Easy:                 return DifficultyMask.Easy;
            case DifficultyLevel.Medium:               return DifficultyMask.Medium;
            default:                                   return DifficultyMask.Hard;
        }
    }

    private static bool IsMatchingFilter(string assetName, DifficultyMask filter)
    {
        foreach (DifficultyLevel diff in System.Enum.GetValues(typeof(DifficultyLevel)))
            if (FilterContains(filter, diff) && assetName.Contains($"Layout_P_{diff}_"))
                return true;
        return false;
    }

    private int CountMatchingAssets(string folder, DifficultyMask filter)
    {
        if (!AssetDatabase.IsValidFolder(folder)) return 0;
        int count = 0;
        foreach (DifficultyLevel diff in System.Enum.GetValues(typeof(DifficultyLevel)))
            if (FilterContains(filter, diff))
                count += AssetDatabase.FindAssets($"Layout_P_{diff}_", new[] { folder }).Length;
        return count;
    }

    private static int CountLoadedMatchingLayouts(MapGenerator generator, DifficultyMask filter)
    {
        if (generator.mapLayouts == null) return 0;
        int count = 0;
        foreach (MapData m in generator.mapLayouts)
            if (m != null && IsMatchingFilter(m.name, filter)) count++;
        return count;
    }

    private static int DifficultyOrder(string name)
    {
        if (name == null) return int.MaxValue;
        // Logische Reihenfolge (Trivial → Lava-Sub-Phasen → Hazard → Easy/Medium/Hard).
        // Achtung: die TrivialLava*-Strings müssen vor TrivialHazard geprüft werden,
        // sonst würde "TrivialLavaSurround" durch keinen Test gefangen, da es kein
        // Substring von "_Hazard_" ist — aber Reihenfolge spielt für Korrektheit eine Rolle, wenn ein Name mehrere Suffixe enthält.
        if (name.Contains("_Trivial_"))              return 0;
        if (name.Contains("_TrivialCorr_"))          return 1;
        if (name.Contains("_TrivialBranch_"))        return 2;
        if (name.Contains("_TrivialHole_"))          return 3;
        if (name.Contains("_TrivialJumpWarmup_"))    return 4;
        if (name.Contains("_TrivialLavaSurround_"))  return 5;
        if (name.Contains("_TrivialLavaCrossable_")) return 6;
        if (name.Contains("_TrivialLavaWide_"))      return 7;
        if (name.Contains("_TrivialHazard_"))        return 8;
        if (name.Contains("_Easy_"))                 return 9;
        if (name.Contains("_Medium_"))               return 10;
        if (name.Contains("_Hard_"))                 return 11;
        return 12;
    }

    private static int CompareDifficultyThenName(string a, string b)
    {
        int diff = DifficultyOrder(a).CompareTo(DifficultyOrder(b));
        return diff != 0 ? diff
            : string.Compare(a, b, System.StringComparison.OrdinalIgnoreCase);
    }
}
