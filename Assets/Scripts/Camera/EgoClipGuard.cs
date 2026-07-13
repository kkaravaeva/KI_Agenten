using System.Collections.Generic;
using UnityEngine;

/// Fades the screen to black when the ego camera is inside or very close to
/// wall geometry. Prevents the "see-through wall" artifact that appears when
/// the agent's capsule slightly penetrates a wall and the near-clip plane slices
/// through the single-sided mesh (revealing the transparent backface).
[RequireComponent(typeof(Camera))]
public class EgoClipGuard : MonoBehaviour
{
    [Tooltip("Start fading when solid geometry is this close (metres)")]
    public float fadeStartDist = 0.22f;
    [Tooltip("Screen is fully black at this distance (metres)")]
    public float fadeEndDist   = 0.04f;
    [Tooltip("Fade transition speed")]
    public float fadeSpeed     = 16f;

    [Tooltip("Wenn true, wird nicht abgeblendet (z.B. während eines Kamera-Flugs).")]
    public bool  suppressed    = false;

    Camera     _cam;
    Texture2D  _blackTex;
    float      _alpha;
    Collider[] _agentCols = new Collider[0];

    // Pre-allocated buffer — avoids GC each frame
    readonly Collider[] _overlapBuf = new Collider[32];

    void Awake()
    {
        _cam = GetComponent<Camera>();
        _blackTex = new Texture2D(1, 1);
        _blackTex.SetPixel(0, 0, Color.black);
        _blackTex.Apply();
    }

    void Start()
    {
        // Wenn die Kamera als Kind eines Charakters hängt (Competition-Modus:
        // EgoCamera ist Kind des Players), nehmen wir die Collider des Eltern-Objekts.
        // Andernfalls Fallback auf den LabyrinthAgent (klassischer Training-Modus).
        var parentRb = GetComponentInParent<Rigidbody>();
        if (parentRb != null)
        {
            _agentCols = parentRb.GetComponentsInChildren<Collider>(includeInactive: true);
        }
        else
        {
            // Mehr-Agenten-Vergleich (Generalisierungstest): Kollider ALLER Agenten
            // sammeln, damit die POV-Kamera nicht am eigenen/fremden Agentenkörper
            // abdunkelt — nur echte Wände sollen den Fade auslösen.
            var cols = new List<Collider>();
            foreach (var agent in Object.FindObjectsByType<LabyrinthAgent>(FindObjectsInactive.Include, FindObjectsSortMode.None))
                cols.AddRange(agent.GetComponentsInChildren<Collider>(true));
            _agentCols = cols.ToArray();
        }
    }

    void Update()
    {
        if (!_cam.enabled || suppressed) { _alpha = Mathf.Lerp(_alpha, 0f, Time.deltaTime * fadeSpeed); return; }

        float dist   = NearestWallDist();
        float span   = Mathf.Max(fadeStartDist - fadeEndDist, 0.001f);
        float target = 1f - Mathf.Clamp01((dist - fadeEndDist) / span);
        _alpha = Mathf.Lerp(_alpha, target, Time.deltaTime * fadeSpeed);
    }

    float NearestWallDist()
    {
        int count = Physics.OverlapSphereNonAlloc(
                        transform.position, fadeStartDist,
                        _overlapBuf, ~0, QueryTriggerInteraction.Ignore);

        float min = fadeStartDist;
        for (int i = 0; i < count; i++)
        {
            if (IsAgentCollider(_overlapBuf[i])) continue;

            // ClosestPoint returns the surface point nearest to the camera
            float d = Vector3.Distance(
                          transform.position,
                          _overlapBuf[i].ClosestPoint(transform.position));
            if (d < min) min = d;
        }
        return min;
    }

    bool IsAgentCollider(Collider col)
    {
        foreach (var ac in _agentCols)
            if (ac == col) return true;
        return false;
    }

    void OnGUI()
    {
        if (_alpha < 0.005f) return;
        var prev = GUI.color;
        GUI.color = new Color(0f, 0f, 0f, _alpha);
        GUI.DrawTexture(new Rect(0f, 0f, Screen.width, Screen.height), _blackTex);
        GUI.color = prev;
    }
}
