using System.IO;
using UnityEditor;
using UnityEngine;

/// Generiert eine prozedurale, realistische Betonwand-Textur (Albedo + Normal Map)
/// mit Algen, Rissen und Löchern. Aufruf: Tools → Texturen → Wand-Textur generieren
public static class WallTextureGenerator
{
    const string TextureDir   = "Assets/Textures";
    const string AlbedoPath   = "Assets/Textures/Wall_Albedo.png";
    const string NormalPath   = "Assets/Textures/Wall_Normal.png";
    const string MaterialPath = "Assets/Materials/Wall_Mat.mat";
    const int    Res           = 1024;

    [MenuItem("Tools/Texturen/Wand-Textur generieren")]
    static void Generate()
    {
        if (!AssetDatabase.IsValidFolder(TextureDir))
            AssetDatabase.CreateFolder("Assets", "Textures");

        EditorUtility.DisplayProgressBar("Wand-Textur", "Albedo …", 0f);
        var albedoTex = BuildAlbedo();

        EditorUtility.DisplayProgressBar("Wand-Textur", "Normal Map …", 0.6f);
        var normalTex = BuildNormalMap();

        EditorUtility.DisplayProgressBar("Wand-Textur", "Speichern …", 0.92f);
        SavePng(albedoTex, AlbedoPath);
        SavePng(normalTex, NormalPath);
        Object.DestroyImmediate(albedoTex);
        Object.DestroyImmediate(normalTex);
        EditorUtility.ClearProgressBar();

        AssetDatabase.Refresh();
        var ni = (TextureImporter)AssetImporter.GetAtPath(NormalPath);
        if (ni != null) { ni.textureType = TextureImporterType.NormalMap; ni.SaveAndReimport(); }

        ApplyToMaterial();
        Debug.Log("[WallTextureGenerator] Fertig.");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ALBEDO
    // ═══════════════════════════════════════════════════════════════════════════

    static Texture2D BuildAlbedo()
    {
        var tex = new Texture2D(Res, Res, TextureFormat.RGB24, mipChain: true);
        for (int y = 0; y < Res; y++)
            for (int x = 0; x < Res; x++)
                tex.SetPixel(x, y, AlbedoAt((float)x / Res, (float)y / Res));
        tex.Apply();
        return tex;
    }

    static Color AlbedoAt(float u, float v)
    {
        // ── Beton-Basis ───────────────────────────────────────────────────────
        float macro  = Fbm(u * 1.3f + 0.17f, v * 1.1f + 0.31f, 6);
        float mid    = Fbm(u * 4.7f + 7.3f,  v * 3.9f + 2.1f,  4);
        float fine   = Fbm(u * 19f  + 3.5f,  v * 17f  + 8.2f,  3);
        float stain  = Mathf.Pow(Mathf.Max(0f, Fbm(u * 0.35f + 1.3f, v * 9.5f + 0.7f, 4) - 0.48f) * 1.92f, 2.5f);
        float weather= Mathf.Pow(Mathf.Max(0f, Fbm(u * 2.3f + 5.7f,  v * 1.9f + 3.3f, 4) - 0.42f) * 1.72f, 2f);
        float temp   = Fbm(u * 0.6f + 9.1f, v * 0.7f + 4.3f, 2);

        var lightConc = new Color(0.76f, 0.73f, 0.69f);
        var midConc   = new Color(0.53f, 0.51f, 0.48f);
        var darkConc  = new Color(0.30f, 0.28f, 0.26f);
        var stainCol  = new Color(0.19f, 0.17f, 0.15f);

        Color c = Color.Lerp(midConc, lightConc, macro);
        c = Color.Lerp(c, Color.Lerp(darkConc, c, 0.55f), mid * 0.35f);
        float grain = (fine - 0.5f) * 0.07f;
        c = new Color(c.r + grain, c.g + grain * 0.95f, c.b + grain * 0.9f);
        if (temp > 0.55f) c = Color.Lerp(c, new Color(0.65f, 0.61f, 0.52f), (temp - 0.55f) * 0.6f);
        else if (temp < 0.45f) c = Color.Lerp(c, new Color(0.55f, 0.57f, 0.64f), (0.45f - temp) * 0.5f);
        c = Color.Lerp(c, stainCol, stain * 0.65f);
        c = Color.Lerp(c, darkConc, weather * 0.5f);

        // ── Algen ─────────────────────────────────────────────────────────────
        // Wächst bevorzugt unten (v klein = Boden) und in feuchten Bereichen
        float algaeBase = Fbm(u * 2.2f + 11.3f, v * 1.8f + 7.7f, 5);
        float algaeMask = Mathf.Pow(Mathf.Max(0f, algaeBase - 0.44f) * 1.79f, 1.8f);
        // Feuchtigkeit & Bodenbereich verstärken Algen
        float moistBoost = stain * 0.5f + Mathf.Clamp01(1f - v * 2.2f) * 0.6f;
        algaeMask = Mathf.Clamp01(algaeMask + moistBoost * algaeMask);

        float algaeVar = Fbm(u * 6.1f + 4.4f, v * 5.3f + 9.9f, 3); // Farbtöne variieren
        var algaeDark  = new Color(0.10f, 0.22f, 0.07f);
        var algaeMid   = new Color(0.18f, 0.32f, 0.10f);
        var algaeLight = new Color(0.28f, 0.41f, 0.14f);
        var algaeBrown = new Color(0.20f, 0.23f, 0.09f); // ältere, abgestorbene Algen
        Color algaeColor = Color.Lerp(
            Color.Lerp(algaeDark, algaeMid,  algaeVar),
            Color.Lerp(algaeLight, algaeBrown, Fbm(u * 3.3f + 2.2f, v * 2.8f + 6.1f, 2)),
            Fbm(u * 1.1f + 8.8f, v * 0.9f + 3.5f, 2));

        c = Color.Lerp(c, algaeColor, algaeMask * 0.85f);

        // ── Risse ─────────────────────────────────────────────────────────────
        // Ridge-Noise erzeugt netzartige Linien
        float crackA = Ridge(u * 7.3f + 2.1f, v * 6.9f + 5.3f);
        float crackB = Ridge(u * 13f  + 8.7f, v * 11f  + 1.9f);
        float crackC = Ridge(u * 4.1f + 0.5f, v * 19f  + 4.4f); // feine Haarrisse
        float crack  = Mathf.Max(crackA * 0.9f, Mathf.Max(crackB * 0.75f, crackC * 0.5f));
        crack = Mathf.Pow(Mathf.Max(0f, crack - 0.78f) * 4.76f, 2f);

        var crackColor = new Color(0.06f, 0.05f, 0.04f);
        c = Color.Lerp(c, crackColor, crack * 0.9f);

        // ── Löcher / Ausbrüche ────────────────────────────────────────────────
        float hole      = HolesAt(u, v);
        float holeEdge  = HoleEdgeAt(u, v);   // aufgerissener Rand
        var   holeInner = new Color(0.03f, 0.03f, 0.02f);
        var   holeRim   = new Color(0.18f, 0.16f, 0.14f);
        c = Color.Lerp(c, holeRim,   holeEdge * 0.6f);
        c = Color.Lerp(c, holeInner, hole     * 1.0f);

        return new Color(Mathf.Clamp01(c.r), Mathf.Clamp01(c.g), Mathf.Clamp01(c.b), 1f);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NORMAL MAP
    // ═══════════════════════════════════════════════════════════════════════════

    static Texture2D BuildNormalMap()
    {
        var tex = new Texture2D(Res, Res, TextureFormat.RGB24, mipChain: true);
        float eps = 1f / Res;
        for (int y = 0; y < Res; y++)
            for (int x = 0; x < Res; x++)
            {
                float u = (float)x / Res;
                float v = (float)y / Res;
                float h  = HeightAt(u,       v);
                float hx = HeightAt(u + eps, v);
                float hy = HeightAt(u,       v + eps);
                var n = new Vector3((h - hx) * 8f, (h - hy) * 8f, 1f).normalized;
                tex.SetPixel(x, y, new Color(n.x * 0.5f + 0.5f,
                                             n.y * 0.5f + 0.5f,
                                             n.z * 0.5f + 0.5f, 1f));
            }
        tex.Apply();
        return tex;
    }

    // Höhenfeld für Normal Map: Beton + Risse (Vertiefungen) + Löcher (tiefe Mulden)
    static float HeightAt(float u, float v)
    {
        float base_ = Fbm(u * 1.3f + 0.17f, v * 1.1f + 0.31f, 5) * 0.6f
                    + Fbm(u * 19f  + 3.5f,  v * 17f  + 8.2f,  3) * 0.2f;

        // Risse als Vertiefungen
        float crackA = Ridge(u * 7.3f + 2.1f, v * 6.9f + 5.3f);
        float crackB = Ridge(u * 13f  + 8.7f, v * 11f  + 1.9f);
        float crack  = Mathf.Max(crackA, crackB);
        crack = Mathf.Pow(Mathf.Max(0f, crack - 0.78f) * 4.76f, 2f);

        // Löcher als tiefe Mulden
        float hole = HolesAt(u, v);

        return base_ - crack * 0.35f - hole * 0.8f;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PRIMITIVE: Risse, Löcher, FBM
    // ═══════════════════════════════════════════════════════════════════════════

    // Ridge-Noise: gibt Werte nahe 1 an den "Kämmen" des Noise zurück → Linien/Netz
    static float Ridge(float x, float y)
    {
        float v = 0f, a = 0.5f, f = 1f;
        for (int i = 0; i < 5; i++)
        {
            float n = Mathf.PerlinNoise(x * f, y * f);
            v += a * (1f - Mathf.Abs(n * 2f - 1f));
            a *= 0.5f; f *= 2.1f;
        }
        return v;
    }

    // Streut unregelmäßige Ausbrüche / Löcher per Zell-Hash
    static float HolesAt(float u, float v)
    {
        float result = 0f;
        int   gridN  = 9;
        for (int cx = -1; cx <= 1; cx++)
        for (int cy = -1; cy <= 1; cy++)
        {
            float cellX = Mathf.Floor(u * gridN) + cx;
            float cellY = Mathf.Floor(v * gridN) + cy;
            if (Hash(cellX * 419.2f + cellY * 571.9f) > 0.14f) continue; // ~14 % der Zellen

            float hx = Hash(cellX * 127.1f + cellY * 311.7f);
            float hy = Hash(cellX * 269.5f + cellY * 183.3f);
            float px  = (cellX + hx) / gridN;
            float py  = (cellY + hy) / gridN;
            float r   = 0.018f + Hash(cellX * 739.3f + cellY * 127.5f) * 0.028f;
            float du  = u - px, dv = v - py;
            // Löcher sind leicht elliptisch für mehr Natürlichkeit
            float aspect = 0.6f + Hash(cellX * 553.1f + cellY * 233.7f) * 0.8f;
            float dist   = Mathf.Sqrt(du * du + dv * dv / (aspect * aspect));
            float inside = 1f - Mathf.SmoothStep(0f, r, dist);
            result = Mathf.Max(result, inside);
        }
        return result;
    }

    // Aufgerissener Rand um Löcher
    static float HoleEdgeAt(float u, float v)
    {
        float result = 0f;
        int   gridN  = 9;
        for (int cx = -1; cx <= 1; cx++)
        for (int cy = -1; cy <= 1; cy++)
        {
            float cellX = Mathf.Floor(u * gridN) + cx;
            float cellY = Mathf.Floor(v * gridN) + cy;
            if (Hash(cellX * 419.2f + cellY * 571.9f) > 0.14f) continue;

            float hx = Hash(cellX * 127.1f + cellY * 311.7f);
            float hy = Hash(cellX * 269.5f + cellY * 183.3f);
            float px  = (cellX + hx) / gridN;
            float py  = (cellY + hy) / gridN;
            float r   = 0.018f + Hash(cellX * 739.3f + cellY * 127.5f) * 0.028f;
            float aspect = 0.6f + Hash(cellX * 553.1f + cellY * 233.7f) * 0.8f;
            float du  = u - px, dv = v - py;
            float dist   = Mathf.Sqrt(du * du + dv * dv / (aspect * aspect));
            float rim    = 1f - Mathf.SmoothStep(r, r * 2.2f, dist);
            result = Mathf.Max(result, rim);
        }
        return result;
    }

    static float Fbm(float x, float y, int octaves)
    {
        float v = 0f, a = 0.5f, f = 1f;
        for (int i = 0; i < octaves; i++)
        {
            v += a * Mathf.PerlinNoise(x * f, y * f);
            a *= 0.5f; f *= 2.1f;
        }
        return v;
    }

    // Deterministischer Hash [0,1] aus einem Float-Seed
    static float Hash(float n) => Mathf.Abs(Mathf.Sin(n) * 43758.5453f) % 1f;

    // ═══════════════════════════════════════════════════════════════════════════
    // SPEICHERN & MATERIAL
    // ═══════════════════════════════════════════════════════════════════════════

    static void SavePng(Texture2D tex, string assetPath)
    {
        File.WriteAllBytes(
            Path.Combine(Application.dataPath, "..", assetPath),
            tex.EncodeToPNG());
    }

    static void ApplyToMaterial()
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>(MaterialPath);
        if (mat == null) { Debug.LogError($"[WallTextureGenerator] Nicht gefunden: {MaterialPath}"); return; }

        var albedo = AssetDatabase.LoadAssetAtPath<Texture2D>(AlbedoPath);
        var normal = AssetDatabase.LoadAssetAtPath<Texture2D>(NormalPath);

        mat.SetTexture("_MainTex", albedo);
        mat.SetTexture("_BumpMap", normal);
        mat.SetColor("_Color", Color.white);
        mat.SetFloat("_Glossiness", 0.12f);
        mat.SetFloat("_Metallic",   0.00f);
        mat.SetFloat("_BumpScale",  0.75f);
        mat.SetTextureScale("_MainTex", new Vector2(1f, 4f));
        mat.SetTextureScale("_BumpMap", new Vector2(1f, 4f));

        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
    }
}
