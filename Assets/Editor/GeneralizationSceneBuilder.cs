#if UNITY_EDITOR
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using Unity.MLAgents.Policies;

/// <summary>
/// Baut die Generalisierungstest-Szene:
///   1. Generiert Held-out-Maps mit dediziertem Seed-Bereich (nie im Training gesehen):
///      10 Easy, 10 Medium, 10 Hard, 5 Giant → Assets/Layouts/Generalization/
///   2. Kopiert die Trainingsszene und reduziert sie auf DREI Areale mit je EINEM
///      Agenten (MLP / LSTM / Transformer) — Observations (31er inkl. Zielvektor)
///      und Prefab-Verdrahtung bleiben dadurch identisch zum Training.
///   3. Verdrahtet den GeneralizationEvalManager, HUD und eine Überblickskamera.
/// Batchmode: Unity.exe -batchmode -executeMethod GeneralizationSceneBuilder.BuildAll -quit
/// </summary>
public static class GeneralizationSceneBuilder
{
    const string SOURCE_SCENE  = "Assets/Scenes/Training Area.unity";
    const string TARGET_SCENE  = "Assets/Scenes/Generalization Test.unity";
    const string LAYOUT_FOLDER = "Assets/Layouts/Generalization";
    const int    SEED_BASE     = 900000;   // bewusst weit weg von allen Trainings-Seeds

    static readonly (DifficultyLevel diff, int count)[] PLAN =
    {
        (DifficultyLevel.Easy,   50),
        (DifficultyLevel.Medium, 50),
        (DifficultyLevel.Hard,   50),
        (DifficultyLevel.Giant,   5),
    };

    /// <summary>
    /// Weist den drei Agenten die finalen ONNX-Modelle zu (Assets/Models/FinalV2/)
    /// und baut die Testszene als eigenständigen Player nach Build_Gen/.
    /// Batchmode: -executeMethod GeneralizationSceneBuilder.AssignModelsAndBuild
    /// </summary>
    [MenuItem("Training/Generalisierungstest: Modelle zuweisen + Build")]
    public static void AssignModelsAndBuild()
    {
        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);
        string[] wanted = { "MLP_Navigator", "LSTM_Navigator", "Transformer_Navigator" };
        int assigned = 0;

        foreach (var agent in Object.FindObjectsByType<LabyrinthAgent>(FindObjectsInactive.Include, FindObjectsSortMode.None))
        {
            var bp = agent.GetComponent<BehaviorParameters>();
            if (bp == null) continue;
            string behavior = bp.BehaviorName;
            if (System.Array.IndexOf(wanted, behavior) < 0) continue;

            string guid = AssetDatabase.FindAssets($"{behavior}-", new[] { "Assets/Models/FinalV2" }).FirstOrDefault();
            if (guid == null)
            {
                Debug.LogError($"[GeneralizationSceneBuilder] Kein Modell für {behavior} in Assets/Models/FinalV2!");
                return;
            }
            string path = AssetDatabase.GUIDToAssetPath(guid);
            var model = AssetDatabase.LoadMainAssetAtPath(path);
            var so = new SerializedObject(bp);
            var prop = so.FindProperty("m_Model");
            prop.objectReferenceValue = model;
            so.ApplyModifiedProperties();
            EditorUtility.SetDirty(bp);
            assigned++;
            Debug.Log($"[GeneralizationSceneBuilder] {behavior} ← {path}");
        }

