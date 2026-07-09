#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using Unity.MLAgents.Policies;
using TMPro;

/// <summary>
/// Erstellt die Modellvergleichs-Szene mit 3x9 TrainingAreas (9 pro Architektur).
///
/// Menü: Tools / ModelComparison / Build Model Comparison Scene
///
/// Layout (3 Spalten = Modelle, 9 Zeilen = parallele Instanzen):
///
///   X\Z    0      80     160    240    320    400    480    560    640
///   0      LSTM_0 LSTM_1 ...                                  LSTM_8
///   80     Transformer_0  ...                           Transformer_8
///   160    MLP_0  MLP_1  ...                                   MLP_8
/// </summary>
public static class ModelComparisonSceneBuilder
{
    const string SOURCE_SCENE         = "Assets/Scenes/Training_MultiArea.unity";
    const string TARGET_SCENE         = "Assets/Scenes/Training Area.unity";
    const string TRAINING_AREA_PREFAB = "Assets/Prefabs/TrainingArea/TrainingArea.prefab";
    const string CURRICULUM_CONFIG    = "Assets/CurriculumConfig_Default.asset";

    const int AREAS_PER_BEHAVIOR = 9;
    const float SPACING = 80f;

    static readonly (string name, float x, float z, string behaviorName)[] AREAS = new[]
    {
        ("LSTM_0",          0f,   0f,  "LSTM_Navigator"),
        ("LSTM_1",          0f,  80f,  "LSTM_Navigator"),
        ("LSTM_2",          0f, 160f,  "LSTM_Navigator"),
        ("LSTM_3",          0f, 240f,  "LSTM_Navigator"),
        ("LSTM_4",          0f, 320f,  "LSTM_Navigator"),
        ("LSTM_5",          0f, 400f,  "LSTM_Navigator"),
        ("LSTM_6",          0f, 480f,  "LSTM_Navigator"),
        ("LSTM_7",          0f, 560f,  "LSTM_Navigator"),
        ("LSTM_8",          0f, 640f,  "LSTM_Navigator"),
        ("Transformer_0",  80f,   0f,  "Transformer_Navigator"),
        ("Transformer_1",  80f,  80f,  "Transformer_Navigator"),
        ("Transformer_2",  80f, 160f,  "Transformer_Navigator"),
        ("Transformer_3",  80f, 240f,  "Transformer_Navigator"),
        ("Transformer_4",  80f, 320f,  "Transformer_Navigator"),
        ("Transformer_5",  80f, 400f,  "Transformer_Navigator"),
        ("Transformer_6",  80f, 480f,  "Transformer_Navigator"),
        ("Transformer_7",  80f, 560f,  "Transformer_Navigator"),
        ("Transformer_8",  80f, 640f,  "Transformer_Navigator"),
        ("MLP_0",         160f,   0f,  "MLP_Navigator"),
        ("MLP_1",         160f,  80f,  "MLP_Navigator"),
        ("MLP_2",         160f, 160f,  "MLP_Navigator"),
        ("MLP_3",         160f, 240f,  "MLP_Navigator"),
        ("MLP_4",         160f, 320f,  "MLP_Navigator"),
        ("MLP_5",         160f, 400f,  "MLP_Navigator"),
        ("MLP_6",         160f, 480f,  "MLP_Navigator"),
        ("MLP_7",         160f, 560f,  "MLP_Navigator"),
        ("MLP_8",         160f, 640f,  "MLP_Navigator"),
    };

    [MenuItem("Tools/ModelComparison/Build Model Comparison Scene")]
    public static void BuildModelComparisonScene()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            return;

