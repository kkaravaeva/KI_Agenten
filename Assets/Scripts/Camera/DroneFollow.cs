using UnityEngine;

/// <summary>
/// Drohnen-Kamera: schwebt orthografisch senkrecht über dem Agenten.
/// Der Zoom wird jede Episode automatisch so eingestellt, dass das gesamte
/// Labyrinth gerade noch sichtbar ist — so nah am Agenten wie möglich.
/// </summary>
[RequireComponent(typeof(Camera))]
public class DroneFollow : MonoBehaviour
{
    [Header("Referenzen")]
    public Transform    target;
    public MapGenerator mapGenerator;

    [Header("Höhe & Padding")]
    public float height  = 30f;
    [Tooltip("Rand-Multiplikator (1 = exakt bündig, 1.05 = 5 % Luft)")]
    public float padding = 1.05f;

    [Header("Glättung")]
    public float positionSmoothTime = 0.12f;
    public float zoomSmoothSpeed    = 4f;

    private Camera  _cam;
    private Vector3 _posVelocity;

    private void Awake() => _cam = GetComponent<Camera>();

    private void LateUpdate()
    {
        if (target == null) return;

        // ── Position: Agent X/Z, feste Höhe ──────────────────────────────────
        Vector3 desired = new Vector3(target.position.x, height, target.position.z);
        transform.position = Vector3.SmoothDamp(
            transform.position, desired, ref _posVelocity, positionSmoothTime);
        transform.rotation = Quaternion.Euler(90f, 0f, 0f);

        // ── Orthografischer Zoom ──────────────────────────────────────────────
        if (mapGenerator == null || !mapGenerator.HasMapData) return;

        Bounds bounds  = mapGenerator.GetWorldBounds();
        float  camX    = transform.position.x;
        float  camZ    = transform.position.z;
        float  aspect  = _cam.aspect;

        // Wie groß muss orthographicSize sein damit ALLE 4 Seiten der Map
        // von der aktuellen Camera-Position (= Agent-Position) aus sichtbar sind?
        float needX = Mathf.Max(Mathf.Abs(bounds.max.x - camX),
                                Mathf.Abs(bounds.min.x - camX)) / aspect;
        float needZ = Mathf.Max(Mathf.Abs(bounds.max.z - camZ),
                                Mathf.Abs(bounds.min.z - camZ));

        float targetSize = Mathf.Max(needX, needZ) * padding;
        _cam.orthographicSize = Mathf.Lerp(
            _cam.orthographicSize, targetSize, Time.deltaTime * zoomSmoothSpeed);
    }
}
