using System.IO;
using System.Net;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

/// One-click medieval landscape builder.
/// Menu: Tools/Mittelalter/Landschaft aufbauen
public static class MedievalLandscapeSetup
{
    const string TexDir   = "Assets/Textures/Medieval";
    const string MatDir   = "Assets/Materials/Medieval";
    const string ParentGO = "[MedievalLandscape]";

    static string PhDiff(string slug) =>
        $"https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/{slug}/{slug}_diff_2k.jpg";
    static string PhNrm(string slug) =>
        $"https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/{slug}/{slug}_nor_gl_2k.jpg";

    static Material _matStone, _matMossyStone, _matBark, _matLeaf,
                    _matPath, _matTorch, _matFire, _matMountain, _matGrass;

    // ── Entry point ────────────────────────────────────────────────────────────

    [MenuItem("Tools/Mittelalter/Landschaft aufbauen")]
    static void Build()
    {
        var old = GameObject.Find(ParentGO);
        if (old != null) Object.DestroyImmediate(old);

        EnsureFolders();
        DownloadTextures();
        BuildMaterials();

        var root   = new GameObject(ParentGO).transform;
        Vector3 c  = GetLabyrinthCenter();
        float   lr = GetSafeRadius();   // guaranteed outside all possible layouts

        BuildEntrance(root, c, lr);
        BuildTowers(root, c, lr);
        BuildRuins(root, c, lr);
        BuildTrees(root, c, lr);
        BuildHills(root, c, lr);
        BuildMountains(root, c, lr);
        SetupDayNightCycle();
        UpdateAtmosphere();

        EditorUtility.SetDirty(root.gameObject);
        AssetDatabase.SaveAssets();
        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
        Debug.Log("[Medieval] Landscape built.");
        EditorUtility.DisplayDialog("Mittelalterliche Landschaft",
            $"✓ Sicherheitsradius: {lr:F1} m (alle Layouts berücksichtigt)\n" +
            "✓ Eingang: Torbogen & Fackeln außen\n" +
            "✓ 4 Ecktürme mit Zinnen\n" +
            "✓ 18 Ruinen & Felsgruppen\n" +
            "✓ Baumgruppen (Eichen)\n" +
            "✓ Hügellandschaft (50 Hügel, nahe + mittlere Distanz)\n" +
            "✓ Berge (ohne schwebende Schneekappen)\n" +
            "✓ Tag/Nacht-Zyklus [P=Pause · N=Nacht · D=Tag]", "OK");
    }

    // ── Radius: largest possible labyrinth across ALL layouts ─────────────────

    static float GetSafeRadius()
    {
        var mg = Object.FindObjectOfType<MapGenerator>();
        float maxDiag = 14f; // conservative minimum

        if (mg != null)
        {
            float cs = mg.cellSize > 0f ? mg.cellSize : 1f;

            // Direct map layouts
            if (mg.mapLayouts != null)
                foreach (var md in mg.mapLayouts)
                    if (md != null)
                        maxDiag = Mathf.Max(maxDiag,
                            Mathf.Sqrt(md.width * md.width + md.height * md.height) * cs * 0.5f);

            // Curriculum layouts
            if (mg.curriculumConfig?.phases != null)
                foreach (var phase in mg.curriculumConfig.phases)
                    if (phase.layouts != null)
                        foreach (var md in phase.layouts)
                            if (md != null)
                                maxDiag = Mathf.Max(maxDiag,
                                    Mathf.Sqrt(md.width * md.width + md.height * md.height) * cs * 0.5f);
        }

        return maxDiag + 10f; // 10-unit buffer outside the farthest possible wall
    }

    static Vector3 GetLabyrinthCenter()
    {
        var mg = Object.FindObjectOfType<MapGenerator>();
        return mg != null ? mg.transform.position : Vector3.zero;
    }

    // ── Texture download ───────────────────────────────────────────────────────

    static void DownloadTextures()
    {
        TryDownload("mossy_cobblestone", "diff.jpg", PhDiff("mossy_cobblestone"));
        TryDownload("mossy_cobblestone", "nor.jpg",  PhNrm("mossy_cobblestone"));
        TryDownload("mossy_stone_wall",  "diff.jpg", PhDiff("mossy_stone_wall"));
        TryDownload("mossy_stone_wall",  "nor.jpg",  PhNrm("mossy_stone_wall"));
        TryDownload("rock_04",           "diff.jpg", PhDiff("rock_04"));
        TryDownload("sparse_grass",      "diff.jpg", PhDiff("sparse_grass"));
        AssetDatabase.Refresh();
    }

