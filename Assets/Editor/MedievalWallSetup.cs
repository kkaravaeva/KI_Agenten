using UnityEditor;
using UnityEngine;

/// Applies the downloaded Poly Haven "medieval_blocks_05" PBR textures to Wall_Mat.
/// Menu: Tools/Texturen/Mittelalterliche Wand-Textur anwenden
public static class MedievalWallSetup
{
    const string MatPath       = "Assets/Materials/Wall_Mat.mat";
    const string AlbedoPath    = "Assets/Textures/Wall/medieval_wall_albedo.jpg";
    const string NormalPath    = "Assets/Textures/Wall/medieval_wall_normal.jpg";
    const string RoughnessPath = "Assets/Textures/Wall/medieval_wall_roughness.jpg";
    const string AoPath        = "Assets/Textures/Wall/medieval_wall_ao.jpg";

    [MenuItem("Tools/Texturen/Mittelalterliche Wand-Textur anwenden")]
    static void Apply()
    {
        // Force Unity to import the textures before loading them
        AssetDatabase.ImportAsset(AlbedoPath,    ImportAssetOptions.Default);
        AssetDatabase.ImportAsset(NormalPath,    ImportAssetOptions.Default);
        AssetDatabase.ImportAsset(RoughnessPath, ImportAssetOptions.Default);
        AssetDatabase.ImportAsset(AoPath,        ImportAssetOptions.Default);

        // Set normal map import type
        SetNormalMap(NormalPath);
        // Set linear for roughness and AO
        SetLinear(RoughnessPath);
        SetLinear(AoPath);

        var mat = AssetDatabase.LoadAssetAtPath<Material>(MatPath);
        if (mat == null) { Debug.LogError($"[MedievalWall] Material not found: {MatPath}"); return; }

        var albedo    = AssetDatabase.LoadAssetAtPath<Texture2D>(AlbedoPath);
        var normal    = AssetDatabase.LoadAssetAtPath<Texture2D>(NormalPath);
        var roughness = AssetDatabase.LoadAssetAtPath<Texture2D>(RoughnessPath);
        var ao        = AssetDatabase.LoadAssetAtPath<Texture2D>(AoPath);

        if (albedo == null || normal == null)
        {
            Debug.LogError("[MedievalWall] Textures not loaded — restart Unity to trigger import, then run again.");
            EditorUtility.DisplayDialog("Fehler",
                "Texturen noch nicht importiert.\n\nUnity neu starten und dann erneut ausführen.", "OK");
            return;
        }

        // Apply to Standard shader material
        mat.SetTexture("_MainTex",       albedo);
        mat.SetTexture("_BumpMap",       normal);
        mat.SetTexture("_OcclusionMap",  ao);
        // roughness → Unity uses smoothness = 1 - roughness
        // We store roughness in the smoothness channel inverted via _GlossMapScale trick:
        // Unity Standard can use roughness map via MetallicGlossMap alpha, but simplest
        // is to set a mid smoothness and let the normal + AO do the heavy lifting.
        mat.SetFloat("_Glossiness",      0.15f);  // low base smoothness (rough stone)
        mat.SetFloat("_GlossMapScale",   1.0f);
        mat.SetFloat("_Metallic",        0.00f);
        mat.SetFloat("_BumpScale",       1.0f);
        mat.SetFloat("_OcclusionStrength", 1.0f);
        mat.SetColor("_Color",           new Color(1f, 1f, 1f, 1f));

        // Wall prefab is 1×7×1 → tile 7× in Y so blocks aren't stretched
        mat.SetTextureScale("_MainTex",      new Vector2(1f, 7f));
        mat.SetTextureScale("_BumpMap",      new Vector2(1f, 7f));
        mat.SetTextureScale("_OcclusionMap", new Vector2(1f, 7f));
        mat.EnableKeyword("_NORMALMAP");

        EditorUtility.SetDirty(mat);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        Debug.Log("[MedievalWall] ✓ Poly Haven medieval_blocks_05 applied to Wall_Mat.");
        EditorUtility.DisplayDialog("Fertig",
            "✓ Mittelalterliche Stein-Textur angewendet!\n\n" +
            "Quelle: Poly Haven – medieval_blocks_05\n" +
            "Lizenz: CC0 Public Domain\n\n" +
            "Tipp: Textur-Tiling in Wall_Mat anpassen falls die Steine zu groß/klein wirken.", "OK");
    }

    static void SetNormalMap(string path)
    {
        var imp = AssetImporter.GetAtPath(path) as TextureImporter;
        if (imp == null) return;
        if (imp.textureType == TextureImporterType.NormalMap) return;
        imp.textureType = TextureImporterType.NormalMap;
        imp.SaveAndReimport();
    }

    static void SetLinear(string path)
    {
        var imp = AssetImporter.GetAtPath(path) as TextureImporter;
        if (imp == null) return;
        if (!imp.sRGBTexture) return;
        imp.sRGBTexture = false;
        imp.SaveAndReimport();
    }
}
