using System.Collections.Generic;
using UnityEngine;

/// Builds a humanoid character on the Agent at runtime using Unity primitives.
/// Generates a procedural face texture with eyes, nose, mouth and maps it onto
/// a quad face-plate on the head sphere.
///
/// Proportions follow the 7-head rule scaled to fit the CapsuleCollider (height = 1 unit).
[DisallowMultipleComponent]
public class HumanAgentVisual : MonoBehaviour
{
    // ── Animation pivots ───────────────────────────────────────────────────────
    Transform _lShoulder, _rShoulder;
    Transform _lElbow,    _rElbow;
    Transform _lHip,      _rHip;
    Transform _lKnee,     _rKnee;
    Transform _torso;
    Transform _headRoot;    // parent of all head parts
    Transform _neckPivot;

    Rigidbody _rb;
    float     _walkPhase;

    // All renderers that belong to the head (hidden in POV mode)
    readonly List<Renderer> _headRenderers = new List<Renderer>();

    // ── Shared assets (static so we don't recreate per agent instance) ─────────
    static Material s_skin, s_shirt, s_pants, s_shoes, s_hair, s_eye;
    static Texture2D s_faceTex;

    // ── Proportions (total body 1 unit, y: -0.5 … +0.5) ──────────────────────
    const float HeadCY    = 0.405f;  // head sphere center y
    const float HeadRX    = 0.090f;  // head x/z radius (world units)
    const float HeadRY    = 0.095f;  // head y radius
    const float NeckCY    = 0.345f;
    const float ShoulderY = 0.305f;
    const float ShoulderX = 0.188f;
    const float TorsoMidY = 0.195f;
    const float HipY      = 0.048f;
    const float HipX      = 0.082f;
    const float ThighHalf = 0.135f;  // half-length of thigh cylinder
    const float ShinHalf  = 0.130f;

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    void Awake()
    {
        _rb = GetComponent<Rigidbody>();
        EnsureSharedAssets();
        BuildHumanoid();
        HideCapsuleMesh();
    }

    void HideCapsuleMesh()
    {
        var cap = transform.Find("Capsule");
        if (cap == null) return;
        var mr = cap.GetComponent<MeshRenderer>();
        if (mr != null) mr.enabled = false;
    }

    // ── SetHeadVisible (called by CameraSwitcher) ─────────────────────────────

    public void SetHeadVisible(bool visible)
    {
        foreach (var r in _headRenderers)
            if (r != null) r.enabled = visible;
    }

    // ── Shared asset generation ───────────────────────────────────────────────

    static void EnsureSharedAssets()
    {
        if (s_skin != null) return;
        s_skin  = Mat(new Color(0.90f, 0.73f, 0.59f), 0.22f, 0f);
        s_shirt = Mat(new Color(0.16f, 0.29f, 0.68f), 0.38f, 0f);
        s_pants = Mat(new Color(0.14f, 0.12f, 0.10f), 0.18f, 0f);
        s_shoes = Mat(new Color(0.20f, 0.13f, 0.07f), 0.18f, 0.05f);
        s_hair  = Mat(new Color(0.24f, 0.13f, 0.05f), 0.12f, 0f);
        s_eye   = Mat(new Color(0.08f, 0.08f, 0.10f), 0.85f, 0f);
        s_faceTex = GenerateFaceTexture();
    }

    static Material Mat(Color c, float smooth, float metal)
    {
        var m = new Material(Shader.Find("Standard")) { color = c };
        m.SetFloat("_Glossiness", smooth);
        m.SetFloat("_Metallic",   metal);
        return m;
    }

    // ── Procedural face texture ───────────────────────────────────────────────