    static void TryDownload(string slug, string suffix, string url)
    {
        string dir  = $"{TexDir}/{slug}";
        string path = $"{dir}/{slug}_{suffix}";
        if (File.Exists(path)) return;
        Directory.CreateDirectory(dir);
        try
        {
            using var wc = new WebClient();
            wc.Headers.Add("User-Agent", "UnityEditor");
            byte[] data = wc.DownloadData(url);
            if (data.Length > 2000) { File.WriteAllBytes(path, data); Debug.Log($"[Medieval] Downloaded {slug}_{suffix}"); }
            else Debug.LogWarning($"[Medieval] Skipped {slug}_{suffix} – response too small");
        }
        catch (System.Exception e) { Debug.LogWarning($"[Medieval] Cannot download {slug}_{suffix}: {e.Message}"); }
    }

    // ── Materials ──────────────────────────────────────────────────────────────

    static void BuildMaterials()
    {
        _matStone      = Mat("stone",       new Color(0.52f, 0.50f, 0.47f), "mossy_stone_wall/mossy_stone_wall_diff.jpg",   "mossy_stone_wall/mossy_stone_wall_nor.jpg",  0.85f);
        _matMossyStone = Mat("mossy_stone", new Color(0.35f, 0.40f, 0.32f), "mossy_stone_wall/mossy_stone_wall_diff.jpg",   null,                                          0.90f);
        _matBark       = Mat("bark",        new Color(0.28f, 0.18f, 0.10f), null, null, 0.92f);
        _matLeaf       = Mat("leaf",        new Color(0.12f, 0.26f, 0.08f), null, null, 0.80f);
        _matPath       = Mat("path",        new Color(0.50f, 0.46f, 0.40f), "mossy_cobblestone/mossy_cobblestone_diff.jpg", "mossy_cobblestone/mossy_cobblestone_nor.jpg", 0.88f);
        _matTorch      = Mat("torchwood",   new Color(0.25f, 0.16f, 0.07f), null, null, 0.95f);
        _matFire       = EmissiveMat("fire",     new Color(1f, 0.55f, 0f), new Color(6f, 2f, 0f));
        _matMountain   = Mat("mountain",    new Color(0.30f, 0.28f, 0.30f), "rock_04/rock_04_diff.jpg",                     null,                                          0.90f);
        _matGrass      = Mat("grass_hill",  new Color(0.38f, 0.46f, 0.24f), "sparse_grass/sparse_grass_diff.jpg",          null,                                          0.88f);
    }

    static Material Mat(string id, Color col, string diffRel, string norRel, float roughness)
    {
        string path = $"{MatDir}/{id}.mat";
        var mat = AssetDatabase.LoadAssetAtPath<Material>(path)
                  ?? CreateAndSave(path);
        mat.color = col;
        mat.SetFloat("_Glossiness", 1f - roughness);
        mat.SetFloat("_Metallic",   0f);
        if (diffRel != null) { var t = Tex(diffRel); if (t) mat.mainTexture = t; }
        if (norRel  != null) { var t = Tex(norRel);  if (t) { mat.EnableKeyword("_NORMALMAP"); mat.SetTexture("_BumpMap", t); mat.SetFloat("_BumpScale", 1f); } }
        EditorUtility.SetDirty(mat);
        return mat;
    }

    static Material EmissiveMat(string id, Color col, Color emit)
    {
        string path = $"{MatDir}/{id}.mat";
        var mat = AssetDatabase.LoadAssetAtPath<Material>(path) ?? CreateAndSave(path);
        mat.color = col;
        mat.EnableKeyword("_EMISSION");
        mat.SetColor("_EmissionColor", emit);
        mat.SetFloat("_Glossiness", 0.30f);
        EditorUtility.SetDirty(mat);
        return mat;
    }

    static Material CreateAndSave(string path)
    {
        var m = new Material(Shader.Find("Standard"));
        AssetDatabase.CreateAsset(m, path);
        return m;
    }

    static Texture2D Tex(string rel) =>
        AssetDatabase.LoadAssetAtPath<Texture2D>($"{TexDir}/{rel}");

    // ── Entrance — OUTSIDE the labyrinth ──────────────────────────────────────

