using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

// V16 Fix F: Generiert Layout-Assets für die neue Phase TrivialJumpWarmup.
// Menü: Tools → V16 → Generate JumpWarmup Layouts.
// Ergebnis:
//   1) 80 .asset-Dateien unter Assets/Layouts/Procedural/Layout_P_TrivialJumpWarmup_NNN.asset
//   2) Phase mit difficulty=TrivialJumpWarmup in allen CurriculumConfig-Assets bekommt diese Layouts zugewiesen.
public static class JumpWarmupLayoutGenerator
{
    private const string TargetDir = "Assets/Layouts/Procedural";
    private const string Prefix    = "Layout_P_TrivialJumpWarmup_";
    private const int    Count     = 80;
    private const int    SeedBase  = 16000;  // Eigener Seed-Bereich (kein Konflikt mit anderen Phasen)

    [MenuItem("Tools/V16/Generate JumpWarmup Layouts")]
    public static void Generate()
    {
        if (!AssetDatabase.IsValidFolder(TargetDir))
        {
            Debug.LogError($"JumpWarmupLayoutGenerator: Ordner '{TargetDir}' nicht gefunden.");
            return;
        }

        var generatedAssets = new List<MapData>();

        AssetDatabase.StartAssetEditing();
        int created = 0, skipped = 0;
        try
        {
            for (int i = 1; i <= Count; i++)
            {
                string assetPath = $"{TargetDir}/{Prefix}{i:D3}.asset";

                // Wenn bereits vorhanden: überschreiben (für wiederholbare Generierung).
                MapData existing = AssetDatabase.LoadAssetAtPath<MapData>(assetPath);
                MapData generated = ProceduralLayoutGenerator.GenerateLayout(
                    SeedBase + i,
                    DifficultyLevel.TrivialJumpWarmup);

                if (generated == null)
                {
                    Debug.LogWarning($"JumpWarmupLayoutGenerator: Seed {SeedBase + i} hat null produziert.");
                    skipped++;
                    continue;
                }
                generated.name = $"{Prefix}{i:D3}";

                MapData saved;
                if (existing != null)
                {
                    existing.width  = generated.width;
                    existing.height = generated.height;
                    existing.cells  = generated.cells;
                    EditorUtility.SetDirty(existing);
                    Object.DestroyImmediate(generated);
                    saved = existing;
                }
                else
                {
                    AssetDatabase.CreateAsset(generated, assetPath);
                    saved = generated;
                }
                generatedAssets.Add(saved);
                created++;
            }
        }
        finally
        {
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }

        Debug.Log($"[V16 JumpWarmup] {created} Layouts erzeugt/überschrieben, {skipped} übersprungen.");

        // Phasen in allen CurriculumConfigs aktualisieren (Phase mit difficulty=TrivialJumpWarmup).
        int updatedConfigs = AssignLayoutsToCurriculumConfigs(generatedAssets);
        Debug.Log($"[V16 JumpWarmup] {updatedConfigs} CurriculumConfig(s) mit Layouts befüllt.");
    }

    private static int AssignLayoutsToCurriculumConfigs(List<MapData> layouts)
    {
        if (layouts == null || layouts.Count == 0) return 0;

        string[] guids = AssetDatabase.FindAssets("t:CurriculumConfig");
        int updated = 0;
        foreach (string guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            CurriculumConfig cfg = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(path);
            if (cfg == null || cfg.phases == null) continue;

            bool changed = false;
            for (int p = 0; p < cfg.phases.Length; p++)
            {
                if (cfg.phases[p].difficulty != DifficultyLevel.TrivialJumpWarmup) continue;
                cfg.phases[p].layouts = layouts.ToArray();
                changed = true;
            }
            if (changed)
            {
                EditorUtility.SetDirty(cfg);
                updated++;
            }
        }
        AssetDatabase.SaveAssets();
        return updated;
    }
}
