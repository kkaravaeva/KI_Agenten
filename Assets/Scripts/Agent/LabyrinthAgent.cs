using Unity.MLAgents;
using Unity.MLAgents.Actuators;
using Unity.MLAgents.Sensors;
using UnityEngine;

public class LabyrinthAgent : Agent
{
    [Header("Bewegung")]
    public float moveSpeed = 3f;
    public float jumpForce = 5f;

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
        int action = actions.DiscreteActions[0];

        switch (action)
        {
            case 0: // Idle – keine Bewegung
                break;
            case 1: // Vorwaerts (+Z)
                rb.MovePosition(transform.position + Vector3.forward * moveSpeed * Time.fixedDeltaTime);
                break;
            case 2: // Rueckwaerts (-Z)
                rb.MovePosition(transform.position + Vector3.back * moveSpeed * Time.fixedDeltaTime);
                break;
            case 3: // Links (-X)
                rb.MovePosition(transform.position + Vector3.left * moveSpeed * Time.fixedDeltaTime);
                break;
            case 4: // Rechts (+X)
                rb.MovePosition(transform.position + Vector3.right * moveSpeed * Time.fixedDeltaTime);
                break;
            case 5: // Springen
                if (isGrounded)
                {
                    rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
                    isGrounded = false;
                }
                break;
        }
    }

    public override void Heuristic(in ActionBuffers actionsOut)
    {
        // Wird spaeter implementiert: Manuelle Steuerung zum Testen
    }

    private void OnCollisionEnter(Collision collision)
    {
        // Pruefen ob Agent den Boden beruehrt
        if (collision.gameObject.CompareTag("Floor") || collision.gameObject.CompareTag("Untagged"))
        {
            isGrounded = true;
        }
    }
}