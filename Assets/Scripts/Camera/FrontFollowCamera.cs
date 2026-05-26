using UnityEngine;

/// Positions the camera in front of the agent, facing back at the agent's face.
/// Includes wall avoidance: if a wall is between the agent and the camera
/// position, the camera is pulled in front of the wall instead of going through it.
public class FrontFollowCamera : MonoBehaviour
{
    [Header("Target")]
    public Transform target;

    [Header("Offsets")]
    [Tooltip("How far in front of the agent the camera sits (world units)")]
    public float forwardDistance = 2.2f;
    [Tooltip("How high above the agent root the camera sits")]
    public float heightOffset = 0.55f;
    [Tooltip("Vertical point on the agent the camera looks at")]
    public float lookAtHeight = 0.42f;

    [Header("Smoothing")]
    public float positionSmoothTime  = 0.08f;
    public float rotationSmoothSpeed = 7f;

    [Header("Wall Avoidance")]
    [Tooltip("Sphere radius used for the wall-avoidance cast")]
    public float castRadius = 0.15f;
    [Tooltip("Minimum pull-back distance from a wall hit point")]
    public float wallPullback = 0.20f;

    Vector3 _posVelocity;
    Camera  _cam;

    void Awake()
    {
        _cam = GetComponent<Camera>();
        if (_cam != null) _cam.nearClipPlane = 0.05f;
    }

    public void SetTarget(Transform t) => target = t;

    void LateUpdate()
    {
        if (target == null) return;

        // Ideal position: stand in front of the agent
        Vector3 desired = target.position
                        + target.forward * forwardDistance
                        + Vector3.up     * heightOffset;

        // Wall avoidance: SphereCast from agent head toward desired position.
        // Starting inside the agent's own capsule means Unity skips it automatically.
        Vector3 castOrigin = target.position + Vector3.up * lookAtHeight;
        Vector3 toDesired  = desired - castOrigin;
        float   castLen    = toDesired.magnitude;

        if (castLen > 0.01f)
        {
            Vector3 castDir = toDesired / castLen;
            if (Physics.SphereCast(castOrigin, castRadius, castDir,
                                   out RaycastHit hit, castLen,
                                   ~0, QueryTriggerInteraction.Ignore))
            {
                // Place camera just in front of the wall surface
                float safeDist = Mathf.Max(hit.distance - castRadius - wallPullback, 0.3f);
                desired = castOrigin + castDir * safeDist;
            }
        }

        transform.position = Vector3.SmoothDamp(
            transform.position, desired, ref _posVelocity, positionSmoothTime);

        // Look at the agent's face
        Vector3 lookAt     = target.position + Vector3.up * lookAtHeight;
        var     desiredRot = Quaternion.LookRotation(lookAt - transform.position);
        transform.rotation = Quaternion.Slerp(
            transform.rotation, desiredRot, rotationSmoothSpeed * Time.deltaTime);
    }
}
