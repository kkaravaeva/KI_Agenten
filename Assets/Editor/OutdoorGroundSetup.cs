using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class OutdoorGroundSetup
{
    const string AlbedoPath   = "Assets/Textures/Ground_Albedo.png";
    const string NormalPath   = "Assets/Textures/Ground_Normal.png";
    const string MatPath      = "Assets/Materials/Ground_Mat.mat";
    const string PlaneName    = "OutdoorGround";

    [MenuItem("Tools/Boden/Gras-Boden einrichten")]
    static void Setup()
    {
        if (!Directory.Exists(Path.Combine(Application.dataPath, "Textures")))
            Directory.CreateDirectory(Path.Combine(Application.dataPath, "Textures"));

        const int Res = 1024;
        var albedo = new Texture2D(Res, Res, TextureFormat.RGB24, true);
        var normal = new Texture2D(Res, Res, TextureFormat.RGB24, true);

        for (int py = 0; py < Res; py++)
        for (int px = 0; px < Res; px++)
        {
            float u = (float)px / Res;
            float v = (float)py / Res;
            albedo.SetPixel(px, py, Albedo(u, v));
            normal.SetPixel(px, py, NormalPixel(u, v, 1f / Res));
        }

        albedo.Apply();
        normal.Apply();

        SavePng(albedo, AlbedoPath);
        SavePng(normal, NormalPath);
        AssetDatabase.Refresh();

        // Normal-Map Import-Typ setzen
        var nimport = AssetImporter.GetAtPath(NormalPath) as TextureImporter;
        if (nimport != null)
        {
            nimport.textureType = TextureImporterType.NormalMap;
            nimport.SaveAndReimport();
        }

        // Material
        var mat = AssetDatabase.LoadAssetAtPath<Material>(MatPath);
        if (mat == null)
        {
            mat = new Material(Shader.Find("Standard"));
            AssetDatabase.CreateAsset(mat, MatPath);
        }
        mat.SetTexture("_MainTex",  AssetDatabase.LoadAssetAtPath<Texture2D>(AlbedoPath));
        mat.SetTexture("_BumpMap",  AssetDatabase.LoadAssetAtPath<Texture2D>(NormalPath));
        mat.SetFloat("_BumpScale",  0.7f);
        mat.SetFloat("_Glossiness", 0.03f);
        mat.EnableKeyword("_NORMALMAP");
        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();

        // Ground-Plane in der Szene anlegen / finden
        var plane = GameObject.Find(PlaneName);
        if (plane == null)
        {
            plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
            plane.name = PlaneName;
        }
        plane.GetComponent<MeshRenderer>().sharedMaterial = mat;
        plane.transform.position   = new Vector3(0f, -0.02f, 0f);
        plane.transform.localScale = new Vector3(600f, 1f, 600f); // 6000×6000 Einheiten — reicht bis zum Nebel-Horizont

        // OutdoorGround-Komponente auf MapGenerator
        var mapGen = Object.FindObjectOfType<MapGenerator>();
        if (mapGen != null)
        {
            var og = mapGen.GetComponent<OutdoorGround>();
            if (og == null) og = mapGen.gameObject.AddComponent<OutdoorGround>();
            og.groundPlane = plane;
            og.extraBorder = 100f;

            Bounds b    = mapGen.GetWorldBounds();
            float  size = Mathf.Max(b.size.x, b.size.z) + 200f;
            plane.transform.position   = new Vector3(b.center.x, -0.02f, b.center.z);
            plane.transform.localScale = new Vector3(size / 10f, 1f, size / 10f);

            float tiling = size / 4f;
            mat.SetTextureScale("_MainTex", new Vector2(tiling, tiling));
            mat.SetTextureScale("_BumpMap", new Vector2(tiling, tiling));
            EditorUtility.SetDirty(mat);
            AssetDatabase.SaveAssets();

            EditorUtility.SetDirty(mapGen.gameObject);
        }

        EditorUtility.SetDirty(plane);
        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
        Debug.Log("[OutdoorGroundSetup] Gras-Boden eingerichtet.");
    }

    [MenuItem("Tools/Boden/Gras-Boden entfernen")]
    static void Remove()
    {
        var plane = GameObject.Find(PlaneName);
        if (plane != null) Undo.DestroyObjectImmediate(plane);

        var mapGen = Object.FindObjectOfType<MapGenerator>();
        if (mapGen != null)
        {
            var og = mapGen.GetComponent<OutdoorGround>();
            if (og != null) Undo.DestroyObjectImmediate(og);
        }

        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
        Debug.Log("[OutdoorGroundSetup] Gras-Boden entfernt.");
    }

    // ── Textur-Berechnung ──────────────────────────────────────────────────────

    static Color Albedo(float u, float v)
    {
        float stone = StoneBlend(u, v);
        return Color.Lerp(GrassColor(u, v), StoneColor(u, v), stone);
    }

    static float Height(float u, float v)
    {
        float stone = StoneBlend(u, v);

        float leanAngle = FBM(u * 2.5f, v * 2.5f, 3, 0.5f) * Mathf.PI * 2f;
        float lx = Mathf.Cos(leanAngle), ly = Mathf.Sin(leanAngle);
        float perp  = u * (-ly) + v * lx;
        float along = u *   lx  + v * ly;
        float phase = FBM(perp * 28f + 3.7f, along * 7f + 1.1f, 2, 0.5f);
        float bladeH = Mathf.Pow(
            Mathf.Abs(Mathf.Sin((perp * 65f + phase * 3.5f) * Mathf.PI)), 1.8f) * 0.022f;

        float grassH = FBM(u * 4f, v * 4f, 4, 0.50f) * 0.028f + bladeH;
        float stoneH = FBM(u * 8f, v * 8f, 4, 0.50f) * 0.040f
                     + FBM(u * 22f, v * 22f, 3, 0.40f) * 0.020f;
        return Mathf.Lerp(grassH, stoneH, stone);
    }

    static Color NormalPixel(float u, float v, float step)
    {
        float hR = Height(u + step, v);
        float hL = Height(u - step, v);
        float hU = Height(u, v + step);
        float hD = Height(u, v - step);
        Vector3 n = new Vector3((hL - hR) * 120f, 1f, (hD - hU) * 120f);
        n.Normalize();
        return new Color(n.x * 0.5f + 0.5f, n.z * 0.5f + 0.5f, n.y * 0.5f + 0.5f);
    }

    static Color GrassColor(float u, float v)
    {
        // ── Großflächige Farbzonen ─────────────────────────────────────────────
        float zone    = FBM(u * 1.5f, v * 1.5f, 5, 0.55f);
        float wetness = FBM(u * 2.2f + 5.3f, v * 2.2f + 1.9f, 4, 0.52f);

        // ── Trockene / kahle Flecken ───────────────────────────────────────────
        float dryMask  = Mathf.Clamp01((FBM(u * 3f + 11.3f, v * 3f + 4.7f, 4, 0.52f) - 0.62f) * 3.5f);
        float bareMask = Mathf.Clamp01((FBM(u * 8f +  2.1f, v * 8f + 8.3f, 3, 0.50f) - 0.73f) * 6.0f);

        // ── Grashalm-Simulation ────────────────────────────────────────────────
        // Langsam wechselnde Neigungsrichtung per Patch
        float leanAngle = FBM(u * 2.5f, v * 2.5f, 3, 0.5f) * Mathf.PI * 2f;
        float lx = Mathf.Cos(leanAngle), ly = Mathf.Sin(leanAngle);
        float perp  = u * (-ly) + v * lx;   // quer zu den Halmen
        float along = u *   lx  + v * ly;   // entlang der Halme

        // Zufälliger Phasenversatz pro Halm-Spalte (verhindert Tiling-Muster)
        float phase = FBM(perp * 28f + 3.7f, along * 7f + 1.1f, 2, 0.5f);

        // Feine Streifen quer zur Neigungsrichtung (Halm-Kanten)
        float bladeRaw = Mathf.Abs(Mathf.Sin((perp * 65f + phase * 3.5f) * Mathf.PI));
        float bladeTip = Mathf.Pow(bladeRaw, 2.0f);

        // Entlang-Halm Variation (Basis dunkler, Spitze heller)
        float bladeAlong = FBM(perp * 22f + 0.5f, along * 18f, 3, 0.48f);
        float bladeShade = bladeAlong * 0.28f + bladeTip * 0.22f;

        // ── Farbpalette ────────────────────────────────────────────────────────
        Color veryDark = new Color(0.04f, 0.12f, 0.03f);
        Color dark     = new Color(0.08f, 0.22f, 0.06f);
        Color mid      = new Color(0.14f, 0.35f, 0.09f);
        Color bright   = new Color(0.24f, 0.50f, 0.12f);
        Color yellow   = new Color(0.40f, 0.54f, 0.11f);
        Color dry      = new Color(0.55f, 0.50f, 0.17f);
        Color straw    = new Color(0.64f, 0.56f, 0.22f);
        Color earth    = new Color(0.40f, 0.31f, 0.18f);

        float zt = zone * 0.68f + wetness * 0.32f;
        Color baseColor;
        if      (zt < 0.22f) baseColor = Color.Lerp(veryDark, dark,   zt / 0.22f);
        else if (zt < 0.48f) baseColor = Color.Lerp(dark,     mid,    (zt - 0.22f) / 0.26f);
        else if (zt < 0.70f) baseColor = Color.Lerp(mid,      bright, (zt - 0.48f) / 0.22f);
        else if (zt < 0.85f) baseColor = Color.Lerp(bright,   yellow, (zt - 0.70f) / 0.15f);
        else                 baseColor = Color.Lerp(yellow,   dry,    (zt - 0.85f) / 0.15f);

        // Halm-Shading: dunkle Zwischenräume, helle Kanten
        float s = 0.58f + bladeShade * 0.84f;
        baseColor = new Color(
            Mathf.Clamp01(baseColor.r * s),
            Mathf.Clamp01(baseColor.g * s),
            Mathf.Clamp01(baseColor.b * s));

        Color withDry  = Color.Lerp(baseColor, Color.Lerp(dry, straw, dryMask * 0.5f), dryMask  * 0.65f);
        Color withBare = Color.Lerp(withDry,   earth,                                   bareMask * 0.50f);
        return withBare;
    }

    static float StoneBlend(float u, float v)
    {
        const float freq = 2.5f; // niedrigere Dichte wegen höherem Tiling
        float cx = u * freq, cz = v * freq;
        int   ix = Mathf.FloorToInt(cx), iz = Mathf.FloorToInt(cz);
        float fx = cx - ix,              fz = cz - iz;

        float h = Hash2(ix, iz);
        if (h > 0.80f)
        {
            float dx = fx - 0.5f + Mathf.Sin(u * 27f + v * 13f) * 0.07f;
            float dz = fz - 0.5f + Mathf.Cos(u * 19f + v * 31f) * 0.07f;
            float r  = Mathf.Sqrt(dx * dx + dz * dz);
            float radius = 0.25f + (h - 0.80f) * 1.0f;
            if (r < radius)
                return Mathf.SmoothStep(1f, 0f, r / radius);
        }
        return 0f;
    }

    static Color StoneColor(float u, float v)
    {
        float t = FBM(u * 6f, v * 6f, 5, 0.50f) * 0.6f
                + FBM(u * 18f, v * 18f, 3, 0.45f) * 0.4f;

        Color dark   = new Color(0.28f, 0.26f, 0.24f);
        Color mid    = new Color(0.48f, 0.46f, 0.43f);
        Color bright = new Color(0.65f, 0.63f, 0.60f);
        Color moss   = new Color(0.35f, 0.40f, 0.25f);

        float mossMix = Mathf.Clamp01((FBM(u * 9f + 5.1f, v * 9f + 3.7f, 3, 0.5f) - 0.55f) * 3f);
        Color baseStone = t < 0.45f
            ? Color.Lerp(dark, mid, t / 0.45f)
            : Color.Lerp(mid, bright, (t - 0.45f) / 0.55f);

        return Color.Lerp(baseStone, moss, mossMix * 0.38f);
    }

    // ── Noise ─────────────────────────────────────────────────────────────────

    static float FBM(float x, float y, int octaves, float persistence)
    {
        float val = 0f, amp = 0.5f, freq = 1f, max = 0f;
        for (int i = 0; i < octaves; i++)
        {
            val += Mathf.PerlinNoise(x * freq, y * freq) * amp;
            max  += amp;
            amp  *= persistence;
            freq *= 2f;
        }
        return val / max;
    }

    static float Hash2(int x, int y)
        => Mathf.Abs(Mathf.Sin(x * 127.1f + y * 311.7f) * 43758.5453f) % 1f;

    // ── IO ────────────────────────────────────────────────────────────────────

    static void SavePng(Texture2D tex, string assetPath)
    {
        string full = Path.Combine(Application.dataPath,
            assetPath.Substring("Assets/".Length));
        File.WriteAllBytes(full, tex.EncodeToPNG());
    }
}
