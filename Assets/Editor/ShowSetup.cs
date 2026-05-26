using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using Unity.Barracuda;
using Unity.MLAgents.Policies;

public static class ShowSetup
{
    const string ShowConfigPath   = "Assets/CurriculumConfig_Show.asset";
    const string DefaultConfigPath = "Assets/CurriculumConfig_Default.asset";
    const string ModelPath        = "Assets/ML-Agents/Models/lstm_curiosity.onnx";

    [MenuItem("Tools/Show/1 – Show-Modus aktivieren")]
    static void ActivateShowMode()
    {
        var showConfig = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(ShowConfigPath);
        var model      = AssetDatabase.LoadAssetAtPath<NNModel>(ModelPath);

        if (showConfig == null) { Debug.LogError($"[ShowSetup] Nicht gefunden: {ShowConfigPath}"); return; }
        if (model == null)      { Debug.LogError($"[ShowSetup] Nicht gefunden: {ModelPath}"); return; }

        var areas = FindAllAreas();
        areas.Sort((a, b) => string.Compare(a.name, b.name, System.StringComparison.Ordinal));

        for (int i = 0; i < areas.Count; i++)
        {
            var area   = areas[i];
            bool first = (i == 0);
            area.SetActive(first);
            EditorUtility.SetDirty(area);

            if (!first) continue;

            var mapGen = area.GetComponentInChildren<MapGenerator>(true);
            if (mapGen != null) { mapGen.curriculumConfig = showConfig; EditorUtility.SetDirty(mapGen); }

            var bp = area.GetComponentInChildren<BehaviorParameters>(true);
            if (bp != null) { bp.Model = model; bp.BehaviorType = BehaviorType.InferenceOnly; EditorUtility.SetDirty(bp); }
        }

        SaveScene();
        Debug.Log($"[ShowSetup] Show-Modus aktiv – {areas.Count - 1} Areas deaktiviert, Modell geladen.");
    }

    [MenuItem("Tools/Show/2 – Training-Modus wiederherstellen")]
    static void ActivateTrainingMode()
    {
        var defaultConfig = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(DefaultConfigPath);

        foreach (var area in FindAllAreas())
        {
            area.SetActive(true);
            EditorUtility.SetDirty(area);

            var mapGen = area.GetComponentInChildren<MapGenerator>(true);
            if (mapGen != null && defaultConfig != null) { mapGen.curriculumConfig = defaultConfig; EditorUtility.SetDirty(mapGen); }

            var bp = area.GetComponentInChildren<BehaviorParameters>(true);
            if (bp != null) { bp.Model = null; bp.BehaviorType = BehaviorType.Default; EditorUtility.SetDirty(bp); }
        }

        SaveScene();
        Debug.Log("[ShowSetup] Training-Modus wiederhergestellt – alle Areas aktiv.");
    }

    static List<GameObject> FindAllAreas() =>
        Resources.FindObjectsOfTypeAll<GameObject>()
            .Where(go => go.scene.IsValid() &&
                         go.transform.parent == null &&
                         go.name.StartsWith("TrainingArea"))
            .ToList();

    static void SaveScene()
    {
        var scene = SceneManager.GetActiveScene();
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene);
    }
}
