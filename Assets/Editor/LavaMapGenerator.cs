using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Generiert Lava-Trainings-Maps für die TrivialLava Curriculum-Phase.
/// Zwei Map-Typen:
///   Single-Lava: 1 Lava-Streifen  →  Agent lernt das Sprung-Timing
///   Double-Lava: 2 Lava-Streifen  →  Agent übt das Verhalten mehrfach pro Episode
/// </summary>
public static class LavaMapGenerator
{
    private const string LavaFolder  = "Assets/Layouts/Lava";
    private const string ConfigPath  = "Assets/CurriculumConfig_Default.asset";
    private const string LavaPrefix  = "Layout_Lava_";
    private const int    InsertIdx   = 2;    // TrivialLava: zwischen TrivialCorr(1) und TrivialBranch(2)
    private const int    Threshold   = 2000; // Episoden in der TrivialLava-Phase
    private const int    LoopStart   = 6;    // Loop zurück zu Easy nach Hard

    [MenuItem("Tools/Training/Lava-Maps generieren und Curriculum aktualisieren")]
    public static void GenerateLavaMapsAndUpdateCurriculum()
    {
        // ── Ordner ────────────────────────────────────────────────────────────
        if (!AssetDatabase.IsValidFolder("Assets/Layouts"))
            AssetDatabase.CreateFolder("Assets", "Layouts");
        if (!AssetDatabase.IsValidFolder(LavaFolder))
            AssetDatabase.CreateFolder("Assets/Layouts", "Lava");

        // Alte Maps löschen
        foreach (string g in AssetDatabase.FindAssets(LavaPrefix, new[] { LavaFolder }))
            AssetDatabase.DeleteAsset(AssetDatabase.GUIDToAssetPath(g));

        var maps    = new List<MapData>();
        int idx     = 0;
        float[] spawnFracs = { 0f, 0.25f, 0.5f, 0.75f, 1f };

        // ── Single-Lava Maps (1 Streifen) ─────────────────────────────────────
        // Kleine Maps (w=8,10): 3 Positionen × 5 Spawn = 15 pro Paar
        // Große Maps (w=12,14): 5 Positionen × 5 Spawn = 25 pro Paar
        // → 5×15 + 5×25 = 200 Maps
        var singleSizes = new (int w, int h, int lavaCount)[]
        {
            (8,  6,  3), (8,  8,  3),
            (10, 6,  3), (10, 8,  3), (10, 10, 3),
            (12, 8,  5), (12, 10, 5),
            (14, 8,  5), (14, 10, 5), (14, 12, 5),
        };
        float[] lavaSmall = { 0.30f, 0.50f, 0.70f };
        float[] lavaLarge = { 0.30f, 0.40f, 0.50f, 0.60f, 0.70f };

        foreach (var (w, h, lc) in singleSizes)
        {
            float[] lf = lc == 3 ? lavaSmall : lavaLarge;
            foreach (float lavFrac in lf)
                foreach (float spFrac in spawnFracs)
                    CreateAndSave(MakeSingleLavaMap(w, h, lavFrac, spFrac), maps, ref idx);
        }

        int singleCount = maps.Count;

        // ── Double-Lava Maps (2 Streifen) ─────────────────────────────────────
        // Nur für w >= 10 (genug Platz).  Mindest-Abstand: 3 Zellen zwischen den Streifen.
        // lava1-Frac ∈ {0.25, 0.35},  lava2-Frac ∈ {0.55, 0.65, 0.75}
        // Validierung: gap = lava2Local - lava1Local >= 3
        var doubleSizes = new (int w, int h)[]
        {
            (10, 6), (10, 8), (10, 10),
            (12, 8), (12, 10),
            (14, 8), (14, 10), (14, 12),
        };
        float[] l1Fracs = { 0.25f, 0.35f };
        float[] l2Fracs = { 0.55f, 0.65f, 0.75f };

        foreach (var (w, h) in doubleSizes)
        {
            int iW = w - 2;
            foreach (float f1 in l1Fracs)
            {
                int l1 = Mathf.Clamp(Mathf.RoundToInt(f1 * iW), 1, iW - 2);
                foreach (float f2 in l2Fracs)
                {
                    int l2 = Mathf.Clamp(Mathf.RoundToInt(f2 * iW), 1, iW - 2);
                    if (l2 - l1 < 3) continue; // zu wenig Platz zum Landen
                    foreach (float spFrac in spawnFracs)
                        CreateAndSave(MakeDoubleLavaMap(w, h, l1, l2, spFrac), maps, ref idx);
                }
            }
        }

        int doubleCount = maps.Count - singleCount;

        AssetDatabase.SaveAssets();

        if (maps.Count == 0)
        {
            EditorUtility.DisplayDialog("Fehler", "Keine Maps generiert.", "OK");
            return;
        }

        // ── CurriculumConfig aktualisieren ────────────────────────────────────
        var config = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(ConfigPath);
        if (config == null)
        {
            EditorUtility.DisplayDialog("Fehler", $"Config nicht gefunden:\n{ConfigPath}", "OK");
            return;
        }

        var so          = new SerializedObject(config);
        so.Update();
        var phasesProp  = so.FindProperty("phases");
        var loopProp    = so.FindProperty("loopStartPhaseIndex");
        var initProp    = so.FindProperty("initialPhaseIndex");

        // TrivialLava-Phase suchen oder einfügen
        int phaseIdx = -1;
        for (int i = 0; i < phasesProp.arraySize; i++)
            if (phasesProp.GetArrayElementAtIndex(i)
                    .FindPropertyRelative("difficulty").intValue == (int)DifficultyLevel.TrivialLava)
            { phaseIdx = i; break; }

        if (phaseIdx < 0)
        {
            phasesProp.InsertArrayElementAtIndex(InsertIdx);
            phaseIdx = InsertIdx;
        }

        var phase = phasesProp.GetArrayElementAtIndex(phaseIdx);
        phase.FindPropertyRelative("difficulty").intValue    = (int)DifficultyLevel.TrivialLava;
        phase.FindPropertyRelative("thresholdType").intValue = 0; // Episodes
        phase.FindPropertyRelative("threshold").intValue     = Threshold;

        var layoutsProp = phase.FindPropertyRelative("layouts");
        layoutsProp.ClearArray();
        layoutsProp.arraySize = maps.Count;
        for (int i = 0; i < maps.Count; i++)
            layoutsProp.GetArrayElementAtIndex(i).objectReferenceValue = maps[i];

        loopProp.intValue = LoopStart;
        if (initProp != null) initProp.intValue = 0;

        so.ApplyModifiedProperties();
        EditorUtility.SetDirty(config);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        Debug.Log($"[LavaMapGen] {maps.Count} Maps ({singleCount} single, {doubleCount} double). " +
                  $"Phases: {phasesProp.arraySize}. Threshold: {Threshold}.");

        EditorUtility.DisplayDialog("Fertig",
            $"✓ {singleCount} Single-Lava Maps\n" +
            $"✓ {doubleCount} Double-Lava Maps\n" +
            $"✓ Gesamt: {maps.Count} Maps\n" +
            $"✓ Threshold: {Threshold} Episoden\n" +
            $"✓ loopStartPhaseIndex = {LoopStart}", "OK");
    }

