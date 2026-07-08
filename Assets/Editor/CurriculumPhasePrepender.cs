#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

/// Fuegt eine neue Phase 0 (Trivial, 7x7 offener Raum) vor der bisherigen Phase 0 ein.
/// Menu: Tools / Curriculum / Prepend Trivial Goal Phase
public static class CurriculumPhasePrepender
{
    const string CONFIG_PATH  = "Assets/CurriculumConfig_Default.asset";
    const string LAYOUTS_PATH = "Assets/Layouts/Procedural";

    [MenuItem("Tools/Curriculum/Prepend Trivial Goal Phase")]
    public static void PrependTrivialPhase()
    {
        var config = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(CONFIG_PATH);
        if (config == null)
        {
            EditorUtility.DisplayDialog("Fehler", "CurriculumConfig_Default.asset nicht gefunden.", "OK");
            return;
        }

        // Alle Trivial-Layouts laden (DifficultyLevel.Trivial = offener 7x7 Raum)
        var guids = AssetDatabase.FindAssets("Layout_P_Trivial_", new[] { LAYOUTS_PATH });
        if (guids.Length == 0)
        {
            EditorUtility.DisplayDialog("Fehler", "Keine Layout_P_Trivial_*.asset gefunden in:\n" + LAYOUTS_PATH, "OK");
            return;
        }

        var trivialLayouts = new MapData[guids.Length];
        for (int i = 0; i < guids.Length; i++)
        {
            string path = AssetDatabase.GUIDToAssetPath(guids[i]);
            trivialLayouts[i] = AssetDatabase.LoadAssetAtPath<MapData>(path);
        }

        // Pruefen ob Phase 0 bereits Trivial ist (Doppel-Einfuegen verhindern)
        if (config.phases != null && config.phases.Length > 0 &&
            config.phases[0].difficulty == DifficultyLevel.Trivial &&
            config.phases[0].threshold == 500)
        {
            EditorUtility.DisplayDialog("Bereits vorhanden",
                "Phase 0 ist bereits eine Trivial-Goal-Phase (Threshold 500). Nichts geaendert.", "OK");
            return;
        }

        // Neue Phase bauen
        var newPhase = new CurriculumPhase
        {
            difficulty     = DifficultyLevel.Trivial,
            layouts        = trivialLayouts,
            thresholdType  = ThresholdType.Episodes,
            threshold      = 500,
        };

        // Bestehende Phasen um 1 nach hinten verschieben
        var oldPhases = config.phases ?? new CurriculumPhase[0];
        var newPhases = new CurriculumPhase[oldPhases.Length + 1];
        newPhases[0] = newPhase;
        for (int i = 0; i < oldPhases.Length; i++)
            newPhases[i + 1] = oldPhases[i];

        // loopStartPhaseIndex um 1 erhoehen (alle alten Phasen rutschen einen Index nach unten)
        config.phases             = newPhases;
        config.loopStartPhaseIndex = config.loopStartPhaseIndex + 1;
        config.initialPhaseIndex  = 0;

        EditorUtility.SetDirty(config);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        Debug.Log($"[CurriculumPhasePrepender] Phase 0 eingefuegt: Trivial, {trivialLayouts.Length} Layouts, Threshold=500 Episoden.");
        EditorUtility.DisplayDialog(
            "Curriculum aktualisiert!",
            $"Neue Phase 0 eingefuegt:\n" +
            $"  Typ: Trivial (7x7 offener Raum, nur Goal)\n" +
            $"  Layouts: {trivialLayouts.Length}\n" +
            $"  Threshold: 500 Episoden\n\n" +
            $"Bisherige Phasen sind jetzt Phase 1..{newPhases.Length - 1}.\n" +
            $"loopStartPhaseIndex wurde auf {config.loopStartPhaseIndex} angepasst.",
            "OK");
    }
}
#endif
