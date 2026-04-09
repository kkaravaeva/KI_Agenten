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

    [Header("Boden-Sensor")]
    public float groundSensorRange = 2.0f;
    public float groundSensorHeight = 0.5f;

    [Header("Map")]
    public MapGenerator mapGenerator;

    [Header("Debug")]
    public bool debugSensors = false;

    private Rigidbody rb;
    private bool isGrounded;
    private Transform goalTransform;

    public override void Initialize()
    {
        rb = GetComponent<Rigidbody>();
        FindGoal();
    }

    public override void OnEpisodeBegin()
    {
        if (mapGenerator != null)
        {
            Vector3 spawnPos = mapGenerator.GetSpawnPosition();
            transform.localPosition = spawnPos + Vector3.up * 0.5f;
            transform.localRotation = Quaternion.identity;
            rb.velocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
        else
        {
            Debug.LogWarning("LabyrinthAgent: Kein MapGenerator zugewiesen!");
        }

        FindGoal();
    }

    public override void CollectObservations(VectorSensor sensor)
    {
        // === Boden-Sensor (6 Observations) ===
        Vector3[] checkOffsets = new Vector3[]
        {
            Vector3.zero,
            transform.forward * 1f,
            transform.forward * 2f
        };

        string[] offsetNames = new string[] { "Unter Agent", "1 Zelle voraus", "2 Zellen voraus" };

        for (int i = 0; i < checkOffsets.Length; i++)
        {
            Vector3 rayOrigin = transform.position + checkOffsets[i] + Vector3.up * groundSensorHeight;
            RaycastHit hit;

            if (Physics.Raycast(rayOrigin, Vector3.down, out hit, groundSensorRange))
            {
                float typeCode = 0f;
                if (hit.collider.CompareTag("Floor")) typeCode = 1f;
                else if (hit.collider.CompareTag("Lava")) typeCode = -1f;
                else if (hit.collider.CompareTag("Hole")) typeCode = -0.5f;
                else if (hit.collider.CompareTag("Bridge")) typeCode = 0.5f;

                sensor.AddObservation(typeCode);
                sensor.AddObservation(hit.distance / groundSensorRange);

                if (debugSensors)
                {
                    Debug.Log($"[BodenSensor] {offsetNames[i]}: Tag={hit.collider.tag} TypeCode={typeCode} Dist={hit.distance / groundSensorRange:F2}");
                }
            }
            else
            {
                sensor.AddObservation(-0.5f);
                sensor.AddObservation(1f);

                if (debugSensors)
                {
                    Debug.Log($"[BodenSensor] {offsetNames[i]}: KEIN TREFFER (Abgrund)");
                }
            }
        }

        // === Eigengeschwindigkeit normalisiert (3 Observations) ===
        Vector3 normalizedVelocity = rb.velocity / moveSpeed;
        sensor.AddObservation(normalizedVelocity.x);
        sensor.AddObservation(normalizedVelocity.y);
        sensor.AddObservation(normalizedVelocity.z);

        // === Ground-Status (1 Observation) ===
        sensor.AddObservation(isGrounded ? 1f : 0f);

        // === Richtung zum Ziel normalisiert (3 Observations) ===
        if (goalTransform != null)
        {
            Vector3 directionToGoal = (goalTransform.position - transform.position).normalized;
            sensor.AddObservation(directionToGoal.x);
            sensor.AddObservation(directionToGoal.y);
            sensor.AddObservation(directionToGoal.z);

            if (debugSensors)
            {
                Debug.Log($"[Zielrichtung] Dir=({directionToGoal.x:F2}, {directionToGoal.y:F2}, {directionToGoal.z:F2})");
            }
        }
        else
        {
            sensor.AddObservation(0f);
            sensor.AddObservation(0f);
            sensor.AddObservation(0f);

            if (debugSensors)
            {
                Debug.LogWarning("[Zielrichtung] Kein Goal gefunden!");
            }
        }

        if (debugSensors)
        {
            Debug.Log($"[Status] Velocity=({normalizedVelocity.x:F2}, {normalizedVelocity.y:F2}, {normalizedVelocity.z:F2}) isGrounded={isGrounded}");
        }
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        int moveAction = actions.DiscreteActions[0];
        int jumpAction = actions.DiscreteActions[1];

        Vector3 direction = Vector3.zero;

        switch (moveAction)
        {
            case 0: break;
            case 1: direction = Vector3.forward; break;
            case 2: direction = Vector3.back; break;
            case 3: direction = Vector3.left; break;
            case 4: direction = Vector3.right; break;
        }

        if (direction != Vector3.zero)
        {
            rb.MovePosition(transform.position + direction * moveSpeed * Time.fixedDeltaTime);
        }

        if (jumpAction == 1 && isGrounded)
        {
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
            isGrounded = false;
        }
    }

    public override void Heuristic(in ActionBuffers actionsOut)
    {
        var discreteActions = actionsOut.DiscreteActions;

        discreteActions[0] = 0;
        if (Input.GetKey(KeyCode.W)) discreteActions[0] = 1;
        else if (Input.GetKey(KeyCode.S)) discreteActions[0] = 2;
        else if (Input.GetKey(KeyCode.A)) discreteActions[0] = 3;
        else if (Input.GetKey(KeyCode.D)) discreteActions[0] = 4;

        discreteActions[1] = 0;
        if (Input.GetKey(KeyCode.Space)) discreteActions[1] = 1;
    }

    private void FixedUpdate()
    {
        GroundCheck();
    }

    private void GroundCheck()
    {
        Vector3 rayOrigin = transform.position + Vector3.up * 0.5f;
        float rayLength = 1.0f + groundCheckDistance;

        isGrounded = Physics.Raycast(rayOrigin, Vector3.down, rayLength, groundLayer);
    }

    private void FindGoal()
    {
        GameObject goalObject = GameObject.FindWithTag("Goal");
        if (goalObject != null)
        {
            goalTransform = goalObject.transform;
        }
        else
        {
            goalTransform = null;
            Debug.LogWarning("LabyrinthAgent: Kein GameObject mit Tag 'Goal' gefunden!");
        }
    }

    private void OnDrawGizmosSelected()
    {
        // Ground Check Gizmo
        Vector3 rayOrigin = transform.position + Vector3.up * 0.5f;
        float rayLength = 1.0f + groundCheckDistance;

        Gizmos.color = isGrounded ? Color.green : Color.red;
        Gizmos.DrawLine(rayOrigin, rayOrigin + Vector3.down * rayLength);

        // Boden-Sensor Gizmos
        Vector3[] checkOffsets = new Vector3[]
        {
            Vector3.zero,
            transform.forward * 1f,
            transform.forward * 2f
        };

        foreach (Vector3 offset in checkOffsets)
        {
            Vector3 origin = transform.position + offset + Vector3.up * groundSensorHeight;
            RaycastHit hit;

            if (Physics.Raycast(origin, Vector3.down, out hit, groundSensorRange))
            {
                bool safe = hit.collider.CompareTag("Floor") || hit.collider.CompareTag("Bridge");
                Gizmos.color = safe ? Color.cyan : Color.magenta;
                Gizmos.DrawLine(origin, hit.point);
                Gizmos.DrawWireSphere(hit.point, 0.1f);
            }
            else
            {
                Gizmos.color = Color.magenta;
                Gizmos.DrawLine(origin, origin + Vector3.down * groundSensorRange);
            }
        }

        // Zielrichtung Gizmo
        if (goalTransform != null)
        {
            Gizmos.color = Color.yellow;
            Vector3 dirToGoal = (goalTransform.position - transform.position).normalized;
            Gizmos.DrawLine(transform.position + Vector3.up * 0.5f,
                            transform.position + Vector3.up * 0.5f + dirToGoal * 2f);
        }
    }
}