        // ── 1. Quellszene duplizieren ──────────────────────────────────────────
        if (string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(SOURCE_SCENE)))
        {
            EditorUtility.DisplayDialog("Fehler",
                "Quellszene nicht gefunden:\n" + SOURCE_SCENE, "OK");
            return;
        }

        if (!string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(TARGET_SCENE)))
            AssetDatabase.DeleteAsset(TARGET_SCENE);

        if (!AssetDatabase.CopyAsset(SOURCE_SCENE, TARGET_SCENE))
        {
            EditorUtility.DisplayDialog("Fehler",
                "Szene konnte nicht kopiert werden:\n" + TARGET_SCENE, "OK");
            return;
        }
        AssetDatabase.Refresh();

        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);

        // ── 2. Alle bestehenden TrainingAreas entfernen ────────────────────────
        var existingAgents = Object.FindObjectsOfType<LabyrinthAgent>(true);
        int removed = 0;
        foreach (var agent in existingAgents)
        {
            var root = agent.transform.parent != null
                ? agent.transform.parent.gameObject
                : agent.gameObject;
            Object.DestroyImmediate(root);
            removed++;
        }
        Debug.Log($"[ModelComparisonSceneBuilder] {removed} bestehende TrainingArea(s) entfernt.");

        // ── 3. Assets laden ────────────────────────────────────────────────────
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(TRAINING_AREA_PREFAB);
        if (prefab == null)
        {
            EditorUtility.DisplayDialog("Fehler",
                "TrainingArea-Prefab nicht gefunden:\n" + TRAINING_AREA_PREFAB, "OK");
            return;
        }

        var curriculumConfig = AssetDatabase.LoadAssetAtPath<CurriculumConfig>(CURRICULUM_CONFIG);
        if (curriculumConfig == null)
            Debug.LogWarning("[ModelComparisonSceneBuilder] CurriculumConfig nicht gefunden: " + CURRICULUM_CONFIG);

        // ── 4. 9 TrainingAreas im 3x3 Grid instantiieren ──────────────────────
        foreach (var (name, x, z, behaviorName) in AREAS)
        {
            var instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab);
            instance.name = name;
            instance.transform.position = new Vector3(x, 0f, z);

            var bp = instance.GetComponentInChildren<BehaviorParameters>();
            if (bp != null)
            {
                bp.BehaviorName              = behaviorName;
                bp.Model                     = null;
                bp.BehaviorType              = BehaviorType.Default;
                // 31 = voller VectorSensor-Satz (v24CompatMode=false):
                //   Boden 9x2=18 + Velocity 3 + isGrounded 1 + Zieldistanz 1
                //   + Zielrichtung 3 + Wand-Raycasts 4 + Line-of-Sight 1.
                // Muss exakt der Zahl entsprechen, die LabyrinthAgent.CollectObservations
                // emittiert. Frueher 28 (ohne Zielrichtung) — seit deren Re-Einfuehrung
                // (v2, CollectObservations) auf 31 gezogen, sonst Obs-Size-Mismatch.
                bp.BrainParameters.VectorObservationSize = 31;
                EditorUtility.SetDirty(bp);
            }
            else
            {
                Debug.LogWarning($"[ModelComparisonSceneBuilder] Kein BehaviorParameters in {name}");
            }

            var agent = instance.GetComponentInChildren<LabyrinthAgent>();
            if (agent != null)
            {
                agent.v24CompatMode = false;
                if (agent.GetComponent<HumanAgentVisual>() == null)
                    agent.gameObject.AddComponent<HumanAgentVisual>();
                EditorUtility.SetDirty(agent);
            }
            else
            {
                Debug.LogWarning($"[ModelComparisonSceneBuilder] Kein LabyrinthAgent in {name}");
            }

            var mapGen = instance.GetComponentInChildren<MapGenerator>();
            if (mapGen != null)
            {
                mapGen.trainingMode = TrainingMode.Curriculum;
                if (curriculumConfig != null)
                    mapGen.curriculumConfig = curriculumConfig;
                EditorUtility.SetDirty(mapGen);
            }

            EditorUtility.SetDirty(instance);
        }
        Debug.Log("[ModelComparisonSceneBuilder] 27 TrainingAreas im 3x9 Grid platziert.");

        // ── 5. Modell-Labels über jeder Spalte ────────────────────────────────
        CreateModelLabel("LSTM",        0f,   new Color(0.2f, 0.5f, 1.0f));
        CreateModelLabel("Transformer", 80f,  new Color(1.0f, 0.6f, 0.1f));
        CreateModelLabel("MLP",         160f, new Color(0.2f, 0.8f, 0.3f));

        // ── 6. Kamera einrichten + CameraController ────────────────────────────
        var cam = Object.FindObjectOfType<Camera>();
        if (cam != null)
        {
            // 3x9 Grid: X=0..160, Z=0..640 → Mittelpunkt (80, 0, 320)
            cam.transform.position = new Vector3(80f, 350f, -30f);
            cam.transform.rotation = Quaternion.Euler(72f, 0f, 0f);

            if (cam.GetComponent<ModelComparisonCameraController>() == null)
                cam.gameObject.AddComponent<ModelComparisonCameraController>();

            EditorUtility.SetDirty(cam.gameObject);
        }

        // ── 7. Szene speichern ─────────────────────────────────────────────────
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, TARGET_SCENE);
        AssetDatabase.Refresh();

        Debug.Log("[ModelComparisonSceneBuilder] ✓ Szene gespeichert: " + TARGET_SCENE);
        EditorUtility.DisplayDialog(
            "Model Comparison Szene erstellt!",
            "✓  " + TARGET_SCENE + "\n\n" +
            $"• {removed} alte TrainingArea(s) entfernt\n" +
            "• 27 neue TrainingAreas im 3x9 Grid:\n" +
            "    Spalte 0 (X=0):   LSTM_0..8         → BehaviorName: LSTM_Navigator\n" +
            "    Spalte 1 (X=80):  Transformer_0..8  → BehaviorName: Transformer_Navigator\n" +
            "    Spalte 2 (X=160): MLP_0..8          → BehaviorName: MLP_Navigator\n\n" +
            "• Alle Agenten starten ohne vortrainiertes Modell (Training von Null).\n" +
            "• Training-Config muss alle 3 BehaviorNames enthalten.",
            "OK");
    }

    static void CreateModelLabel(string modelName, float xPos, Color color)
    {
        // Root GameObject
        var labelRoot = new GameObject($"Label_{modelName}");
        labelRoot.transform.position = new Vector3(xPos, 5f, -15f);
        labelRoot.transform.rotation = Quaternion.Euler(45f, 0f, 0f);
        labelRoot.transform.localScale = new Vector3(0.1f, 0.1f, 0.1f);

        // WorldSpace Canvas
        var canvas = labelRoot.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.WorldSpace;
        var rt = labelRoot.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(600f, 150f);

        // Semi-transparent background
        var bgGo = new GameObject("Background");
        bgGo.transform.SetParent(labelRoot.transform, false);
        var bgImage = bgGo.AddComponent<Image>();
        bgImage.color = new Color(0f, 0f, 0f, 0.55f);
        var bgRt = bgGo.GetComponent<RectTransform>();
        bgRt.anchorMin = Vector2.zero;
        bgRt.anchorMax = Vector2.one;
        bgRt.offsetMin = Vector2.zero;
        bgRt.offsetMax = Vector2.zero;

        // TextMeshPro label
        var textGo = new GameObject("Text");
        textGo.transform.SetParent(labelRoot.transform, false);
        var tmp = textGo.AddComponent<TextMeshProUGUI>();
        tmp.text = modelName;
        tmp.fontSize = 100f;
        tmp.fontStyle = FontStyles.Bold;
        tmp.color = color;
        tmp.alignment = TextAlignmentOptions.Center;
        var textRt = textGo.GetComponent<RectTransform>();
        textRt.anchorMin = Vector2.zero;
        textRt.anchorMax = Vector2.one;
        textRt.offsetMin = Vector2.zero;
        textRt.offsetMax = Vector2.zero;

        EditorUtility.SetDirty(labelRoot);
        Debug.Log($"[ModelComparisonSceneBuilder] Label '{modelName}' erstellt bei X={xPos}.");
    }
}
#endif