    static Texture2D GenerateFaceTexture()
    {
        const int W = 512, H = 512;
        var tex = new Texture2D(W, H, TextureFormat.RGBA32, false);

        float fcx = W / 2f, fcy = H / 2f;
        float faceRX = W * 0.39f, faceRY = H * 0.46f;

        // ── Base skin fill ─────────────────────────────────────────────────────
        var skinBase  = new Color(0.90f, 0.73f, 0.59f);
        var skinShade = new Color(0.76f, 0.60f, 0.47f);
        var skinLight = new Color(0.95f, 0.80f, 0.66f);

        for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++)
        {
            float dx = (x - fcx) / faceRX;
            float dy = (y - fcy) / faceRY;
            float d  = dx * dx + dy * dy;
            if (d > 1f) { tex.SetPixel(x, y, Color.clear); continue; }

            // Edge shadow
            float edge  = Mathf.Sqrt(d);
            Color c     = Color.Lerp(skinBase, skinShade, edge * 0.55f);
            // Forehead highlight
            if (dy > 0.15f) c = Color.Lerp(c, skinLight, (dy - 0.15f) * 0.5f);
            tex.SetPixel(x, y, c);
        }

        // ── Hair (top of head, inside face oval) ───────────────────────────────
        var hairClr = new Color(0.24f, 0.13f, 0.05f);
        for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++)
        {
            float dx = (x - fcx) / faceRX;
            float dy = (y - fcy) / faceRY;
            if (dx * dx + dy * dy > 1f) continue;
            float fy = (float)y / H; // 0=bottom, 1=top
            if (fy > 0.73f)           // top 27% = hair
            {
                float t = Mathf.SmoothStep(0f, 1f, (fy - 0.73f) / 0.10f);
                tex.SetPixel(x, y, Color.Lerp(tex.GetPixel(x, y), hairClr, t));
            }
        }

        // ── Eyes ──────────────────────────────────────────────────────────────
        DrawEye(tex, W, H, (int)(fcx - W * 0.165f), (int)(fcy + H * 0.10f));
        DrawEye(tex, W, H, (int)(fcx + W * 0.165f), (int)(fcy + H * 0.10f));

        // ── Eyebrows ──────────────────────────────────────────────────────────
        var browClr = new Color(0.18f, 0.10f, 0.04f);
        DrawBrow(tex, W, H, (int)(fcx - W * 0.165f), (int)(fcy + H * 0.175f), browClr, false);
        DrawBrow(tex, W, H, (int)(fcx + W * 0.165f), (int)(fcy + H * 0.175f), browClr, true);

        // ── Nose ──────────────────────────────────────────────────────────────
        DrawNose(tex, W, H, (int)fcx, (int)(fcy + H * 0.02f), skinShade);

        // ── Mouth ─────────────────────────────────────────────────────────────
        DrawMouth(tex, W, H, (int)fcx, (int)(fcy - H * 0.165f));

        // ── Cheek blush ───────────────────────────────────────────────────────
        var blush = new Color(0.88f, 0.62f, 0.55f, 0.22f);
        FillEllipse(tex, (int)(fcx - W * 0.25f), (int)(fcy + H * 0.02f),
                    (int)(W * 0.13f), (int)(H * 0.09f), blush, 0.35f);
        FillEllipse(tex, (int)(fcx + W * 0.25f), (int)(fcy + H * 0.02f),
                    (int)(W * 0.13f), (int)(H * 0.09f), blush, 0.35f);

        tex.Apply();
        return tex;
    }

    // ── Face drawing helpers ──────────────────────────────────────────────────

    static void DrawEye(Texture2D tex, int W, int H, int cx, int cy)
    {
        int erx = (int)(W * 0.072f), ery = (int)(H * 0.044f); // eye white
        int irr = (int)(W * 0.040f);                           // iris radius
        int pur = (int)(W * 0.022f);                           // pupil radius

        // Eye whites
        FillEllipse(tex, cx, cy, erx, ery, Color.white, 1f);
        // Iris (dark blue-green)
        FillCircle(tex, cx, cy, irr, new Color(0.25f, 0.45f, 0.72f));
        // Pupil
        FillCircle(tex, cx, cy, pur, new Color(0.07f, 0.06f, 0.06f));
        // Specular highlight
        FillCircle(tex, cx + (int)(irr * 0.35f), cy + (int)(iry(ery) * 0.35f),
                   (int)(pur * 0.55f), new Color(1f, 1f, 1f, 0.95f));
        // Upper eyelid shadow
        var ldShadow = new Color(0.55f, 0.38f, 0.30f, 0.5f);
        for (int dx = -erx; dx <= erx; dx++)
        for (int dy = 0; dy <= ery; dy++)
        {
            float ex = (float)dx / erx, ey = (float)dy / ery;
            if (ex*ex + ey*ey <= 1f)
                BlendPixel(tex, cx + dx, cy + dy, ldShadow, 0.35f * (dy / (float)ery));
        }
    }
    static int iry(int ery) => (int)(ery * 0.3f); // small helper for specular offset

    static void DrawBrow(Texture2D tex, int W, int H, int cx, int cy, Color clr, bool flip)
    {
        int bw = (int)(W * 0.115f), bh = (int)(H * 0.025f);
        for (int dx = -bw; dx <= bw; dx++)
        {
            float t  = (float)(dx + bw) / (bw * 2f);
            // Slight arch — higher in the middle
            int arch = (int)(bh * 0.6f * Mathf.Sin(t * Mathf.PI));
            for (int th = 0; th <= bh; th++)
            {
                int px = flip ? cx - dx : cx + dx;
                int py = cy + arch + th;
                float alpha = 1f - Mathf.Abs(th / (float)bh - 0.5f) * 2f;
                BlendPixel(tex, px, py, clr, alpha * 0.9f);
            }
        }
    }

    static void DrawNose(Texture2D tex, int W, int H, int cx, int cy, Color shade)
    {
        // Bridge (thin vertical shadow)
        int nh = (int)(H * 0.09f);
        for (int dy = -nh / 2; dy < nh / 2; dy++)
        for (int dx = -2; dx <= 2; dx++)
            BlendPixel(tex, cx + dx, cy + dy, shade, 0.15f);

        // Nose tip
        FillEllipse(tex, cx, cy - nh / 2, (int)(W * 0.034f), (int)(H * 0.028f), shade, 0.35f);

        // Nostrils
        int nostrilX = (int)(W * 0.032f);
        var nostril  = new Color(0.50f, 0.33f, 0.25f, 0.8f);
        FillEllipse(tex, cx - nostrilX, cy - nh / 2 - (int)(H * 0.015f),
                    (int)(W * 0.020f), (int)(H * 0.016f), nostril, 0.70f);
        FillEllipse(tex, cx + nostrilX, cy - nh / 2 - (int)(H * 0.015f),
                    (int)(W * 0.020f), (int)(H * 0.016f), nostril, 0.70f);
    }

    static void DrawMouth(Texture2D tex, int W, int H, int cx, int cy)
    {
        int mw = (int)(W * 0.130f), mh = (int)(H * 0.028f);
        var upper = new Color(0.65f, 0.35f, 0.30f);
        var lower = new Color(0.75f, 0.45f, 0.38f);
        var line  = new Color(0.40f, 0.22f, 0.18f);

        // Lower lip (slightly fuller)
        FillEllipse(tex, cx, cy, mw, (int)(mh * 1.6f), lower, 0.90f);
        // Upper lip (slightly smaller, darker)
        FillEllipse(tex, cx, cy + mh, mw, (int)(mh * 1.1f), upper, 0.90f);
        // Lip line
        for (int dx = -mw; dx <= mw; dx++)
        {
            float t = (float)dx / mw;
            // Cupid's bow: slight dip in the centre
            int bowY = (int)(Mathf.Abs(Mathf.Sin(t * Mathf.PI)) * mh * 0.5f);
            BlendPixel(tex, cx + dx, cy + bowY, line, 0.85f);
            BlendPixel(tex, cx + dx, cy + bowY + 1, line, 0.50f);
        }
        // Corner shadows
        BlendPixel(tex, cx - mw, cy, line, 0.7f);
        BlendPixel(tex, cx + mw, cy, line, 0.7f);
    }

    static void FillCircle(Texture2D tex, int cx, int cy, int r, Color c)
    {
        for (int dy = -r; dy <= r; dy++)
        for (int dx = -r; dx <= r; dx++)
            if (dx * dx + dy * dy <= r * r)
                BlendPixel(tex, cx + dx, cy + dy, c, c.a);
    }

    static void FillEllipse(Texture2D tex, int cx, int cy, int rx, int ry, Color c, float alpha)
    {
        for (int dy = -ry; dy <= ry; dy++)
        for (int dx = -rx; dx <= rx; dx++)
        {
            float ex = (float)dx / rx, ey = (float)dy / ry;
            if (ex * ex + ey * ey <= 1f)
                BlendPixel(tex, cx + dx, cy + dy, c, alpha * c.a);
        }
    }

    static void BlendPixel(Texture2D tex, int x, int y, Color over, float alpha)
    {
        if (x < 0 || x >= tex.width || y < 0 || y >= tex.height) return;
        Color base_ = tex.GetPixel(x, y);
        if (base_.a < 0.01f) return; // don't paint on transparent (outside face oval)
        tex.SetPixel(x, y, Color.Lerp(base_, new Color(over.r, over.g, over.b, base_.a), alpha));
    }

    // ── Build humanoid ────────────────────────────────────────────────────────

    void BuildHumanoid()
    {
        var root = new GameObject("HumanVisual").transform;
        root.SetParent(transform, false);

        BuildHead(root);
        BuildTorso(root);
        BuildArms(root);
        BuildLegs(root);
    }

    void BuildHead(Transform root)
    {
        _headRoot = new GameObject("HeadRoot").transform;
        _headRoot.SetParent(root, false);
        _headRoot.localPosition = Vector3.zero;

        // Head sphere
        var head = Part(_headRoot, "Head", PrimitiveType.Sphere, s_skin,
            new Vector3(0f, HeadCY, 0f),
            new Vector3(HeadRX * 2f, HeadRY * 2f, HeadRX * 2f));
        _headRenderers.Add(head.GetComponent<Renderer>());

        // Hair cap
        var hair = Part(_headRoot, "Hair", PrimitiveType.Sphere, s_hair,
            new Vector3(0f, HeadCY + 0.004f, -0.006f),
            new Vector3(HeadRX * 2.04f, HeadRY * 1.40f, HeadRX * 2.05f));
        _headRenderers.Add(hair.GetComponent<Renderer>());

        // Face plate (quad with generated texture, mirrored x to face correctly)
        var faceGO = GameObject.CreatePrimitive(PrimitiveType.Quad);
        faceGO.name = "Face";
        DestroyImmediate(faceGO.GetComponent<Collider>());
        faceGO.transform.SetParent(_headRoot, false);
        // Position it just in front of the head sphere surface
        faceGO.transform.localPosition = new Vector3(0f, HeadCY, HeadRX * 0.97f);
        // Scale: x is negative to flip texture left-right (character's right = viewer's left)
        faceGO.transform.localScale    = new Vector3(-(HeadRX * 1.75f), HeadRY * 2.0f, 1f);

        var faceMat = new Material(Shader.Find("Standard"));
        faceMat.mainTexture = s_faceTex;
        faceMat.SetFloat("_Glossiness", 0.12f);
        faceMat.SetFloat("_Metallic",   0f);
        faceMat.color = Color.white;
        // Enable transparency for the face texture alpha
        faceMat.SetFloat("_Mode", 3f); // Transparent
        faceMat.SetInt("_SrcBlend",    (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        faceMat.SetInt("_DstBlend",    (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        faceMat.SetInt("_ZWrite",      0);
        faceMat.EnableKeyword("_ALPHAPREMULTIPLY_ON");
        faceMat.renderQueue = 3000;
        faceGO.GetComponent<MeshRenderer>().sharedMaterial = faceMat;
        _headRenderers.Add(faceGO.GetComponent<Renderer>());

        // Ears
        var earL = Part(_headRoot, "EarL", PrimitiveType.Sphere, s_skin,
            new Vector3(-HeadRX * 0.97f, HeadCY, 0f),
            new Vector3(0.018f, 0.028f, 0.016f));
        var earR = Part(_headRoot, "EarR", PrimitiveType.Sphere, s_skin,
            new Vector3( HeadRX * 0.97f, HeadCY, 0f),
            new Vector3(0.018f, 0.028f, 0.016f));
        _headRenderers.Add(earL.GetComponent<Renderer>());
        _headRenderers.Add(earR.GetComponent<Renderer>());

        // Neck
        var neck = Part(root, "Neck", PrimitiveType.Cylinder, s_skin,
            new Vector3(0f, NeckCY, 0f),
            new Vector3(0.052f, 0.032f, 0.052f));
        _headRenderers.Add(neck.GetComponent<Renderer>());
    }

    void BuildTorso(Transform root)
    {
        _torso = Part(root, "Torso", PrimitiveType.Capsule, s_shirt,
            new Vector3(0f, TorsoMidY, 0f),
            new Vector3(0.250f, 0.140f, 0.185f));

        Part(root, "Hips", PrimitiveType.Capsule, s_pants,
            new Vector3(0f, 0.065f, 0f),
            new Vector3(0.225f, 0.060f, 0.168f));
    }

    void BuildArms(Transform root)
    {
        _lShoulder = Pivot(root, "LShoulder", new Vector3(-ShoulderX, ShoulderY, 0f));
        _rShoulder = Pivot(root, "RShoulder", new Vector3( ShoulderX, ShoulderY, 0f));

        BuildOneArm(_lShoulder, ref _lElbow);
        BuildOneArm(_rShoulder, ref _rElbow);
    }

    void BuildOneArm(Transform shoulder, ref Transform elbowOut)
    {
        Part(shoulder, "UpperArm", PrimitiveType.Cylinder, s_shirt,
            new Vector3(0f, -0.070f, 0f), new Vector3(0.060f, 0.070f, 0.060f));

        elbowOut = Pivot(shoulder, "Elbow", new Vector3(0f, -0.148f, 0f));

        Part(elbowOut, "ForeArm", PrimitiveType.Cylinder, s_shirt,
            new Vector3(0f, -0.058f, 0f), new Vector3(0.052f, 0.058f, 0.052f));
        Part(elbowOut, "Hand", PrimitiveType.Sphere, s_skin,
            new Vector3(0f, -0.130f, 0f), new Vector3(0.056f, 0.052f, 0.045f));
    }

    void BuildLegs(Transform root)
    {
        _lHip = Pivot(root, "LHip", new Vector3(-HipX, HipY, 0f));
        _rHip = Pivot(root, "RHip", new Vector3( HipX, HipY, 0f));

        BuildOneLeg(_lHip, ref _lKnee);
        BuildOneLeg(_rHip, ref _rKnee);
    }

    void BuildOneLeg(Transform hip, ref Transform kneeOut)
    {
        Part(hip, "Thigh", PrimitiveType.Cylinder, s_pants,
            new Vector3(0f, -ThighHalf, 0f), new Vector3(0.078f, ThighHalf, 0.078f));

        kneeOut = Pivot(hip, "Knee", new Vector3(0f, -ThighHalf * 2f, 0f));

        Part(kneeOut, "Shin", PrimitiveType.Cylinder, s_pants,
            new Vector3(0f, -ShinHalf, 0f), new Vector3(0.065f, ShinHalf, 0.065f));

        Part(kneeOut, "Shoe", PrimitiveType.Sphere, s_shoes,
            new Vector3(0f, -ShinHalf * 2f - 0.022f, 0.036f),
            new Vector3(0.082f, 0.052f, 0.115f));
    }

    // ── Factories ─────────────────────────────────────────────────────────────

    static Transform Pivot(Transform p, string n, Vector3 lp)
    {
        var t = new GameObject(n).transform;
        t.SetParent(p, false);
        t.localPosition = lp;
        return t;
    }

    static Transform Part(Transform p, string n, PrimitiveType type, Material mat,
                           Vector3 lp, Vector3 ls)
    {
        var go = GameObject.CreatePrimitive(type);
        go.name = n;
        Destroy(go.GetComponent<Collider>());
        var t = go.transform;
        t.SetParent(p, false);
        t.localPosition = lp;
        t.localScale    = ls;
        go.GetComponent<MeshRenderer>().sharedMaterial = mat;
        return t;
    }

    // ── Animation ─────────────────────────────────────────────────────────────

    void Update()
    {
        if (_rb == null) return;

        Vector3 hVel    = new Vector3(_rb.linearVelocity.x, 0f, _rb.linearVelocity.z);
        float   speed   = hVel.magnitude;
        float   blend   = Mathf.Clamp01(speed / 4.5f);
        bool    airborne= Mathf.Abs(_rb.linearVelocity.y) > 0.5f
                          && !Physics.Raycast(transform.position, Vector3.down, 0.72f);

        _walkPhase += Time.deltaTime * speed * 3.5f;

        float sine = Mathf.Sin(_walkPhase);

        // ── Legs ──────────────────────────────────────────────────────────────
        // Each hip swings forward (negative X rotation = forward swing)
        float lLegFwd = -sine * blend * 38f;
        float rLegFwd =  sine * blend * 38f;

        if (_lHip) _lHip.localRotation = Quaternion.Euler(lLegFwd, 0f, 0f);
        if (_rHip) _rHip.localRotation = Quaternion.Euler(rLegFwd, 0f, 0f);

        // Knee bends during the back-swing to clear the foot off the ground
        float lKnee = Mathf.Max(0f,  sine) * blend * 42f;
        float rKnee = Mathf.Max(0f, -sine) * blend * 42f;
        if (_lKnee) _lKnee.localRotation = Quaternion.Euler(lKnee, 0f, 0f);
        if (_rKnee) _rKnee.localRotation = Quaternion.Euler(rKnee, 0f, 0f);

        // ── Arms ──────────────────────────────────────────────────────────────
        // Arms swing opposite to legs; less amplitude than legs
        float lArmFwd =  sine * blend * 30f;
        float rArmFwd = -sine * blend * 30f;
        // Resting natural elbow bend = 12° + extra when arm swings back
        float lElbBend = 12f + Mathf.Max(0f, -sine) * blend * 28f;
        float rElbBend = 12f + Mathf.Max(0f,  sine) * blend * 28f;

        if (_lShoulder) _lShoulder.localRotation = Quaternion.Euler(lArmFwd, 0f, -14f);
        if (_rShoulder) _rShoulder.localRotation = Quaternion.Euler(rArmFwd, 0f,  14f);
        if (_lElbow)    _lElbow.localRotation    = Quaternion.Euler(lElbBend, 0f, 0f);
        if (_rElbow)    _rElbow.localRotation    = Quaternion.Euler(rElbBend, 0f, 0f);

        // ── Torso lean ────────────────────────────────────────────────────────
        if (_torso) _torso.localRotation = Quaternion.Euler(blend * 4f, 0f, 0f);

        // ── Airborne pose ─────────────────────────────────────────────────────
        if (airborne)
        {
            float ab = Mathf.Clamp01(Mathf.Abs(_rb.linearVelocity.y) * 0.18f);
            // Tuck knees up slightly when rising, extend when falling
            float kneeAng = _rb.linearVelocity.y > 0f ? 25f : -10f;
            if (_lKnee) _lKnee.localRotation = Quaternion.Lerp(_lKnee.localRotation,
                Quaternion.Euler(kneeAng, 0f, 0f), ab * 0.6f);
            if (_rKnee) _rKnee.localRotation = Quaternion.Lerp(_rKnee.localRotation,
                Quaternion.Euler(kneeAng, 0f, 0f), ab * 0.6f);
            // Arms out to sides for balance
            if (_lShoulder) _lShoulder.localRotation = Quaternion.Lerp(_lShoulder.localRotation,
                Quaternion.Euler(0f, 0f, -55f), ab * 0.5f);
            if (_rShoulder) _rShoulder.localRotation = Quaternion.Lerp(_rShoulder.localRotation,
                Quaternion.Euler(0f, 0f,  55f), ab * 0.5f);
        }
    }
}