    // ── Hilfsmethoden ─────────────────────────────────────────────────────────

    static void CreateAndSave(MapData map, List<MapData> list, ref int idx)
    {
        if (map == null) return;
        idx++;
        string path = $"{LavaFolder}/{LavaPrefix}{idx:D3}.asset";

        EditorUtility.DisplayProgressBar("Lava-Maps generieren",
            $"Map {idx} ({map.width}×{map.height})", idx / 500f);

        AssetDatabase.CreateAsset(map, path);
        list.Add(map);
    }

    /// <summary>Single Lava-Streifen. SpawnPoint links, Goal rechts.</summary>
    static MapData MakeSingleLavaMap(int w, int h, float lavaFrac, float spawnFrac)
    {
        int iW = w - 2;
        int iH = h - 2;
        int lx = Mathf.Clamp(Mathf.RoundToInt(lavaFrac * iW), 1, iW - 2);
        if (lx < 1 || lx > iW - 2) return null;

        int sx = 1;
        int sy = 1 + Mathf.Clamp(Mathf.RoundToInt(spawnFrac * (iH - 1)), 0, iH - 1);
        int gx = (1 + lx + 1 + w - 2) / 2; // Mitte der rechten Region
        int gy = Mathf.Clamp(h / 2, 1, h - 2);

        return BuildMap(w, h,
            lavaAbsX: new[] { 1 + lx },
            spawnX: sx, spawnY: sy,
            goalX: gx, goalY: gy);
    }

    /// <summary>Zwei Lava-Streifen. Agent muss zweimal springen.</summary>
    static MapData MakeDoubleLavaMap(int w, int h, int lava1Local, int lava2Local, float spawnFrac)
    {
        int iH = h - 2;
        int lx1 = 1 + lava1Local;
        int lx2 = 1 + lava2Local;

        int sx  = 1;                         // SpawnPoint: erste Innenspalte (links)
        int sy  = 1 + Mathf.Clamp(Mathf.RoundToInt(spawnFrac * (iH - 1)), 0, iH - 1);
        int gx  = Mathf.Clamp(lx2 + 1 + (w - 2 - lx2 - 1) / 2, lx2 + 1, w - 2); // rechts von lx2
        int gy  = Mathf.Clamp(h / 2, 1, h - 2);

        return BuildMap(w, h,
            lavaAbsX: new[] { lx1, lx2 },
            spawnX: sx, spawnY: sy,
            goalX: gx, goalY: gy);
    }

    static MapData BuildMap(int w, int h, int[] lavaAbsX,
                            int spawnX, int spawnY, int goalX, int goalY)
    {
        var map    = ScriptableObject.CreateInstance<MapData>();
        map.width  = w;
        map.height = h;
        map.Init();

        // Rand = Wand, Innen = Boden
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                map.SetCell(x, y, (x == 0 || y == 0 || x == w - 1 || y == h - 1)
                    ? CellType.Wall : CellType.Floor);

        // Lava-Streifen (volle Innenhöhe – kein Weg drumherum)
        foreach (int lx in lavaAbsX)
            for (int y = 1; y < h - 1; y++)
                map.SetCell(lx, y, CellType.Lava);

        map.SetCell(spawnX, spawnY, CellType.SpawnPoint);
        map.SetCell(goalX,  goalY,  CellType.Goal);
        return map;
    }
}
