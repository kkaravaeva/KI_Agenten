using System.IO;
using System.IO.Compression;
using System.Net;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

/// Downloads Lava005 (AmbientCG, CC0) and applies it to Lava_Mat.
/// Menu: Tools/Texturen/Lava-Textur laden (AmbientCG)
/// Menu: Tools/Texturen/Lava-Textur anwenden
public static class LavaTextureSetup
{
    const string TexDir    = "Assets/Textures/Lava";
    const string MatPath   = "Assets/Materials/M_Lava01.mat";   // used by Lava_Placeholder prefab
    const string MatPath2  = "Assets/Materials/Lava_Mat.mat";   // secondary material
    const string ZipUrl    = "https://ambientcg.com/get?file=Lava005_2K-JPG.zip";
    const string AssetId   = "Lava005_2K-JPG";

    static string AlbedoPath  => $"{TexDir}/lava_color.jpg";
    static string NormalPath  => $"{TexDir}/lava_normal.jpg";
    static string RoughPath   => $"{TexDir}/lava_roughness.jpg";
    static string EmitPath    => $"{TexDir}/lava_emission.jpg";

    // ── Download + Apply ───────────────────────────────────────────────────────

    [MenuItem("Tools/Texturen/Lava-Textur laden (AmbientCG)")]
    static void DownloadAndApply()
    {
        EnsureFolder();
        string tmpZip = Path.Combine(Path.GetTempPath(), "Lava005_2K-JPG.zip");
        string tmpDir = Path.Combine(Path.GetTempPath(), "Lava005_extracted");

        try
        {
            EditorUtility.DisplayProgressBar("Lava-Textur", "Lade Lava005 von AmbientCG (~34 MB)…", 0.05f);
            using (var wc = new WebClient())
            {
                wc.Headers.Add("User-Agent", "UnityEditor/2021.3");
                wc.DownloadFile(ZipUrl, tmpZip);
            }

            EditorUtility.DisplayProgressBar("Lava-Textur", "Entpacke…", 0.50f);
            ExtractNeeded(tmpZip, tmpDir);

            EditorUtility.DisplayProgressBar("Lava-Textur", "Importiere Texturen…", 0.80f);
            AssetDatabase.Refresh();
            ConfigureImportSettings();
            ApplyToMaterial(MatPath);
            ApplyToMaterial(MatPath2);
            SaveScene();

            EditorUtility.ClearProgressBar();
            EditorUtility.DisplayDialog("Lava-Textur",
                "✓ AmbientCG Lava005 (2K PBR, CC0) erfolgreich geladen!\n\n" +
                "• Color Map (Basalt + glühende Risse)\n" +
                "• Normal Map (Oberflächendetail)\n" +
                "• Emission Map (Risse selbstleuchtend)\n" +
                "• Roughness Map (raues Gestein)", "OK");
        }
        catch (System.Exception e)
        {
            EditorUtility.ClearProgressBar();
            Debug.LogError($"[LavaTexture] Download fehlgeschlagen: {e.Message}");
            EditorUtility.DisplayDialog("Fehler",
                $"Download fehlgeschlagen:\n{e.Message}\n\n" +
                "Prüfe deine Internetverbindung oder wende die vorhandenen Texturen an:\n" +
                "Tools → Texturen → Lava-Textur anwenden", "OK");
        }
    }

    // ── Apply existing textures ────────────────────────────────────────────────

    [MenuItem("Tools/Texturen/Lava-Textur anwenden")]
    static void ApplyOnly()
    {
        if (!File.Exists(Path.Combine(Application.dataPath, AlbedoPath.Substring("Assets/".Length))))
        {
            EditorUtility.DisplayDialog("Lava-Textur",
                "Texturen nicht gefunden.\nBitte zuerst laden:\nTools → Texturen → Lava-Textur laden (AmbientCG)", "OK");
            return;
        }

        AssetDatabase.Refresh();
        ConfigureImportSettings();
        ApplyToMaterial(MatPath);
        ApplyToMaterial(MatPath2);
        SaveScene();
        EditorUtility.DisplayDialog("Lava-Textur", "✓ Lava005-Texturen auf M_Lava01 + Lava_Mat angewandt.", "OK");
    }