    static void BuildEntrance(Transform root, Vector3 c, float lr)
    {
        // North side: path goes outward (+Z), never inward
        Vector3 edgeNorth = c + Vector3.forward * lr;
        Vector3 outward   = Vector3.forward;          // away from labyrinth center
        float   pathLen   = 14f;

        PlacePath(root, edgeNorth, outward, pathLen);

        // Arch sits 2 m outside the labyrinth edge — rotation identity so pillars span X axis (perpendicular to path)
        PlaceArch(root, edgeNorth + outward * 2.5f, Quaternion.identity);

        // Torches along the path, going outward: positions 4, 7, 10, 13 m from edge
        for (int i = 0; i < 4; i++)
        {
            Vector3 p = edgeNorth + outward * (4f + i * 3f);
            PlaceTorch(root, p + Vector3.right * 1.5f);
            PlaceTorch(root, p - Vector3.right * 1.5f);
        }
    }

    // ── 4 corner towers ───────────────────────────────────────────────────────

    static void BuildTowers(Transform root, Vector3 c, float lr)
    {
        float   d       = lr + 20f;
        float[] angles  = { 45f, 135f, 225f, 315f };
        float[] heights = { 11f, 9f,   13f,  10f  };
        for (int i = 0; i < 4; i++)
        {
            float a = angles[i] * Mathf.Deg2Rad;
            PlaceTower(root, c + new Vector3(Mathf.Cos(a) * d, 0, Mathf.Sin(a) * d), heights[i]);
        }
    }

    // ── Ruins ─────────────────────────────────────────────────────────────────

    static void BuildRuins(Transform root, Vector3 c, float lr)
    {
        var rng = new System.Random(42);
        for (int i = 0; i < 20; i++)
        {
            float a   = (float)rng.NextDouble() * Mathf.PI * 2f;
            float d   = lr + 12f + (float)rng.NextDouble() * 38f;
            var   pos = c + new Vector3(Mathf.Cos(a) * d, 0, Mathf.Sin(a) * d);
            switch (rng.Next(3))
            {
                case 0: PlaceRuinWall(root, pos, Quaternion.Euler(0, (float)rng.NextDouble() * 360, 0),
                            2 + rng.Next(5), 0.4f + (float)rng.NextDouble() * 0.6f); break;
                case 1: PlacePillar(root, pos, 1.5f + (float)rng.NextDouble() * 3f); break;
                case 2: PlaceRockCluster(root, pos, rng); break;
            }
        }
    }

    // ── Trees ─────────────────────────────────────────────────────────────────

    static void BuildTrees(Transform root, Vector3 c, float lr)
    {
        var rng = new System.Random(7);
        for (int g = 0; g < 14; g++)
        {
            float ga = (float)g / 14f * Mathf.PI * 2f;
            float gd = lr + 16f + (float)rng.NextDouble() * 65f;
            var   gc = c + new Vector3(Mathf.Cos(ga) * gd, 0, Mathf.Sin(ga) * gd);
            int   n  = 2 + rng.Next(6);
            for (int t = 0; t < n; t++)
            {
                float ox = (float)(rng.NextDouble() - 0.5) * 10f;
                float oz = (float)(rng.NextDouble() - 0.5) * 10f;
                PlaceTree(root, gc + new Vector3(ox, 0, oz), 4f + (float)rng.NextDouble() * 5f, rng);
            }
        }
    }

    // ── Hills ─────────────────────────────────────────────────────────────────

    static void BuildHills(Transform root, Vector3 c, float lr)
    {
        var rng = new System.Random(13);

        // Nahe Hügel — dichte, sanfte Hügelkette direkt hinter dem Labyrinth
        for (int i = 0; i < 28; i++)
        {
            float a = (float)rng.NextDouble() * Mathf.PI * 2f;
            float d = lr + 8f + (float)rng.NextDouble() * 40f;
            var   p = c + new Vector3(Mathf.Cos(a) * d, 0, Mathf.Sin(a) * d);
            PlaceHill(root, p, 10f + (float)rng.NextDouble() * 18f, 4f + (float)rng.NextDouble() * 10f);
        }

        // Mittlere Hügel — markantere Erhebungen im Mittelgrund
        for (int i = 0; i < 22; i++)
        {
            float a = (float)rng.NextDouble() * Mathf.PI * 2f;
            float d = lr + 50f + (float)rng.NextDouble() * 90f;
            var   p = c + new Vector3(Mathf.Cos(a) * d, 0, Mathf.Sin(a) * d);
            PlaceHill(root, p, 14f + (float)rng.NextDouble() * 22f, 7f + (float)rng.NextDouble() * 16f);
        }
    }

