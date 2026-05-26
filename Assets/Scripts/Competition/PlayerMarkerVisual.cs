using UnityEngine;

/// <summary>
/// Adds a colored floating sphere above the human player's head so they are
/// immediately distinguishable from the AI agent (which looks identical because
/// HumanAgentVisual uses static shared materials).
///
/// The marker is created entirely at runtime from primitives — no additional
/// assets are needed.
/// </summary>
[DisallowMultipleComponent]
public class PlayerMarkerVisual : MonoBehaviour
{
    [Header("Marker")]
    [Tooltip("Farbe des Markers. Standard: Blau = Spieler, Rot wäre KI (falls benötigt).")]
    public Color markerColor = new Color(0.15f, 0.45f, 1.0f);   // Blau

    [Tooltip("Höhe über dem Pivot-Punkt (≈ Scheitel des Charakters).")]
    public float markerHeight = 0.72f;

    [Tooltip("Radius des Marker-Balls.")]
    public float markerRadius = 0.09f;

    // Optional: Halo-Ring unter der Kugel für bessere Sichtbarkeit
    [Header("Ring")]
    public bool  showRing      = true;
    public Color ringColor     = new Color(0.15f, 0.45f, 1.0f, 0.55f);

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    private void Awake()
    {
        BuildMarker();
    }

    // ── Aufbau ───────────────────────────────────────────────────────────────

    private void BuildMarker()
    {
        var root = new GameObject("PlayerMarker").transform;
        root.SetParent(transform, false);
        root.localPosition = new Vector3(0f, markerHeight, 0f);

        // ── Kugel ─────────────────────────────────────────────────────────────
        var sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.name = "MarkerSphere";
        Destroy(sphere.GetComponent<Collider>());
        sphere.transform.SetParent(root, false);
        sphere.transform.localPosition = Vector3.zero;
        sphere.transform.localScale    = Vector3.one * (markerRadius * 2f);

        var mat = new Material(Shader.Find("Standard"));
        mat.color = markerColor;
        mat.SetFloat("_Glossiness", 0.85f);
        mat.SetFloat("_Metallic",   0.15f);
        sphere.GetComponent<MeshRenderer>().material = mat;

        // ── Leuchtring (flach gedrückte Scheibe unter der Kugel) ─────────────
        if (showRing)
        {
            var ring = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            ring.name = "MarkerRing";
            Destroy(ring.GetComponent<Collider>());
            ring.transform.SetParent(root, false);
            ring.transform.localPosition = new Vector3(0f, -markerRadius * 1.1f, 0f);
            ring.transform.localScale    = new Vector3(markerRadius * 4f, 0.01f, markerRadius * 4f);

            var ringMat = new Material(Shader.Find("Standard"));
            ringMat.color = ringColor;
            // Halbtransparent
            ringMat.SetFloat("_Mode", 3f);
            ringMat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            ringMat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            ringMat.SetInt("_ZWrite",   0);
            ringMat.EnableKeyword("_ALPHAPREMULTIPLY_ON");
            ringMat.renderQueue = 3000;
            ringMat.SetFloat("_Glossiness", 0.95f);
            ringMat.SetFloat("_Metallic",   0.1f);
            ring.GetComponent<MeshRenderer>().material = ringMat;
        }
    }
}
