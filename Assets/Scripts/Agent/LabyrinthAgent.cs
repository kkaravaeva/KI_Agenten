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

    [Header("Boden-Sensor")]
    public float groundSensorRange = 2.0f;
    public float groundSensorHeight = 0.5f;

    [Header("Map")]
    public MapGenerator mapGenerator;

    [Header("Reward – Ziel")]
    [SerializeField] private float goalReward = 1f;

    [Header("Reward – Tod")]
    [SerializeField] private float lavaDeathPenalty = -1f;
    [SerializeField] private float holeDeathPenalty = -1f;

    [Header("Reward – Zeit")]
    [SerializeField] private float stepPenalty = -0.001f;

    [Header("Wall-Climb Guard")]
    [SerializeField] private float wallClimbMaxY = 3.0f;
    [SerializeField] private float wallClimbPenalty = -1f;
    [SerializeField] private float maxUpwardVelocity = 3.5f;

    [Header("Reward – Shaping (PBRS)")]
    [SerializeField] private float distanceShapingScale = 0.02f;
    [SerializeField] private float pbrsGamma = 0.99f;

    [Header("Observation – Distanz zum Ziel")]
    [SerializeField] private float maxObservationDistance = 20f;

    [Header("Debug")]
    public bool debugSensors = false;

    private Rigidbody rb;
    private bool isGrounded;
    private Transform goalTransform;
    private float previousDistance = 0f;
    private int lastEpisodeStepCount = 0;
    private float lastEpisodeCumulativeReward = 0f;
    private float spawnY = 0f;

    public override void Initialize()
    {
        rb = GetComponent<Rigidbody>();
        // warnIfMissing=false: Map ist zu diesem Zeitpunkt noch nicht generiert (Start läuft nach Initialize).
        // FindGoal() wird erneut in OnEpisodeBegin aufgerufen, wenn die Map bereit ist.
        FindGoal(warnIfMissing: false);
    }

    public override void OnEpisodeBegin()
    {
        Debug.Log($"[Episode] Neue Episode. Steps letzte Episode: {lastEpisodeStepCount} | Letzter Cumulative Reward: {lastEpisodeCumulativeReward:F3}");

        if (mapGenerator != null)
        {
            mapGenerator.GenerateRuntimeMap();
            Vector3 spawnPos = mapGenerator.GetSpawnPosition();
            // 0.6f statt 0.5f: Kapsel-Unterseite (transform.y - 0.5) bei 0.1m, Boden-Top bei 0.05m
            // → kein PhysX-Overlap, kein Depentrations-Impuls beim Spawn
            transform.position = spawnPos + Vector3.up * 0.6f;
            spawnY = transform.position.y;
            transform.localRotation = Quaternion.identity;
            rb.velocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
        else
        {
            Debug.LogWarning("LabyrinthAgent: Kein MapGenerator zugewiesen!");
        }

        FindGoal();
        previousDistance = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position)
            : 0f;
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
                sensor.AddObservation(-1.5f);
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
        if (goalTransform == null)
            FindGoal(warnIfMissing: false);

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

        // === Distanz zum Ziel normalisiert (1 Observation) ===
        float distToGoal = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position)
            : 0f;
        sensor.AddObservation(distToGoal / maxObservationDistance);

        if (debugSensors)
        {
            Debug.Log($"[Status] Velocity=({normalizedVelocity.x:F2}, {normalizedVelocity.y:F2}, {normalizedVelocity.z:F2}) isGrounded={isGrounded} DistToGoal={distToGoal:F2}");
        }
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        CurriculumTracker.NotifyStep();
        AddReward(stepPenalty);

        // PBRS: F(s,s') = γΦ(s') - Φ(s), Φ(s) = -distance_to_goal
        if (goalTransform != null)
        {
            float currentDistance = Vector3.Distance(transform.position, goalTransform.position);
            AddReward((previousDistance - pbrsGamma * currentDistance) * distanceShapingScale);
            previousDistance = currentDistance;
        }

        if (transform.position.y > spawnY + wallClimbMaxY)
        {
            AddReward(wallClimbPenalty);
            Debug.Log($"[WallClimb] Y={transform.position.y:F2} > SpawnY+{wallClimbMaxY} | Penalty={wallClimbPenalty}");
        }

        lastEpisodeStepCount = StepCount;
        lastEpisodeCumulativeReward = GetCumulativeReward();

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
            rb.MoveRotation(Quaternion.LookRotation(direction));
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

        if (rb.velocity.y > maxUpwardVelocity)
            rb.velocity = new Vector3(rb.velocity.x, maxUpwardVelocity, rb.velocity.z);

    }

    private void GroundCheck()
    {
        // Ray starts at capsule center (transform.position with center.y=0).
        // Length = half-height (0.5) + margin → detects floor within groundCheckDistance below capsule bottom.
        Vector3 rayOrigin = transform.position;
        float rayLength = 0.5f + groundCheckDistance;

        RaycastHit hit;
        if (Physics.Raycast(rayOrigin, Vector3.down, out hit, rayLength))
        {
            isGrounded = hit.collider.CompareTag("Floor")
                      || hit.collider.CompareTag("Bridge")
                      || hit.collider.CompareTag("Platform");
        }
        else
        {
            isGrounded = false;
        }
    }

    private void FindGoal(bool warnIfMissing = true)
    {
        if (mapGenerator != null)
        {
            goalTransform = mapGenerator.GetGoalTransform();
        }
        else
        {
            goalTransform = null;
        }

        if (goalTransform == null && warnIfMissing)
            Debug.LogWarning("LabyrinthAgent: Kein Goal-Transform gefunden! Ist MapGenerator zugewiesen und hat die Map ein Goal-Prefab?");
    }

    // === Architekturentscheidung: Zentrale Reward-Vergabe am Agent ===
    // Alle Reward-Werte bei Tod sind als serialisierte Felder am LabyrinthAgent definiert
    // (lavaDeathPenalty, holeDeathPenalty). Externe Trigger-Objekte (Lava, KillZone) rufen
    // keine Rewards direkt auf, sondern lösen nur OnTriggerEnter aus. Der Agent vergibt
    // den Reward intern. Das entspricht dem ML-Agents-Paradigma (nur die Agent-Klasse
    // darf AddReward/EndEpisode aufrufen) und erleichtert die Konfiguration in Milestone 5.
    //
    // Todesauslöser:
    // 1. Lava: IsTrigger=true am Lava-Prefab → Agent läuft in Trigger → lavaDeathPenalty
    // 2. Hole: Agent fällt durch HoleSurface-Layer → trifft KillZone-Box → holeDeathPenalty
    //    (Lava und Hole haben bewusst separate Felder für spätere Differenzierung)
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Goal"))
        {
            AddReward(goalReward);
            Debug.Log($"[Ziel] Ziel erreicht | Reward={goalReward}");
            EndEpisode();
        }
        else if (other.CompareTag("Lava"))
        {
            AddReward(lavaDeathPenalty);
            Debug.Log($"[Tod] Todesursache=Lava | Reward={lavaDeathPenalty}");
            EndEpisode();
        }
        else if (other.CompareTag("KillZone"))
        {
            AddReward(holeDeathPenalty);
            Debug.Log($"[Tod] Todesursache=Hole | Reward={holeDeathPenalty}");
            EndEpisode();
        }
    }

    private void OnDrawGizmosSelected()
    {
        // Ground Check Gizmo
        Vector3 rayOrigin = transform.position;
        float rayLength = 0.5f + groundCheckDistance;

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