    // ── Extract ───────────────────────────────────────────────────────────────

    static void ExtractNeeded(string zipPath, string tmpDir)
    {
        if (Directory.Exists(tmpDir)) Directory.Delete(tmpDir, recursive: true);
        Directory.CreateDirectory(tmpDir);

        var needed = new System.Collections.Generic.Dictionary<string, string>
        {
            { $"{AssetId}_Color.jpg",    AlbedoPath },
            { $"{AssetId}_NormalGL.jpg", NormalPath },
            { $"{AssetId}_Roughness.jpg",RoughPath  },
            { $"{AssetId}_Emission.jpg", EmitPath   },
        };

        using (var zip = ZipFile.OpenRead(zipPath))
        {
            foreach (var entry in zip.Entries)
            {
                if (!needed.TryGetValue(entry.FullName, out string destAsset)) continue;
                string dest = Path.Combine(Application.dataPath,
                                           destAsset.Substring("Assets/".Length));
                using var src  = entry.Open();
                using var dst  = File.Create(dest);
                src.CopyTo(dst);
                Debug.Log($"[LavaTexture] Extracted {entry.FullName} ({entry.Length / 1024} KB)");
            }
        }
    }

    // ── Import settings ───────────────────────────────────────────────────────

    static void ConfigureImportSettings()
    {
        SetNormalMap(NormalPath);
        SetLinear(RoughPath);
        SetLinear(EmitPath);
    }

    static void SetNormalMap(string assetPath)
    {
        var imp = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (imp == null || imp.textureType == TextureImporterType.NormalMap) return;
        imp.textureType = TextureImporterType.NormalMap;
        imp.SaveAndReimport();
    }

    static void SetLinear(string assetPath)
    {
        var imp = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (imp == null || !imp.sRGBTexture) return;
        imp.sRGBTexture = false;
        imp.SaveAndReimport();
    }

    // ── Material ──────────────────────────────────────────────────────────────

    static void ApplyToMaterial(string matPath)
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>(matPath);
        if (mat == null) { Debug.LogWarning($"[LavaTexture] Material nicht gefunden: {matPath}"); return; }

        var albedo = AssetDatabase.LoadAssetAtPath<Texture2D>(AlbedoPath);
        var normal = AssetDatabase.LoadAssetAtPath<Texture2D>(NormalPath);
        var emit   = AssetDatabase.LoadAssetAtPath<Texture2D>(EmitPath);

        if (albedo != null) mat.SetTexture("_MainTex", albedo);

        if (normal != null)
        {
            mat.EnableKeyword("_NORMALMAP");
            mat.SetTexture("_BumpMap", normal);
            mat.SetFloat("_BumpScale", 1.0f);
        }

        if (emit != null)
        {
            mat.EnableKeyword("_EMISSION");
            mat.SetTexture("_EmissionMap", emit);
            // HDR orange-red glow matching real molten lava
            mat.SetColor("_EmissionColor", new Color(4.0f, 0.7f, 0.0f));
        }

        // Lava is very rough basalt — almost no specularity
        mat.SetColor("_Color",      Color.white);
        mat.SetFloat("_Glossiness", 0.04f);
        mat.SetFloat("_Metallic",   0.00f);

        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
        Debug.Log($"[LavaTexture] {matPath} aktualisiert mit Lava005 PBR-Texturen.");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    static void EnsureFolder()
    {
        string full = Path.Combine(Application.dataPath, "Textures/Lava");
        if (!Directory.Exists(full)) Directory.CreateDirectory(full);
    }

    static void SaveScene()
    {
        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
    }
}
