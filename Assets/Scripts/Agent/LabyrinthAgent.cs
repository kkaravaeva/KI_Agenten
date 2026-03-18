using Unity.MLAgents;
using Unity.MLAgents.Actuators;
using Unity.MLAgents.Sensors;
using UnityEngine;

public class LabyrinthAgent : Agent
{
    [Header("Bewegung")]
    public float moveSpeed = 3f;

    [Header("Sprung")]
    public float jumpForce = 4.5f;

    [Header("Ground Check")]
    public float groundCheckDistance = 0.15f;
    public LayerMask groundLayer;

    private Rigidbody rb;
    private bool isGrounded;

    public override void Initialize()
    {
        rb = GetComponent<Rigidbody>();
    }

    public override void OnEpisodeBegin()
    {
        // Wird spaeter implementiert: Position zuruecksetzen, Map laden etc.
    }

    public override void CollectObservations(VectorSensor sensor)
    {
        // Wird spaeter implementiert: Observations an das neuronale Netz uebergeben
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        // Branch 0: Bewegung (0=Idle, 1=Vorwaerts, 2=Rueckwaerts, 3=Links, 4=Rechts)
        int moveAction = actions.DiscreteActions[0];

        // Branch 1: Sprung (0=Kein Sprung, 1=Springen)
        int jumpAction = actions.DiscreteActions[1];

        // Bewegung ausfuehren
        Vector3 direction = Vector3.zero;

        switch (moveAction)
        {
            case 0: // Idle
                break;
            case 1: // Vorwaerts (+Z)
                direction = Vector3.forward;
                break;
            case 2: // Rueckwaerts (-Z)
                direction = Vector3.back;
                break;
            case 3: // Links (-X)
                direction = Vector3.left;
                break;
            case 4: // Rechts (+X)
                direction = Vector3.right;
                break;
        }

        if (direction != Vector3.zero)
        {
            rb.MovePosition(transform.position + direction * moveSpeed * Time.fixedDeltaTime);
        }

        // Sprung ausfuehren
        if (jumpAction == 1 && isGrounded)
        {
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
            isGrounded = false;
        }
    }

    public override void Heuristic(in ActionBuffers actionsOut)
    {
        // Wird spaeter implementiert: Manuelle Steuerung zum Testen
    }

    private void FixedUpdate()
    {
        GroundCheck();
    }

    private void GroundCheck()
    {
        // Raycast vom Collider-Zentrum nach unten
        // CapsuleCollider Center ist bei Y=0.5, also Raycast-Startpunkt = transform.position + Y=0.5
        Vector3 rayOrigin = transform.position + Vector3.up * 0.5f;
        float rayLength = 0.5f + groundCheckDistance;

        isGrounded = Physics.Raycast(rayOrigin, Vector3.down, rayLength, groundLayer);
    }

    // Debug-Visualisierung des Ground-Check-Rays im Scene View
    private void OnDrawGizmosSelected()
    {
        Vector3 rayOrigin = transform.position + Vector3.up * 0.5f;
        float rayLength = 0.5f + groundCheckDistance;

        Gizmos.color = isGrounded ? Color.green : Color.red;
        Gizmos.DrawLine(rayOrigin, rayOrigin + Vector3.down * rayLength);
    }
}