        if (assigned != wanted.Length)
        {
            Debug.LogError($"[GeneralizationSceneBuilder] Nur {assigned}/3 Modelle zugewiesen — Abbruch.");
            return;
        }
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, TARGET_SCENE);
        AssetDatabase.SaveAssets();

        var options = new BuildPlayerOptions
        {
            scenes           = new[] { TARGET_SCENE },
            locationPathName = "Build_Gen/KI_Agenten_GenTest.exe",
            target           = BuildTarget.StandaloneWindows64,
            options          = BuildOptions.None,
        };
        var report = UnityEditor.BuildPipeline.BuildPlayer(options);
        Debug.Log($"[GeneralizationSceneBuilder] Build: {report.summary.result} | Errors: {report.summary.totalErrors}");
    }

    /// <summary>
    /// Build-Variante für Python-Inferenz (mlagents --inference --resume):
    /// BehaviorType=Default, keine ONNX-Modelle — die Policies liefert der Trainer.
    /// Umgeht die Barracuda-Inkompatibilität des Transformer-Graphen vollständig
    /// und nutzt exakt die Trainings-Policy-Implementierung.
    /// </summary>
    [MenuItem("Training/Generalisierungstest: Build für Python-Inferenz")]
    public static void BuildForPythonInference()
    {
        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);
        foreach (var agent in Object.FindObjectsByType<LabyrinthAgent>(FindObjectsInactive.Include, FindObjectsSortMode.None))
        {
            var bp = agent.GetComponent<BehaviorParameters>();
            if (bp == null) continue;
            var so = new SerializedObject(bp);
            so.FindProperty("m_Model").objectReferenceValue = null;
            so.FindProperty("m_BehaviorType").enumValueIndex = (int)Unity.MLAgents.Policies.BehaviorType.Default;
            so.ApplyModifiedProperties();
            EditorUtility.SetDirty(bp);
            Debug.Log($"[GeneralizationSceneBuilder] {bp.BehaviorName}: BehaviorType=Default, Modell entfernt (Python-Inferenz)");
        }
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, TARGET_SCENE);

        var options = new BuildPlayerOptions
        {
            scenes           = new[] { TARGET_SCENE },
            locationPathName = "Build_Gen/KI_Agenten_GenTest.exe",
            target           = BuildTarget.StandaloneWindows64,
            options          = BuildOptions.None,
        };
        var report = UnityEditor.BuildPipeline.BuildPlayer(options);
        Debug.Log($"[GeneralizationSceneBuilder] Build (Python-Inferenz): {report.summary.result} | Errors: {report.summary.totalErrors}");
    }

    [MenuItem("Training/Generalisierungstest bauen (Maps + Szene)")]
    public static void BuildAll()
    {
        var maps = GenerateHeldOutMaps();
        BuildScene(maps);
        AssetDatabase.SaveAssets();
        Debug.Log("[GeneralizationSceneBuilder] Fertig.");
    }

    // ── 1. Held-out-Maps ─────────────────────────────────────────────────────
    static List<MapData> GenerateHeldOutMaps()
    {
        if (!AssetDatabase.IsValidFolder(LAYOUT_FOLDER))
            AssetDatabase.CreateFolder("Assets/Layouts", "Generalization");

        var all = new List<MapData>();
        foreach (var (diff, count) in PLAN)
        {
            string prefix = $"Layout_GEN_{diff}_";

            // Vollständig vorhandenen Satz wiederverwenden, sonst Kategorie neu aufbauen
            // (deterministische Seeds — Teilmengen aus früheren Läufen würden sonst
            // bei anderer Zielanzahl zu Duplikaten führen).
            var existing = new List<MapData>();
            for (int i = 1; i <= count; i++)
            {
                var found = AssetDatabase.LoadAssetAtPath<MapData>($"{LAYOUT_FOLDER}/{prefix}{i:D3}.asset");
                if (found == null) break;
                existing.Add(found);
            }
            if (existing.Count >= count)
            {
                Debug.Log($"[GeneralizationSceneBuilder] {diff}: {existing.Count} Maps vorhanden.");
                all.AddRange(existing);
                continue;
            }
            foreach (var guid in AssetDatabase.FindAssets(prefix, new[] { LAYOUT_FOLDER }))
                AssetDatabase.DeleteAsset(AssetDatabase.GUIDToAssetPath(guid));

            int created = 0, tries = 0;
            var made = new List<MapData>();
            while (made.Count < count && tries < count * 20)
            {
                // 100.000er-Abstand je Difficulty: kein Seed-Überlapp zwischen Kategorien,
                // auch bei vielen Fehlversuchen (tries*17 <= 17.000).
                int seed = SEED_BASE + (int)diff * 100000 + tries * 17;
                tries++;
                MapData layout = ProceduralLayoutGenerator.GenerateLayout(seed, diff, null);
                if (layout == null) continue;
                string path = $"{LAYOUT_FOLDER}/{prefix}{made.Count + 1:D3}.asset";
                AssetDatabase.CreateAsset(layout, path);
                made.Add(layout);
                created++;
            }
            AssetDatabase.SaveAssets();
            Debug.Log($"[GeneralizationSceneBuilder] {diff}: {created} neu generiert ({made.Count}/{count}, {tries} Versuche).");
            all.AddRange(made);
        }
        return all;
    }

    // ── 2. Szene ─────────────────────────────────────────────────────────────
    static void BuildScene(List<MapData> maps)
    {
        if (!string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(TARGET_SCENE)))
            AssetDatabase.DeleteAsset(TARGET_SCENE);
        if (!AssetDatabase.CopyAsset(SOURCE_SCENE, TARGET_SCENE))
        {
            Debug.LogError("[GeneralizationSceneBuilder] Szene konnte nicht kopiert werden.");
            return;
        }
        AssetDatabase.Refresh();
        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);

        // Areale über die Agenten finden (Wurzelobjekt je Areal)
        var agents = Object.FindObjectsOfType<LabyrinthAgent>(true);
        var byRoot = new Dictionary<GameObject, List<LabyrinthAgent>>();
        foreach (var ag in agents)
        {
            var root = ag.transform.root.gameObject;
            if (!byRoot.TryGetValue(root, out var list)) byRoot[root] = list = new List<LabyrinthAgent>();
            list.Add(ag);
        }

        // Struktur der Trainingsszene: JEDES Areal ist ein Top-Level-Root mit genau
        // einem Agenten und eigenem MapGenerator (MLP_0..8, LSTM_0..8, Transformer_0..8).
        // Wir behalten je Architektur das _0-Areal und entfernen alle übrigen.
        string[] wanted = { "MLP_Navigator", "LSTM_Navigator", "Transformer_Navigator" };
        var keepRoots = new Dictionary<string, GameObject>();
        foreach (var behavior in wanted)
        {
            var candidates = byRoot.Where(kv => kv.Value.Any(ag =>
                    ag.GetComponent<BehaviorParameters>()?.BehaviorName == behavior))
                .Select(kv => kv.Key)
                .OrderBy(r => r.name, System.StringComparer.Ordinal)
                .ToList();
            if (candidates.Count == 0)
            {
                Debug.LogError($"[GeneralizationSceneBuilder] Kein Areal mit Behavior {behavior} gefunden!");
                return;
            }
            keepRoots[behavior] = candidates[0];
        }
        foreach (var root in byRoot.Keys)
            if (!keepRoots.ContainsValue(root))
                Object.DestroyImmediate(root);

        var evalAreas = new List<GeneralizationEvalManager.EvalArea>();
        foreach (var behavior in wanted)
        {
            var root = keepRoots[behavior];
            var keep = root.GetComponentInChildren<LabyrinthAgent>(true);
            if (keep == null)
            {
                Debug.LogError($"[GeneralizationSceneBuilder] Areal {root.name}: Agent fehlt!");
                continue;
            }

            var mapGen = root.GetComponentInChildren<MapGenerator>();
            mapGen.trainingMode    = TrainingMode.Standard;
            mapGen.selectionMode   = MapSelectionMode.Fixed;
            mapGen.mapLayouts      = maps.ToArray();
            mapGen.autoFrameCamera = false;

            keep.competitionMode = true;
            if (keep.mapGenerator == null) keep.mapGenerator = mapGen;

            var keepBp = keep.GetComponent<BehaviorParameters>();
            keepBp.BehaviorType = Unity.MLAgents.Policies.BehaviorType.InferenceOnly;
            EditorUtility.SetDirty(keepBp);

            root.name = $"EvalArea_{behavior.Replace("_Navigator", "")}";
            evalAreas.Add(new GeneralizationEvalManager.EvalArea
            {
                label = behavior.Replace("_Navigator", ""),
                agent = keep,
                mapGenerator = mapGen,
            });
            EditorUtility.SetDirty(keep);
            EditorUtility.SetDirty(mapGen);
        }

        // HUD
        var canvasGO = new GameObject("EvalCanvas");
        var canvas = canvasGO.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvasGO.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        var labelGO = new GameObject("HudLabel");
        labelGO.transform.SetParent(canvasGO.transform, false);
        var tmp = labelGO.AddComponent<TextMeshProUGUI>();
        tmp.fontSize = 22; tmp.color = Color.white;
        tmp.text = "Generalisierungstest — Play drücken";
        var rt = labelGO.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(0f, 1f);
        rt.pivot = new Vector2(0f, 1f);
        rt.anchoredPosition = new Vector2(16f, -12f);
        rt.sizeDelta = new Vector2(900f, 160f);

        // Überblickskamera über dem Zentrum der drei Areale
        if (Object.FindObjectsOfType<Camera>().Length == 0)
        {
            var centroid = evalAreas.Aggregate(Vector3.zero, (acc, a) => acc + a.mapGenerator.transform.position) / evalAreas.Count;
            var camGO = new GameObject("EvalOverviewCamera");
            var cam = camGO.AddComponent<Camera>();
            camGO.transform.position = centroid + new Vector3(0f, 90f, -55f);
            camGO.transform.LookAt(centroid);
            cam.farClipPlane = 500f;
        }

        // Manager
        var mgrGO = new GameObject("GeneralizationEvalManager");
        var mgr = mgrGO.AddComponent<GeneralizationEvalManager>();
        mgr.areas = evalAreas.ToArray();
        mgr.maps = maps.ToArray();
        mgr.hudLabel = tmp;
        EditorUtility.SetDirty(mgr);

        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, TARGET_SCENE);
        AssetDatabase.Refresh();
        Debug.Log($"[GeneralizationSceneBuilder] Szene gespeichert: {TARGET_SCENE} | Areale: {evalAreas.Count} | Maps: {maps.Count}");
    }
}
#endif
