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

    /// <summary>
    /// Bereitet die vorhandene Generalisierungstest-Szene zum LIVE-Zuschauen im
    /// Editor auf (kein Build): Alle drei Behaviors laufen per Python-Inferenz
    /// (Default, kein ONNX — der Transformer-Graph ist Barracuda-inkompatibel),
    /// die Kamera bekommt denselben Umschalter wie das Training
    /// (ModelComparisonCameraController: 0/Tab Übersicht, 1-3 Top-Down, 4-6 POV),
    /// die drei Architektur-Labels bleiben erhalten, und der EvalManager läuft
    /// mit timeScale 1 (zuschau-tauglich, im Inspector änderbar).
    ///
    /// Ablauf danach:
    ///   1. Trainer im Inferenz-Modus starten (wartet auf Unity):
    ///        python -m mlagents.trainers.learn config/model_comparison_final_v2.yaml \
    ///          --run-id model_comparison_final_v2 --inference --resume --base-port 5004
    ///   2. In Unity die Szene "Generalization Test" öffnen und Play drücken.
    /// </summary>
    [MenuItem("Training/Generalisierungstest: Editor-Ansicht vorbereiten (Python-Inferenz)")]
    public static void PrepareEditorWatch()
    {
        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);

        // 1. Alle drei Behaviors auf Python-Inferenz stellen (Default, kein Modell).
        int set = 0;
        foreach (var agent in Object.FindObjectsByType<LabyrinthAgent>(FindObjectsInactive.Include, FindObjectsSortMode.None))
        {
            var bp = agent.GetComponent<BehaviorParameters>();
            if (bp == null) continue;
            var so = new SerializedObject(bp);
            so.FindProperty("m_Model").objectReferenceValue = null;
            so.FindProperty("m_BehaviorType").enumValueIndex = (int)BehaviorType.Default;
            so.ApplyModifiedProperties();
            EditorUtility.SetDirty(bp);
            set++;
        }

        // 2. Kamera-Umschalter wie im Training auf die vorhandene Kamera legen.
        var cam = Object.FindFirstObjectByType<Camera>();
        if (cam == null)
            Debug.LogWarning("[GeneralizationSceneBuilder] Keine Kamera in der Szene gefunden.");
        else
        {
            if (cam.GetComponent<ModelComparisonCameraController>() == null)
                cam.gameObject.AddComponent<ModelComparisonCameraController>();
            // POV-Kamera nicht durch Wände sehen (messe2-Fix): blendet schwarz,
            // sobald die Ego-Kamera in Wandgeometrie ragt.
            if (cam.GetComponent<EgoClipGuard>() == null)
                cam.gameObject.AddComponent<EgoClipGuard>();
            EditorUtility.SetDirty(cam.gameObject);
        }

        // 3. Zuschau-Geschwindigkeit (1 = Echtzeit; im Inspector des Managers änderbar).
        var mgr = Object.FindFirstObjectByType<GeneralizationEvalManager>();
        if (mgr != null)
        {
            mgr.timeScale = 1f;
            // Fürs Video: jede der 155 Maps läuft genau EINMAL durch (statt 5 Episoden).
            mgr.episodesPerMap = 1;
            // Kürzere Timeouts fürs Video: ein hängender/gestorbener Agent hält die
            // bereits fertigen (eingefrorenen) Areale deutlich kürzer auf. Bleibt
            // synchron (alle 3 auf derselben Map) und damit fair vergleichbar.
            mgr.secondsEasy   = 20f;
            mgr.secondsMedium = 30f;
            mgr.secondsHard   = 40f;
            mgr.secondsGiant  = 60f;
            EditorUtility.SetDirty(mgr);
        }

        // 4. Architektur-Labels mittig über die Areale legen (behebt Überlappung).
        PositionModelLabels();

        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, TARGET_SCENE);
        AssetDatabase.SaveAssets();
        Debug.Log($"[GeneralizationSceneBuilder] Editor-Ansicht bereit: {set} Behaviors auf Python-Inferenz, " +
                  $"Kamera-Umschalter{(cam != null ? "" : " (KEINE Kamera!)")} + timeScale 1 gesetzt. " +
                  "Jetzt Trainer (--inference --resume) starten, dann Play drücken.");
    }

    // Legt die drei World-Space-Labels (LSTM/Transformer/MLP) mittig ÜBER ihrem
    // jeweiligen Areal ab — anhand der tatsächlichen MapGenerator-Position, damit
    // sie sich nicht überlappen und alle drei erscheinen (fehlende werden erstellt).
    static void PositionModelLabels()
    {
        var specs = new (string behavior, string name, Color color)[]
        {
            ("LSTM_Navigator",        "LSTM",        new Color(0.2f, 0.5f, 1.0f)),
            ("Transformer_Navigator", "Transformer", new Color(1.0f, 0.6f, 0.1f)),
            ("MLP_Navigator",         "MLP",         new Color(0.2f, 0.8f, 0.3f)),
        };
        var agents = Object.FindObjectsByType<LabyrinthAgent>(FindObjectsInactive.Include, FindObjectsSortMode.None);

        foreach (var (behavior, name, color) in specs)
        {
            Vector3 anchor = Vector3.zero; bool found = false;
            foreach (var a in agents)
            {
                var bp = a.GetComponent<BehaviorParameters>();
                if (bp == null || bp.BehaviorName != behavior) continue;
                var areaRoot = a.transform.parent != null ? a.transform.parent : a.transform;
                var gen = areaRoot.GetComponentInChildren<MapGenerator>(true);
                anchor = (gen != null ? gen.transform : areaRoot).position;
                found = true; break;
            }
            if (!found)
            {
                Debug.LogWarning($"[GeneralizationSceneBuilder] Kein Areal für {behavior} gefunden — Label übersprungen.");
                continue;
            }

            var labelRoot = GameObject.Find($"Label_{name}") ?? CreateLabelObject(name, color);
            // WICHTIG: Bei einem Root-World-Space-Canvas bestimmt localPosition die
            // Weltposition — NICHT anchoredPosition (das gilt nur mit Eltern-RectTransform).
            // transform.position würde die X in anchoredPosition schreiben und alle Labels
            // lägen sichtbar auf (0,0) übereinander. Deshalb anchoredPosition nullen und
            // localPosition direkt setzen.
            var rt = labelRoot.GetComponent<RectTransform>();
            if (rt != null) { rt.anchoredPosition = Vector2.zero; rt.sizeDelta = new Vector2(760f, 150f); }
            var tmp = labelRoot.GetComponentInChildren<TMPro.TextMeshProUGUI>(true);
            if (tmp != null) tmp.enableWordWrapping = false;   // "Transformer" einzeilig
            labelRoot.transform.localScale = Vector3.one * 0.08f;
            labelRoot.transform.localPosition = new Vector3(anchor.x + 12f, 11f, anchor.z - 6f);
            labelRoot.transform.localRotation = Quaternion.Euler(45f, 0f, 0f);
            EditorUtility.SetDirty(labelRoot);
        }
    }

    static GameObject CreateLabelObject(string name, Color color)
    {
        var labelRoot = new GameObject($"Label_{name}");
        var canvas = labelRoot.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.WorldSpace;
        labelRoot.GetComponent<RectTransform>().sizeDelta = new Vector2(760f, 150f); // breit genug für "Transformer" einzeilig

        var bgGo = new GameObject("Background");
        bgGo.transform.SetParent(labelRoot.transform, false);
        var bgImage = bgGo.AddComponent<Image>();
        bgImage.color = new Color(0f, 0f, 0f, 0.55f);
        var bgRt = bgGo.GetComponent<RectTransform>();
        bgRt.anchorMin = Vector2.zero; bgRt.anchorMax = Vector2.one;
        bgRt.offsetMin = Vector2.zero; bgRt.offsetMax = Vector2.zero;

        var textGo = new GameObject("Text");
        textGo.transform.SetParent(labelRoot.transform, false);
        var tmp = textGo.AddComponent<TextMeshProUGUI>();
        tmp.text = name; tmp.fontSize = 100f; tmp.fontStyle = FontStyles.Bold;
        tmp.color = color; tmp.alignment = TextAlignmentOptions.Center;
        tmp.enableWordWrapping = false;   // "Transformer" nie umbrechen
        var textRt = textGo.GetComponent<RectTransform>();
        textRt.anchorMin = Vector2.zero; textRt.anchorMax = Vector2.one;
        textRt.offsetMin = Vector2.zero; textRt.offsetMax = Vector2.zero;

        Debug.Log($"[GeneralizationSceneBuilder] Label '{name}' erstellt.");
        return labelRoot;
    }

    /// <summary>
    /// Wendet den „Messe-Look" auf die Generalisierungstest-Szene an (fürs Video):
    /// Lava-Textur, mittelalterliche Wand-Textur, HDR-Himmel und Grasboden.
    /// Nutzt bewusst NICHT „Apply Full Polish" — das würde ein eigenes Kamera-Rig
    /// installieren und den 3-Wege-Umschalter (ModelComparisonCameraController)
    /// überschreiben; stattdessen nur „Nur HDR Sky".
    /// Der Grasboden wird als großer statischer Untergrund über ALLE drei Areale
    /// gelegt (die OutdoorGround-Folgekomponente würde ihn sonst auf ein Areal
    /// zentrieren und die anderen beiden über Leere schweben lassen).
    /// Beim Ausführen erscheinen ~3 Bestätigungsdialoge (mit OK bestätigen).
    /// </summary>
    [MenuItem("Training/Generalisierungstest: Video-Look anwenden (Texturen+Himmel+Boden)")]
    public static void ApplyVideoLook()
    {
        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);

        // 1. Material-Texturen — wirken auf die Kacheln ALLER drei Areale.
        RunMenu("Tools/Texturen/Lava-Textur anwenden");
        TuneLavaMaterial();   // molten-Look: kräftigeres Glühen, dunklere Basalt-Basis
        RunMenu("Tools/Texturen/Mittelalterliche Wand-Textur anwenden");
        SetupWallAndGoalMaterials();   // Goal leuchtend grün + texturierte Materialien den Kachel-Prefabs zuweisen
        SetupFloorMaterial();          // Steinboden (mossy_cobblestone) auf Floor- und Platform-Kacheln
        SetupHoleMaterial();           // Löcher als dunkler Abgrund

        // 2. HDR-Himmel (ohne Kamera-Rig).
        RunMenu("Tools/Visual Polish/Nur HDR Sky anwenden");

        // 3. Grasboden erzeugen, dann als großen statischen Boden über alle Areale legen.
        RunMenu("Tools/Boden/Gras-Boden einrichten");
        FixGroundForThreeAreas();

        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, TARGET_SCENE);
        AssetDatabase.SaveAssets();
        Debug.Log("[GeneralizationSceneBuilder] Video-Look angewendet: Lava-/Wand-Textur, HDR-Himmel, Grasboden über 3 Areale.");
    }

    static void RunMenu(string path)
    {
        if (!EditorApplication.ExecuteMenuItem(path))
            Debug.LogWarning($"[GeneralizationSceneBuilder] Menü nicht gefunden/fehlgeschlagen: {path}");
    }

    // Macht die Lava realistischer (molten): stärkeres, wärmeres HDR-Glühen der Risse
    // über die Emission-Map, dunklere Basalt-Basis, etwas mehr Oberflächenrelief.
    static void TuneLavaMaterial()
    {
        foreach (var matPath in new[] { "Assets/Materials/M_Lava01.mat", "Assets/Materials/Lava_Mat.mat" })
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>(matPath);
            if (mat == null) continue;

            mat.EnableKeyword("_EMISSION");
            mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
            // Helleres, leicht gelbstichiges Glühen für flüssige Lava (statt nur orange-rot).
            mat.SetColor("_EmissionColor", new Color(6.5f, 1.6f, 0.15f));
            // Dunkle Basalt-Basis, damit die glühenden Risse stärker kontrastieren.
            mat.SetColor("_Color", new Color(0.35f, 0.30f, 0.28f));
            mat.SetFloat("_Glossiness", 0.06f);
            mat.SetFloat("_Metallic",   0.00f);
            if (mat.HasProperty("_BumpScale")) mat.SetFloat("_BumpScale", 1.3f);
            EditorUtility.SetDirty(mat);
        }
        AssetDatabase.SaveAssets();
    }

    // Goal leuchtend grün (messe2) + weist die texturierten Materialien den Kachel-
    // Prefabs zu. Wand- und Goal-Prefab nutzen sonst das Unity-Default-Material,
    // d.h. das Texturieren von Wall_Mat/Goal_Mat allein wäre wirkungslos.
    static void SetupWallAndGoalMaterials()
    {
        var goalMat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Goal_Mat.mat");
        if (goalMat != null)
        {
            goalMat.EnableKeyword("_EMISSION");
            goalMat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
            goalMat.SetColor("_Color",         new Color(0.05f, 0.85f, 0.30f)); // mystisches Grün-Cyan
            goalMat.SetColor("_EmissionColor", new Color(0.20f, 3.50f, 0.70f)); // kräftiges magisches Leuchten
            goalMat.SetFloat("_Glossiness", 0.35f);
            goalMat.SetFloat("_Metallic",   0.00f);
            EditorUtility.SetDirty(goalMat);
        }
        AssetDatabase.SaveAssets();

        AssignMaterialToPrefab("Assets/Prefabs/Map/Wall.prefab",
            AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Wall_Mat.mat"));
        AssignMaterialToPrefab("Assets/Prefabs/Map/Goal.prefab", goalMat);
        AddMysticGlowToGoal();   // pulsierendes, mystisches Leuchten
    }

    // Hängt die MysticGlow-Komponente an das Goal-Prefab (pulsierende Emission).
    static void AddMysticGlowToGoal()
    {
        const string path = "Assets/Prefabs/Map/Goal.prefab";
        var root = PrefabUtility.LoadPrefabContents(path);
        if (root == null) return;
        var rend = root.GetComponentInChildren<Renderer>(true);
        if (rend != null && rend.GetComponent<MysticGlow>() == null)
            rend.gameObject.AddComponent<MysticGlow>();
        PrefabUtility.SaveAsPrefabAsset(root, path);
        PrefabUtility.UnloadPrefabContents(root);
        Debug.Log("[GeneralizationSceneBuilder] MysticGlow am Goal-Prefab.");
    }

    // Löcher als Abgrund: sehr dunkles, mattes Material (verschluckt Licht → wirkt tief).
    static void SetupHoleMaterial()
    {
        const string prefabPath = "Assets/Prefabs/Map/Obstacles/Hole_Placeholder.prefab";
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
        if (prefab == null) { Debug.LogWarning("[GeneralizationSceneBuilder] Hole_Placeholder.prefab nicht gefunden."); return; }
        var rend = prefab.GetComponentInChildren<Renderer>(true);
        var mat = rend != null ? rend.sharedMaterial : null;
        if (mat == null) { Debug.LogWarning("[GeneralizationSceneBuilder] Kein Hole-Material gefunden."); return; }

        mat.SetColor("_Color", new Color(0.012f, 0.012f, 0.018f)); // fast schwarz = Abgrund
        mat.SetFloat("_Glossiness", 0.0f);
        mat.SetFloat("_Metallic",   0.0f);
        mat.DisableKeyword("_EMISSION");
        mat.SetColor("_EmissionColor", Color.black);
        if (mat.HasProperty("_SpecColor")) mat.SetColor("_SpecColor", Color.black);
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
        Debug.Log($"[GeneralizationSceneBuilder] Abgrund-Material auf {mat.name} gesetzt.");
    }

    // Steinboden: Floor_Mat mit mossy_cobblestone (Poly Haven, CC0) texturieren und
    // dem Floor-Prefab zuweisen (nutzte Default-Material). Platform-Kacheln nutzen
    // ebenfalls Floor_Mat und werden dadurch automatisch mit-texturiert.
    static void SetupFloorMaterial()
    {
        const string diffPath = "Assets/Textures/Medieval/mossy_cobblestone/mossy_cobblestone_diff.jpg";
        const string norPath  = "Assets/Textures/Medieval/mossy_cobblestone/mossy_cobblestone_nor.jpg";

        var floorMat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Floor_Mat.mat");
        if (floorMat == null) { Debug.LogWarning("[GeneralizationSceneBuilder] Floor_Mat.mat nicht gefunden."); return; }

        EnsureNormalMapImport(norPath);
        var diff = AssetDatabase.LoadAssetAtPath<Texture2D>(diffPath);
        var nor  = AssetDatabase.LoadAssetAtPath<Texture2D>(norPath);

        if (diff != null) floorMat.SetTexture("_MainTex", diff);
        if (nor != null)
        {
            floorMat.EnableKeyword("_NORMALMAP");
            floorMat.SetTexture("_BumpMap", nor);
            floorMat.SetFloat("_BumpScale", 1.0f);
        }
        floorMat.SetColor("_Color", Color.white);
        floorMat.SetFloat("_Glossiness", 0.10f);
        floorMat.SetFloat("_Metallic",   0.00f);
        // Bodenkachel ist 1x1 Unit → 1 Steintextur pro Kachel.
        floorMat.SetTextureScale("_MainTex", Vector2.one);
        floorMat.SetTextureScale("_BumpMap", Vector2.one);
        EditorUtility.SetDirty(floorMat);
        AssetDatabase.SaveAssets();

        AssignMaterialToPrefab("Assets/Prefabs/Map/Floor.prefab", floorMat);
    }

    static void EnsureNormalMapImport(string path)
    {
        var imp = AssetImporter.GetAtPath(path) as TextureImporter;
        if (imp == null || imp.textureType == TextureImporterType.NormalMap) return;
        imp.textureType = TextureImporterType.NormalMap;
        imp.SaveAndReimport();
    }

    // Weist ALLEN MeshRenderer-Materialslots eines Prefabs ein Material zu (persistiert im Prefab).
    static void AssignMaterialToPrefab(string prefabPath, Material mat)
    {
        if (mat == null) { Debug.LogWarning($"[GeneralizationSceneBuilder] Material null für {prefabPath}"); return; }
        var root = PrefabUtility.LoadPrefabContents(prefabPath);
        if (root == null) { Debug.LogWarning($"[GeneralizationSceneBuilder] Prefab nicht ladbar: {prefabPath}"); return; }

        int slots = 0;
        foreach (var r in root.GetComponentsInChildren<MeshRenderer>(true))
        {
            var mats = r.sharedMaterials;
            for (int i = 0; i < mats.Length; i++) mats[i] = mat;
            r.sharedMaterials = mats;
            slots += mats.Length;
        }
        PrefabUtility.SaveAsPrefabAsset(root, prefabPath);
        PrefabUtility.UnloadPrefabContents(root);
        Debug.Log($"[GeneralizationSceneBuilder] '{mat.name}' auf {slots} Materialslot(s) in {System.IO.Path.GetFileName(prefabPath)} gesetzt.");
    }

    // Entfernt die laufzeit-folgende OutdoorGround-Komponente und legt die Grasboden-
    // Plane als großen statischen Untergrund zentriert über alle drei Areale.
    static void FixGroundForThreeAreas()
    {
        foreach (var og in Object.FindObjectsByType<OutdoorGround>(FindObjectsInactive.Include, FindObjectsSortMode.None))
            Object.DestroyImmediate(og);

        var plane = GameObject.Find("OutdoorGround");
        if (plane == null)
        {
            Debug.LogWarning("[GeneralizationSceneBuilder] Grasboden-Plane 'OutdoorGround' nicht gefunden — bitte 'Tools/Boden/Gras-Boden einrichten' separat ausführen.");
            return;
        }

        // Zentroid aller MapGeneratoren (= Mitte der drei Areale).
        var gens = Object.FindObjectsByType<MapGenerator>(FindObjectsInactive.Include, FindObjectsSortMode.None);
        Vector3 c = Vector3.zero;
        foreach (var g in gens) c += g.transform.position;
        if (gens.Length > 0) c /= gens.Length;

        plane.transform.position   = new Vector3(c.x, -0.02f, c.z);
        plane.transform.localScale = new Vector3(200f, 1f, 200f); // 2000×2000 Einheiten — deckt alle Areale + Rand
        EditorUtility.SetDirty(plane);

        // Textur-Tiling dichter setzen → Gras wirkt kleiner/feiner statt gestreckt.
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Ground_Mat.mat");
        if (mat != null)
        {
            float worldSize = plane.transform.localScale.x * 10f;
            float tiling = worldSize / 1.5f;   // ~1 Grastextur je 1,5 Einheiten (vorher je 4)
            mat.SetTextureScale("_MainTex", new Vector2(tiling, tiling));
            mat.SetTextureScale("_BumpMap", new Vector2(tiling, tiling));
            EditorUtility.SetDirty(mat);
        }
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