    // ── Distant mountains ─────────────────────────────────────────────────────

    static void BuildMountains(Transform root, Vector3 c, float lr)
    {
        var rng = new System.Random(99);
        for (int i = 0; i < 18; i++)
        {
            float a  = (float)i / 18f * Mathf.PI * 2f + (float)(rng.NextDouble() - 0.5) * 0.3f;
            float d  = lr + 180f + (float)rng.NextDouble() * 220f;
            var   p  = c + new Vector3(Mathf.Cos(a) * d, 0, Mathf.Sin(a) * d);
            PlaceMountain(root, p, 45f + (float)rng.NextDouble() * 55f, 65f + (float)rng.NextDouble() * 75f);
        }
    }

    // ── Primitives ─────────────────────────────────────────────────────────────

    static void PlacePath(Transform root, Vector3 start, Vector3 dir, float length)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = "Path";
        go.transform.SetParent(root);
        // Center of path is halfway along its length
        go.transform.position   = start + dir * (length * 0.5f);
        // Make the long axis align with 'dir'
        go.transform.rotation   = Quaternion.LookRotation(dir);
        // Z = length (forward), X = width, Y = height
        go.transform.localScale = new Vector3(2.6f, 0.05f, length);
        Apply(go, _matPath, new Vector2(1f, length * 0.4f));
        Object.DestroyImmediate(go.GetComponent<BoxCollider>());
    }

    static void PlaceArch(Transform root, Vector3 pos, Quaternion rot)
    {
        var arch = new GameObject("Arch");
        arch.transform.SetParent(root);
        arch.transform.position = pos;
        arch.transform.rotation = rot;
        // Pillars at ±X, spanning perpendicular to the path
        Pillar(arch.transform, new Vector3(-1.5f, 0, 0), new Vector3(0.65f, 5.2f, 0.65f));
        Pillar(arch.transform, new Vector3( 1.5f, 0, 0), new Vector3(0.65f, 5.2f, 0.65f));
        // Lintel
        Pillar(arch.transform, new Vector3(0, 5.3f, 0),  new Vector3(3.65f, 0.75f, 0.75f));
        // Keystone
        Pillar(arch.transform, new Vector3(0, 5.95f, 0), new Vector3(1.0f, 0.85f, 0.85f));
    }

    static void Pillar(Transform parent, Vector3 localPos, Vector3 scale)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.transform.SetParent(parent);
        go.transform.localPosition = localPos;
        go.transform.localScale    = scale;
        Apply(go, _matStone);
        Object.DestroyImmediate(go.GetComponent<BoxCollider>());
    }

    static void PlaceTower(Transform root, Vector3 pos, float h)
    {
        var t = new GameObject("Tower");
        t.transform.SetParent(root);
        t.transform.position = pos;
        float r = 2.2f;
        Cyl(t.transform, new Vector3(0, h * 0.5f, 0),  new Vector3(r * 2, h,   r * 2),   _matStone);
        Cyl(t.transform, new Vector3(0, h + 0.4f, 0),  new Vector3(r * 2.3f, 0.8f, r * 2.3f), _matStone);
        for (int m = 0; m < 4; m++)
        {
            float a = m * 90f * Mathf.Deg2Rad;
            Pillar(t.transform, new Vector3(Mathf.Cos(a) * r, h + 1.1f, Mathf.Sin(a) * r),
                   new Vector3(0.85f, 1.0f, 0.85f));
        }
        PlaceTorch(t.transform, pos + new Vector3(r * 0.7f, h + 1.6f, 0));
    }

    static void Cyl(Transform parent, Vector3 lp, Vector3 scale, Material mat)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        go.transform.SetParent(parent);
        go.transform.localPosition = lp;
        go.transform.localScale    = scale;
        Apply(go, mat);
        Object.DestroyImmediate(go.GetComponent<CapsuleCollider>());
    }

    static void PlaceRuinWall(Transform root, Vector3 pos, Quaternion rot, int segs, float hFrac)
    {
        var wall = new GameObject("RuinWall");
        wall.transform.SetParent(root);
        wall.transform.SetPositionAndRotation(pos, rot);
        for (int i = 0; i < segs; i++)
        {
            float h  = 3.5f * hFrac * (0.55f + 0.45f * Mathf.Abs(Mathf.Sin(i * 1.4f)));
            var   go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.transform.SetParent(wall.transform);
            go.transform.localPosition = new Vector3(i * 1.1f, h * 0.5f, 0);
            go.transform.localScale    = new Vector3(1.05f, h, 0.55f);
            go.transform.localRotation = Quaternion.Euler(
                Random.Range(-3f, 3f), Random.Range(-6f, 6f), Random.Range(-2f, 2f));
            Apply(go, _matMossyStone);
            Object.DestroyImmediate(go.GetComponent<BoxCollider>());
        }
    }

    static void PlacePillar(Transform root, Vector3 pos, float h)
    {
        Cyl(root, pos + Vector3.up * h * 0.5f, new Vector3(0.5f, h * 0.5f, 0.5f), _matMossyStone);
    }

    static void PlaceRockCluster(Transform root, Vector3 pos, System.Random rng)
    {
        int n = 2 + rng.Next(5);
        for (int i = 0; i < n; i++)
        {
            float ox = (float)(rng.NextDouble() - 0.5) * 4f;
            float oz = (float)(rng.NextDouble() - 0.5) * 4f;
            float s  = 0.5f + (float)rng.NextDouble() * 1.3f;
            var   go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.name  = "Rock";
            go.transform.SetParent(root);
            go.transform.position   = pos + new Vector3(ox, s * 0.28f, oz);
            go.transform.localScale = new Vector3(s * 1.2f, s * 0.65f, s);
            go.transform.rotation   = Quaternion.Euler(0, (float)rng.NextDouble() * 360f, 0);
            Apply(go, _matMossyStone);
            Object.DestroyImmediate(go.GetComponent<SphereCollider>());
        }
    }

    static void PlaceTree(Transform root, Vector3 pos, float h, System.Random rng)
    {
        var tree = new GameObject("Tree");
        tree.transform.SetParent(root);
        tree.transform.position = pos;
        // Trunk
        Cyl(tree.transform, new Vector3(0, h * 0.38f, 0), new Vector3(0.28f, h * 0.38f, 0.28f), _matBark);
        // Three foliage spheres
        float[] fy = { 0.68f, 0.80f, 0.90f };
        float[] fr = { 0.54f, 0.44f, 0.30f };
        for (int i = 0; i < 3; i++)
        {
            float s  = fr[i] * h;
            float ox = (float)(rng.NextDouble() - 0.5) * 0.5f;
            float oz = (float)(rng.NextDouble() - 0.5) * 0.5f;
            var   go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.transform.SetParent(tree.transform);
            go.transform.localPosition = new Vector3(ox, h * fy[i], oz);
            go.transform.localScale    = new Vector3(s, s * 0.82f, s);
            Apply(go, _matLeaf);
            Object.DestroyImmediate(go.GetComponent<SphereCollider>());
        }
    }

    static void PlaceHill(Transform root, Vector3 pos, float radius, float height)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        go.name = "Hill";
        go.transform.SetParent(root);
        go.transform.position   = pos + Vector3.up * (-radius * 0.42f);
        go.transform.localScale = new Vector3(radius * 2f, height, radius * 2f);
        Apply(go, _matGrass, new Vector2(radius * 0.28f, radius * 0.28f));
        Object.DestroyImmediate(go.GetComponent<SphereCollider>());
    }

    static void PlaceMountain(Transform root, Vector3 pos, float radius, float height)
    {
        var peak = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        peak.name = "Mountain";
        peak.transform.SetParent(root);
        peak.transform.position   = pos + Vector3.up * (-radius * 0.28f);
        peak.transform.localScale = new Vector3(radius * 2f, height, radius * 2f);
        Apply(peak, _matMountain);
        Object.DestroyImmediate(peak.GetComponent<SphereCollider>());
    }

    static void PlaceTorch(Transform root, Vector3 pos)
    {
        var torch = new GameObject("Torch");
        torch.transform.SetParent(root);
        torch.transform.position = pos;

        // Pole
        Cyl(torch.transform, new Vector3(0, 0.75f, 0), new Vector3(0.07f, 0.75f, 0.07f), _matTorch);

        // Head
        var head = GameObject.CreatePrimitive(PrimitiveType.Cube);
        head.transform.SetParent(torch.transform);
        head.transform.localPosition = new Vector3(0, 1.55f, 0);
        head.transform.localScale    = new Vector3(0.16f, 0.22f, 0.16f);
        Apply(head, _matFire);
        Object.DestroyImmediate(head.GetComponent<BoxCollider>());

        // Flame particles
        var ps = new GameObject("Flame").AddComponent<ParticleSystem>();
        ps.transform.SetParent(torch.transform);
        ps.transform.localPosition = new Vector3(0, 1.7f, 0);
        var main = ps.main;
        main.startLifetime    = new ParticleSystem.MinMaxCurve(0.30f, 0.65f);
        main.startSize        = new ParticleSystem.MinMaxCurve(0.08f, 0.18f);
        main.startSpeed       = new ParticleSystem.MinMaxCurve(0.5f, 1.1f);
        main.startColor       = new ParticleSystem.MinMaxGradient(
                                    new Color(1f, 0.75f, 0f), new Color(1f, 0.25f, 0f));
        main.maxParticles     = 30;
        main.gravityModifier  = -0.18f;
        var em = ps.emission;  em.rateOverTime = 28f;
        var sh = ps.shape;     sh.shapeType = ParticleSystemShapeType.Circle; sh.radius = 0.04f;
        var col = ps.colorOverLifetime; col.enabled = true;
        var g = new Gradient();
        g.SetKeys(
            new[] { new GradientColorKey(Color.yellow, 0f),
                    new GradientColorKey(new Color(0.55f, 0.15f, 0f), 0.65f),
                    new GradientColorKey(Color.clear, 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) });
        col.color = new ParticleSystem.MinMaxGradient(g);

        // Point light — named "TorchLight" so DayNightCycle finds it
        var lightGO = new GameObject("TorchLight");
        lightGO.transform.SetParent(torch.transform);
        lightGO.transform.localPosition = new Vector3(0, 1.75f, 0);
        var light = lightGO.AddComponent<Light>();
        light.type      = LightType.Point;
        light.color     = new Color(1f, 0.58f, 0.18f);
        light.intensity = 2.2f;
        light.range     = 9f;
        light.shadows   = LightShadows.None;
    }

    // ── DayNightCycle ──────────────────────────────────────────────────────────

    static void SetupDayNightCycle()
    {
        if (Object.FindObjectOfType<DayNightCycle>() != null) return;
        var go  = new GameObject("DayNightCycle");
        var dnc = go.AddComponent<DayNightCycle>();
        dnc.timeOfDay          = 0.30f;  // start: morning
        dnc.dayDurationSeconds = 240f;
        EditorUtility.SetDirty(go);
    }

    // ── Atmosphere (midday baseline — DayNightCycle overrides at runtime) ──────

    static void UpdateAtmosphere()
    {
        // Brighter sun
        foreach (var l in Object.FindObjectsOfType<Light>())
        {
            if (l.type != LightType.Directional) continue;
            l.color     = new Color(1.00f, 0.96f, 0.85f);
            l.intensity = 1.55f;
            l.shadows   = LightShadows.Soft;
            l.shadowStrength   = 0.68f;
            l.shadowBias       = 0.03f;
            l.shadowNormalBias = 0.30f;
            l.transform.rotation = Quaternion.Euler(52f, -40f, 0f);
            EditorUtility.SetDirty(l);
            break;
        }

        RenderSettings.ambientMode         = AmbientMode.Trilight;
        RenderSettings.ambientSkyColor     = new Color(0.50f, 0.65f, 0.90f);
        RenderSettings.ambientEquatorColor = new Color(0.42f, 0.52f, 0.44f);
        RenderSettings.ambientGroundColor  = new Color(0.18f, 0.15f, 0.12f);
        RenderSettings.fog        = true;
        RenderSettings.fogMode    = FogMode.ExponentialSquared;
        RenderSettings.fogColor   = new Color(0.58f, 0.54f, 0.46f);
        RenderSettings.fogDensity = 0.005f;
    }

    // ── Utility ────────────────────────────────────────────────────────────────

    static void Apply(GameObject go, Material mat, Vector2 tiling = default)
    {
        if (mat == null) return;
        var r = go.GetComponent<Renderer>();
        if (r == null) return;
        r.sharedMaterial = mat;
        if (tiling != default && tiling != Vector2.zero)
            mat.mainTextureScale = tiling;
    }

    static void EnsureFolders()
    {
        foreach (var d in new[] { TexDir, MatDir })
        {
            var parts = d.Split('/');
            string acc = parts[0];
            for (int i = 1; i < parts.Length; i++)
            {
                string next = acc + "/" + parts[i];
                if (!AssetDatabase.IsValidFolder(next))
                    AssetDatabase.CreateFolder(acc, parts[i]);
                acc = next;
            }
        }
    }
}
