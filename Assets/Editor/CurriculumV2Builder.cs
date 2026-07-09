using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Baut das Curriculum für den zweiten finalen Vergleichslauf (model_comparison_final_v2):
/// generiert fehlende TrivialHole-/TrivialHazard-Layouts und schreibt die 8-Phasen-
/// Struktur (mit Gates und Loop ab Easy) in CurriculumConfig_Default.asset.
/// Batchmode-tauglich: Unity.exe -batchmode -executeMethod CurriculumV2Builder.BuildAll -quit
/// </summary>
public static class CurriculumV2Builder
{
    private const string LayoutFolder = "Assets/Layouts/Procedural";
    private const string ConfigPath   = "Assets/CurriculumConfig_Default.asset";
    private const int    NewLayoutCount = 150;

    [MenuItem("Training/Curriculum v2 bauen (Hole+Hazard+Gates)")]
    public static void BuildAll()
    {
        GenerateLayoutsIfMissing(DifficultyLevel.TrivialHole,   NewLayoutCount);
        GenerateLayoutsIfMissing(DifficultyLevel.TrivialHazard, NewLayoutCount);
        RebuildConfig();
        AssetDatabase.SaveAssets();
        Debug.Log("[CurriculumV2Builder] Fertig.");
    }

    private static void GenerateLayoutsIfMissing(DifficultyLevel difficulty, int count)
    {
        string prefix   = $"Layout_P_{difficulty}_";
        int    existing = FindLayouts(difficulty).Count;
        if (existing >= count)
        {
            Debug.Log($"[CurriculumV2Builder] {difficulty}: {existing} Layouts vorhanden, keine Generierung nötig.");
            return;
        }

        int baseSeed = 42000 + (int)difficulty * 1000; // deterministisch, reproduzierbar
        int saved = 0, failed = 0;
        for (int i = existing; i < count; i++)
        {
            MapData layout = ProceduralLayoutGenerator.GenerateLayout(baseSeed + i * 7, difficulty, null);
            if (layout == null) { failed++; continue; }
            AssetDatabase.CreateAsset(layout, $"{LayoutFolder}/{prefix}{i + 1:D3}.asset");
            saved++;
        }
        AssetDatabase.SaveAssets();
        Debug.Log($"[CurriculumV2Builder] {difficulty}: {saved} Layouts generiert ({failed} fehlgeschlagen).");
    }

    private static List<MapData> FindLayouts(DifficultyLevel difficulty)
    {
        // TrivialLava-Layouts stammen aus dem LavaMapGenerator und liegen mit
        // eigenem Namensschema in einem eigenen Ordner.
        string folder = difficulty == DifficultyLevel.TrivialLava ? "Assets/Layouts/Lava" : LayoutFolder;
        string prefix = difficulty == DifficultyLevel.TrivialLava ? "Layout_Lava_" : $"Layout_P_{difficulty}_";

        // Exakte Namensform <Prefix><Nr>, damit z. B. "Trivial_" nicht
        // versehentlich "TrivialCorr_" mitfängt (FindAssets sucht per Contains).
        var rx = new Regex($"^{Regex.Escape(prefix)}\\d+$");
        return AssetDatabase.FindAssets(prefix, new[] { folder })
            .Select(AssetDatabase.GUIDToAssetPath)
            .Where(p => rx.IsMatch(System.IO.Path.GetFileNameWithoutExtension(p)))
            .OrderBy(p => p, StringComparer.Ordinal)
            .Select(AssetDatabase.LoadAssetAtPath<MapData>)
            .Where(m => m != null)
            .ToList();
    }

    private static void RebuildConfig()
    {
        var cfg = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(ConfigPath);
        if (cfg == null) { Debug.LogError($"[CurriculumV2Builder] Config nicht gefunden: {ConfigPath}"); return; }

        CurriculumPhase Phase(DifficultyLevel d, int threshold, float gate)
        {
            var layouts = FindLayouts(d);
            if (layouts.Count == 0) Debug.LogError($"[CurriculumV2Builder] Keine Layouts für {d}!");
            return new CurriculumPhase
            {
                difficulty     = d,
                layouts        = layouts.ToArray(),
                thresholdType  = ThresholdType.Episodes,
                threshold      = threshold,
                minSuccessRate = gate,
            };
        }

        cfg.phases = new[]
        {
            Phase(DifficultyLevel.Trivial,        500, 0.40f),
            Phase(DifficultyLevel.TrivialCorr,   1800, 0.30f),
            Phase(DifficultyLevel.TrivialHole,   1500, 0.30f),
            Phase(DifficultyLevel.TrivialLava,   2000, 0.30f),
            Phase(DifficultyLevel.TrivialHazard, 1500, 0.30f),
            Phase(DifficultyLevel.Easy,          8000, 0.25f),
            Phase(DifficultyLevel.Medium,       12000, 0.20f),
            Phase(DifficultyLevel.Hard,         20000, 0f),
        };
        cfg.loopPhases          = true;
        cfg.loopStartPhaseIndex = 5;   // Loop Hard -> Easy
        cfg.initialPhaseIndex   = 0;
        cfg.successWindow       = 200;
        cfg.hardCapFactor       = 3;

        EditorUtility.SetDirty(cfg);
        Debug.Log($"[CurriculumV2Builder] Config neu geschrieben: {cfg.phases.Length} Phasen | Layouts: " +
                  string.Join(", ", cfg.phases.Select(p => $"{p.difficulty}={p.layouts.Length}")));
    }
}
