using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Rendering;

/// One-click visual & audio polish for the Labyrinth project.
/// Menu: Tools → Visual Polish → Apply Full Polish
public static class VisualPolishSetup
{
    const string HdrTexPath = "Assets/Textures/Sky/farm_field_puresky_4k.hdr";
    const string SkyMatPath = "Assets/Materials/Skybox_HDR.mat";

    [MenuItem("Tools/Visual Polish/Apply Full Polish")]
    static void ApplyFullPolish()
    {
        bool hasSky = SetupHDRSky();
        SetupLighting(hasSky);
        SetupFog();
        SetupMaterials();
        SetupCamera();
        SetupMapFXSpawner();
        SetupAudioManager();
        SetupAgentAudio();
        SetupHumanAgent();
        SetupCameraRig(showDialog: false);

        AssetDatabase.SaveAssets();
AssetDatabase.Refresh();

var scene = SceneManager.GetActiveScene();

if (scene.IsValid() && scene.isLoaded)
{
    EditorSceneManager.MarkSceneDirty(scene);

    bool saved = EditorSceneManager.SaveScene(scene);

    if (!saved)
    {
        Debug.LogError("[VisualPolish] Scene could not be saved.");
    }
}
else
{
    Debug.LogError("[VisualPolish] Invalid scene.");
}
        Debug.Log("[VisualPolish] Full polish applied.");
        EditorUtility.DisplayDialog("Visual Polish",
            $"✓ HDR Sky: {(hasSky ? "farm_field_puresky_4k" : "NICHT GEFUNDEN")}\n" +
            "✓ Lighting konfiguriert\n" +
            "✓ Unendliche Graslandschaft (Nebel-Horizont)\n" +
            "✓ Materials verbessert\n" +
            "✓ Kamera: far clip = 2000\n" +
            "✓ MapFXSpawner hinzugefügt\n" +
            "✓ AudioManager (Wind, Schritte, Ziel, Lava)\n" +
            "✓ AgentAudio hinzugefügt\n" +
            "✓ Mensch-Modell für Agenten\n" +
            "✓ Kamera-Rig (Drohne/Ego/Front via Tab)\n\n" +
            "Auch ausführen:\n" +
            "• Tools/Boden/Gras-Boden einrichten\n" +
            "• Tools/Texturen/Lava-Textur generieren\n" +
            "• Tools/Texturen/Mittelalterliche Wand-Textur anwenden", "OK");
    }

    [MenuItem("Tools/Visual Polish/Nur HDR Sky anwenden")]
    static void ApplyHDRSkyOnly()
    {
        bool ok = SetupHDRSky();
        if (ok)
        {
            EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
            EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
            EditorUtility.DisplayDialog("HDR Sky", "✓ farm_field_puresky_4k.hdr als Skybox gesetzt.\nAmbient Lighting auf Skybox umgestellt.", "OK");
        }
        else
        {
            EditorUtility.DisplayDialog("HDR Sky – Fehler",
                $"HDR-Textur nicht gefunden:\n{HdrTexPath}\n\nStarte Unity neu damit die Datei importiert wird, dann erneut versuchen.", "OK");
        }
    }

    // ── HDR Sky ───────────────────────────────────────────────────────────────

    static bool SetupHDRSky()
    {
        // Force import if needed
        AssetDatabase.ImportAsset(HdrTexPath, ImportAssetOptions.Default);
        var hdrTex = AssetDatabase.LoadAssetAtPath<Texture2D>(HdrTexPath);
        if (hdrTex == null)
        {
            Debug.LogWarning($"[VisualPolish] HDR texture not found at {HdrTexPath}. Import it in Unity first.");
            return false;
        }

        // Ensure correct import settings (panoramic, linear)
        var importer = AssetImporter.GetAtPath(HdrTexPath) as TextureImporter;
        if (importer != null)
        {
            bool changed = false;
            if (importer.sRGBTexture)          { importer.sRGBTexture = false;         changed = true; }
            if (importer.textureShape != TextureImporterShape.Texture2D)
                                                { importer.textureShape = TextureImporterShape.Texture2D; changed = true; }
            if (importer.generateCubemap != TextureImporterGenerateCubemap.None)
                                                { importer.generateCubemap = TextureImporterGenerateCubemap.None; changed = true; }
            if (importer.maxTextureSize < 4096) { importer.maxTextureSize = 4096;      changed = true; }
            if (changed) { importer.SaveAndReimport(); hdrTex = AssetDatabase.LoadAssetAtPath<Texture2D>(HdrTexPath); }
        }

        // Create or update the skybox material
        var skyShader = Shader.Find("Skybox/Panoramic");
        if (skyShader == null)
        {
            Debug.LogError("[VisualPolish] Shader 'Skybox/Panoramic' not found.");
            return false;
        }

        Material skyMat = AssetDatabase.LoadAssetAtPath<Material>(SkyMatPath);
        if (skyMat == null)
        {
            skyMat = new Material(skyShader);
            AssetDatabase.CreateAsset(skyMat, SkyMatPath);
        }
        else
        {
            skyMat.shader = skyShader;
        }

        skyMat.SetTexture("_MainTex",  hdrTex);
        skyMat.SetColor("_Tint",       new Color(0.5f, 0.5f, 0.5f, 0.5f));
        skyMat.SetFloat("_Exposure",   1.15f);
        skyMat.SetFloat("_Rotation",   180f);   // rotate so sun aligns with directional light
        skyMat.SetFloat("_MirrorOnBack", 0f);
        skyMat.SetFloat("_Layout",     0f);     // 360°

        EditorUtility.SetDirty(skyMat);
        AssetDatabase.SaveAssets();

        // Apply to scene
        RenderSettings.skybox = skyMat;

        // Switch ambient to skybox-based GI for realistic lighting from the HDR
        RenderSettings.ambientMode      = AmbientMode.Skybox;
        RenderSettings.ambientIntensity = 1.0f;

        DynamicGI.UpdateEnvironment();
        return true;
    }

