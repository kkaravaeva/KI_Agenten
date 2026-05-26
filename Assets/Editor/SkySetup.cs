using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

/// Richtet einen realistischen Himmel ein (Built-in RP, Skybox/Procedural).
/// Aufruf: Tools → Himmel → Realistischen Himmel einrichten
public static class SkySetup
{
    const string SkyMatPath = "Assets/Materials/Sky_Procedural.mat";

    // ── Presets ───────────────────────────────────────────────────────────────

    // Klarer Nachmittag – warme Sonne, tiefblauer Himmel
    static readonly SkyPreset Afternoon = new SkyPreset
    {
        name              = "Klarer Nachmittag",
        sunSize           = 0.04f,
        sunConvergence    = 10f,
        atmosphereThick   = 0.85f,
        skyTint           = new Color(0.50f, 0.52f, 0.56f),
        groundColor       = new Color(0.24f, 0.21f, 0.17f),
        exposure          = 1.25f,
        sunRotation       = new Vector3(52f, -28f, 0f),
        sunColor          = new Color(1.00f, 0.95f, 0.82f),
        sunIntensity      = 1.15f,
        ambientIntensity  = 1.0f,
        fogEnabled        = true,
        fogColor          = new Color(0.72f, 0.78f, 0.88f),
        fogStart          = 30f,
        fogEnd            = 200f,
    };

    // Bewölkter Tag – diffuses Licht, heller grauer Himmel
    static readonly SkyPreset Overcast = new SkyPreset
    {
        name              = "Bewölkt",
        sunSize           = 0.06f,
        sunConvergence    = 3f,
        atmosphereThick   = 1.6f,
        skyTint           = new Color(0.58f, 0.60f, 0.62f),
        groundColor       = new Color(0.28f, 0.27f, 0.25f),
        exposure          = 1.0f,
        sunRotation       = new Vector3(60f, -10f, 0f),
        sunColor          = new Color(0.92f, 0.92f, 0.95f),
        sunIntensity      = 0.75f,
        ambientIntensity  = 1.1f,
        fogEnabled        = true,
        fogColor          = new Color(0.75f, 0.76f, 0.78f),
        fogStart          = 20f,
        fogEnd            = 120f,
    };

    // Abendrot – warme Orange-Töne, tiefer Sonnenstand
    static readonly SkyPreset Sunset = new SkyPreset
    {
        name              = "Abenddämmerung",
        sunSize           = 0.06f,
        sunConvergence    = 8f,
        atmosphereThick   = 1.1f,
        skyTint           = new Color(0.55f, 0.45f, 0.40f),
        groundColor       = new Color(0.18f, 0.14f, 0.10f),
        exposure          = 1.1f,
        sunRotation       = new Vector3(12f, -40f, 0f),
        sunColor          = new Color(1.00f, 0.65f, 0.30f),
        sunIntensity      = 0.90f,
        ambientIntensity  = 0.85f,
        fogEnabled        = true,
        fogColor          = new Color(0.75f, 0.50f, 0.35f),
        fogStart          = 15f,
        fogEnd            = 100f,
    };

    // ── Menu Items ────────────────────────────────────────────────────────────

    [MenuItem("Tools/Himmel/Klarer Nachmittag")]
    static void SetAfternoon()  => Apply(Afternoon);

    [MenuItem("Tools/Himmel/Bewölkt")]
    static void SetOvercast()   => Apply(Overcast);

    [MenuItem("Tools/Himmel/Abenddämmerung")]
    static void SetSunset()     => Apply(Sunset);

    // ── Kernlogik ─────────────────────────────────────────────────────────────

    static void Apply(SkyPreset p)
    {
        // 1. Skybox-Material erzeugen / aktualisieren
        var mat = AssetDatabase.LoadAssetAtPath<Material>(SkyMatPath);
        if (mat == null)
        {
            mat = new Material(Shader.Find("Skybox/Procedural"));
            AssetDatabase.CreateAsset(mat, SkyMatPath);
        }

        mat.SetFloat ("_SunSize",           p.sunSize);
        mat.SetFloat ("_SunSizeConvergence", p.sunConvergence);
        mat.SetFloat ("_AtmosphereThickness",p.atmosphereThick);
        mat.SetColor ("_SkyTint",            p.skyTint);
        mat.SetColor ("_GroundColor",        p.groundColor);
        mat.SetFloat ("_Exposure",           p.exposure);
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();

        // 2. Skybox in RenderSettings
        RenderSettings.skybox           = mat;
        RenderSettings.ambientMode      = AmbientMode.Skybox;
        RenderSettings.ambientIntensity = p.ambientIntensity;
        RenderSettings.sun              = FindSun();

        // 3. Fog
        RenderSettings.fog          = p.fogEnabled;
        RenderSettings.fogMode      = FogMode.Linear;
        RenderSettings.fogColor     = p.fogColor;
        RenderSettings.fogStartDistance = p.fogStart;
        RenderSettings.fogEndDistance   = p.fogEnd;

        // 4. Directional Light (Sonne) anpassen
        var sun = FindSun();
        if (sun != null)
        {
            sun.transform.rotation = Quaternion.Euler(p.sunRotation);
            sun.color              = p.sunColor;
            sun.intensity          = p.sunIntensity;
            sun.shadows            = LightShadows.Soft;
            sun.shadowStrength     = 0.75f;
            sun.shadowBias         = 0.04f;
            EditorUtility.SetDirty(sun);
        }

        // 5. Ambient neu backen (nur Skybox-Probe, kein Full-Bake)
        DynamicGI.UpdateEnvironment();

        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
        Debug.Log($"[SkySetup] Preset '{p.name}' angewandt.");
    }

    static Light FindSun()
    {
        foreach (var l in Object.FindObjectsOfType<Light>())
            if (l.type == LightType.Directional) return l;
        return null;
    }

    // ── Preset-Datenklasse ────────────────────────────────────────────────────

    class SkyPreset
    {
        public string name;
        // Skybox/Procedural
        public float sunSize, sunConvergence, atmosphereThick, exposure;
        public Color skyTint, groundColor;
        // Licht
        public Vector3 sunRotation;
        public Color   sunColor;
        public float   sunIntensity, ambientIntensity;
        // Fog
        public bool  fogEnabled;
        public Color fogColor;
        public float fogStart, fogEnd;
    }
}
