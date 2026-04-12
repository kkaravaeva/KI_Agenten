using UnityEngine;

public class ThirdPersonCamera : MonoBehaviour
{
    [Header("Ziel")]
    public Transform target;

    [Header("Offset (lokal zum Agenten)")]
    public float heightOffset = 3f;
    public float distanceOffset = 5f;

    [Header("Glättung")]
    public float positionSmoothTime = 0.1f;
    public float rotationSmoothSpeed = 5f;

    private Vector3 _positionVelocity = Vector3.zero;

    private void LateUpdate()
    {
        if (target == null)
            return;

        Vector3 localOffset = new Vector3(0f, heightOffset, -distanceOffset);
        Vector3 desiredPosition = target.position + target.rotation * localOffset;

        transform.position = Vector3.SmoothDamp(
            transform.position,
            desiredPosition,
            ref _positionVelocity,
            positionSmoothTime);

        Vector3 lookTarget = target.position + Vector3.up * 1f;
        Quaternion desiredRotation = Quaternion.LookRotation(lookTarget - transform.position);

        transform.rotation = Quaternion.Slerp(
            transform.rotation,
            desiredRotation,
            rotationSmoothSpeed * Time.deltaTime);
    }
}