    // ── Lighting ───────────────────────────────────────────────────────────────

    static void SetupLighting(bool hasSky)
    {
        var lights = Object.FindObjectsOfType<Light>();
        Light sun = null;
        foreach (var l in lights)
            if (l.type == LightType.Directional) { sun = l; break; }

        if (sun == null)
        {
            var go = new GameObject("DirectionalLight");
            sun = go.AddComponent<Light>();
        }

        sun.type             = LightType.Directional;
        sun.color            = new Color(1.00f, 0.93f, 0.78f);   // warm afternoon gold
        sun.intensity        = 1.3f;
        sun.transform.rotation = Quaternion.Euler(52f, -30f, 0f); // sun angle matches HDR roughly
        sun.shadows          = LightShadows.Soft;
        sun.shadowStrength   = 0.72f;
        sun.shadowBias       = 0.04f;
        sun.shadowNormalBias = 0.35f;
        EditorUtility.SetDirty(sun);

        // If no HDR sky was found, fall back to gradient ambient
        if (!hasSky)
        {
            RenderSettings.ambientMode         = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor     = new Color(0.48f, 0.62f, 0.88f);
            RenderSettings.ambientEquatorColor = new Color(0.38f, 0.52f, 0.43f);
            RenderSettings.ambientGroundColor  = new Color(0.16f, 0.14f, 0.11f);
        }
    }

    // ── Camera ────────────────────────────────────────────────────────────────

    static void SetupCamera()
    {
        var cam = Camera.main ?? Object.FindObjectOfType<Camera>();
        if (cam == null) return;
        // Far clip must reach beyond the fog horizon so the distant ground is drawn
        if (cam.farClipPlane < 2000f) cam.farClipPlane = 2000f;
        EditorUtility.SetDirty(cam);
    }

    // ── Fog ───────────────────────────────────────────────────────────────────

    static void SetupFog()
    {
        RenderSettings.fog        = true;
        RenderSettings.fogMode    = FogMode.ExponentialSquared;
        // Horizon color matches the HDR sky's mid-horizon tone (warm blue-gray)
        RenderSettings.fogColor   = new Color(0.60f, 0.68f, 0.80f);
        // Density 0.010: ~98% opaque at 300 units → ground edge never visible
        RenderSettings.fogDensity = 0.010f;
    }

    // ── Materials ─────────────────────────────────────────────────────────────

    static void SetupMaterials()
    {
        ImproveLavaMaterial();
        ImproveGoalMaterial();
        ImproveFloorMaterial();
        ImproveWallMaterial();
    }

    static void ImproveLavaMaterial()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Lava_Mat.mat");
        if (mat == null) return;
        mat.EnableKeyword("_EMISSION");
        mat.SetColor("_Color",         new Color(0.85f, 0.20f, 0.00f));
        mat.SetColor("_EmissionColor", new Color(4.5f,  0.90f, 0.00f));
        mat.SetFloat("_Glossiness",    0.55f);
        mat.SetFloat("_Metallic",      0.05f);
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
    }

    static void ImproveGoalMaterial()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Goal_Mat.mat");
        if (mat == null) return;
        mat.EnableKeyword("_EMISSION");
        mat.SetColor("_Color",         new Color(0.05f, 0.90f, 0.15f));
        mat.SetColor("_EmissionColor", new Color(0.15f, 3.2f,  0.30f));
        mat.SetFloat("_Glossiness",    0.80f);
        mat.SetFloat("_Metallic",      0.10f);
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
    }

    static void ImproveFloorMaterial()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Floor_Mat.mat");
        if (mat == null) return;
        mat.SetColor("_Color",      new Color(0.55f, 0.52f, 0.48f));
        mat.SetFloat("_Glossiness", 0.28f);
        mat.SetFloat("_Metallic",   0.00f);
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
    }

    static void ImproveWallMaterial()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Wall_Mat.mat");
        if (mat == null) return;
        mat.SetFloat("_Glossiness", 0.10f);
        mat.SetFloat("_BumpScale",  0.85f);
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
    }

    // ── MapFXSpawner ──────────────────────────────────────────────────────────

    static void SetupMapFXSpawner()
    {
        var mapGen = Object.FindObjectOfType<MapGenerator>();
        if (mapGen == null) { Debug.LogWarning("[VisualPolish] MapGenerator not found."); return; }
        if (mapGen.GetComponent<MapFXSpawner>() == null)
        {
            mapGen.gameObject.AddComponent<MapFXSpawner>();
            EditorUtility.SetDirty(mapGen.gameObject);
        }
    }

    // ── AudioManager ─────────────────────────────────────────────────────────

    static void SetupAudioManager()
    {
        if (Object.FindObjectOfType<AudioManager>() != null) return;
        var go = new GameObject("AudioManager");
        go.AddComponent<AudioManager>();
        EditorUtility.SetDirty(go);
    }

    // ── AgentAudio ────────────────────────────────────────────────────────────

    static void SetupAgentAudio()
    {
        var agent = Object.FindObjectOfType<LabyrinthAgent>();
        if (agent == null) return;
        if (agent.GetComponent<AgentAudio>() == null)
        {
            agent.gameObject.AddComponent<AgentAudio>();
            EditorUtility.SetDirty(agent.gameObject);
        }
    }

    // ── Human Agent ───────────────────────────────────────────────────────────

    static void SetupHumanAgent()
    {
        var agent = Object.FindObjectOfType<LabyrinthAgent>();
        if (agent == null) return;
        if (agent.GetComponent<HumanAgentVisual>() == null)
        {
            agent.gameObject.AddComponent<HumanAgentVisual>();
            EditorUtility.SetDirty(agent.gameObject);
        }
    }

    // ── Camera Rig ────────────────────────────────────────────────────────────

    [MenuItem("Tools/Visual Polish/Kamera-Rig einrichten")]
    static void SetupCameraRigMenu() => SetupCameraRig(showDialog: true);

    static void SetupCameraRig(bool showDialog = false)
    {
        var switcher = Object.FindObjectOfType<CameraSwitcher>();
        if (switcher == null)
        {
            Debug.LogWarning("[VisualPolish] CameraSwitcher not found in scene. Attach it to your main camera rig first.");
            if (showDialog)
                EditorUtility.DisplayDialog("Kamera-Rig", "CameraSwitcher nicht in der Szene gefunden.\nFüge ihn zuerst dem Kamera-Objekt hinzu.", "OK");
            return;
        }

        // Create FrontCamera if not already assigned
        if (switcher.frontCamera == null)
        {
            var existing = GameObject.Find("FrontCamera");
            Camera frontCam;
            if (existing != null)
            {
                frontCam = existing.GetComponent<Camera>() ?? existing.AddComponent<Camera>();
            }
            else
            {
                var go = new GameObject("FrontCamera");
                frontCam = go.AddComponent<Camera>();
            }

            frontCam.nearClipPlane = 0.05f;
            frontCam.farClipPlane  = 2000f;
            frontCam.enabled       = false;

            if (frontCam.GetComponent<FrontFollowCamera>() == null)
                frontCam.gameObject.AddComponent<FrontFollowCamera>();

            var agent = Object.FindObjectOfType<LabyrinthAgent>();
            if (agent != null)
            {
                var fc = frontCam.GetComponent<FrontFollowCamera>();
                if (fc != null) fc.target = agent.transform;
            }

            switcher.frontCamera = frontCam;
            EditorUtility.SetDirty(switcher);
            EditorUtility.SetDirty(frontCam.gameObject);
        }

        // Auto-assign drone/ego cameras by name if missing
        if (switcher.droneCamera == null)
        {
            var go = GameObject.Find("DroneCamera") ?? GameObject.Find("Drone Camera");
            if (go != null) { switcher.droneCamera = go.GetComponent<Camera>(); EditorUtility.SetDirty(switcher); }
        }
        if (switcher.egoCamera == null)
        {
            var go = GameObject.Find("EgoCamera") ?? GameObject.Find("Ego Camera");
            if (go != null) { switcher.egoCamera = go.GetComponent<Camera>(); EditorUtility.SetDirty(switcher); }
        }

        if (showDialog)
        {
            EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
            EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
            EditorUtility.DisplayDialog("Kamera-Rig",
                "✓ FrontCamera erstellt und verdrahtet\n" +
                "✓ CameraSwitcher aktualisiert\n\n" +
                "Tab wechselt: Drohne → Ego (POV) → Front (Gesicht)", "OK");
        }
    }
}
