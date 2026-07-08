using Unity.MLAgents;
using Unity.MLAgents.Actuators;
using Unity.MLAgents.Sensors;
using Unity.MLAgents.Policies;
using UnityEngine;
using System.Collections.Generic;

public class LabyrinthAgent : Agent
{
    [Header("Bewegung")]
    public float moveSpeed = 5f;
    public float turnSpeed = 180f;

    [Header("Sprung")]
    public float jumpForce = 9.0f;

    [Header("Ground Check")]
    public float groundCheckDistance = 0.15f;

    [Header("Boden-Sensor")]
    public float groundSensorRange = 2.0f;
    public float groundSensorHeight = 0.5f;

    [Header("Map")]
    public MapGenerator mapGenerator;

    [Header("Reward – Ziel")]
    [SerializeField] private float goalReward = 30f;

    [Header("Reward – Tod")]
    [SerializeField] private float lavaDeathPenalty = -3f;
    [SerializeField] private float holeDeathPenalty = -3f;

    [Header("Reward – Timeout")]
    [SerializeField] private float timeoutPenalty = -10f;

    [Header("Reward – Lava-Sprung")]
    [SerializeField] private float lavaAttemptBaseReward = 1.5f;
    [SerializeField] private float lavaCrossingReward = 8.0f;
    [SerializeField] private float lavaAboveMinDistance = 0.3f;

    [Header("Reward – Zeit")]
    [SerializeField] private float stepPenalty = -0.002f;

    [Header("Wall-Climb Guard")]
    [SerializeField] private float wallClimbMaxY = 5.0f;
    [SerializeField] private float wallClimbPenalty = -1f;
    [SerializeField] private float maxUpwardVelocity = 7.0f;

    [Header("Reward – Shaping (PBRS)")]
    [SerializeField] private float distanceShapingScale = 0.01f;
    [SerializeField] private float pbrsGamma = 1.0f;

    [Header("Curriculum – MaxStep pro Phase")]
    // Index = CurriculumTracker.CurrentPhaseIndex
    // 0 Trivial | 1 TrivialCorr | 2 TrivialLava | 3 Easy | 4 Medium | 5 Hard
    [SerializeField] private int[] phaseMaxSteps = new int[] { 600, 1200, 1200, 1500, 2000, 2500 };

    [Tooltip("Wenn > 0, ueberschreibt phaseMaxSteps fuer diese Szene/Instanz. Nur fuer Tests, im Training auf 0 lassen.")]
    [SerializeField] private int testOverrideMaxSteps = 0;

    [Header("Observation – Distanz zum Ziel")]
    [SerializeField] private float maxObservationDistance = 20f;

    [Header("Wand-Sensor")]
    [SerializeField] private float wallRaycastRange = 3.0f;
    [SerializeField] private float wallRaycastHeight = 0.5f;

    [Header("Reward – Sichtbarkeit")]
    [SerializeField] private float lineOfSightReward = 0.005f;

    [Header("Debug")]
    public bool debugSensors = false;

    [Header("V24 Transformer – Inference Mode")]
    [Tooltip("Aktivieren wenn das Transformer_v24.onnx Modell verwendet wird. Gibt exakt 21 Vektor-Obs aus (Boden + Velocity), die restlichen werden nicht benoetigt da das Modell nur damit trainiert wurde.")]
    [SerializeField] public bool v24CompatMode = false;

    [Header("Wettkampf-Modus")]
    [Tooltip("Wenn aktiv: kein EndEpisode, keine Rewards, kein Map-Neu-Generieren. Steuerung durch CompetitionManager.")]
    public bool competitionMode = false;
    /// <summary>Wird ausgeloest, wenn der Agent das Ziel im Wettkampfmodus erreicht.</summary>
    public System.Action onGoalReached;
    /// <summary>Wird ausgeloest, wenn der Agent im Wettkampfmodus stirbt (Lava / Loch).</summary>
    public System.Action onAgentDied;
    // Bewegungssperre (waehrend Countdown / nach Zieleinlauf)
    private bool movementFrozen = false;

    private Rigidbody rb;
    private bool isGrounded;
    private Transform goalTransform;
    private float previousDistance = 0f;
    private int lastEpisodeStepCount = 0;
    private float lastEpisodeCumulativeReward = 0f;
    private float spawnY = 0f;
    private bool lastEpisodeWasSuccess = false;
    private enum DeathReason { None, Lava, Hole, Timeout }
    private DeathReason lastDeathReason = DeathReason.None;

    private int lavaJumpAttempts = 0;
    private bool wasAboveLava = false;
    private bool episodeEndedByTerminal = false;
    private bool hasLineOfSight = false;

    // TensorBoard-Logging
    private string statPrefix = "";
    private const int ROLLING_WINDOW = 50;
    private Queue<float> rollingSuccesses = new Queue<float>();
    private float lastDistanceToGoal = 0f;
    private int lavaCrossingsThisEpisode = 0;

    // Erstes-Mal-Milestone pro Behavior (static = geteilt über alle Agenten derselben Architektur)
    private static readonly Dictionary<string, bool> firstLavaCrossingDone = new Dictionary<string, bool>();

    public override void Initialize()
    {
        rb = GetComponent<Rigidbody>();
        var bp = GetComponent<BehaviorParameters>();
        statPrefix = (bp != null ? bp.BehaviorName : "Agent") + "/";
        FindGoal(warnIfMissing: false);
    }

    // ── Wettkampf-Modus öffentliche API ──────────────────────────────────────

    /// <summary>Setzt den Agenten auf die aktuelle Spawn-Position zurück (ohne EndEpisode).</summary>
    public void RespawnAtStart()
    {
        if (mapGenerator == null) return;
        Vector3 spawnPos = mapGenerator.GetSpawnPosition();
        transform.position = spawnPos + Vector3.up * 0.6f;
        transform.localRotation = Quaternion.identity;
        rb.velocity        = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        episodeEndedByTerminal = false;
        lavaJumpAttempts       = 0;
        wasAboveLava           = false;
        if (goalTransform == null) FindGoal(warnIfMissing: false);
        previousDistance = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position) : 0f;
    }

    /// <summary>Goal-Transform nach Map-Neugenerierung aktualisieren.</summary>
    public void RefreshGoal() => FindGoal();

    /// <summary>Bewegt den Agenten nicht, er sammelt aber weiter Observations.</summary>
    public void FreezeMovement()   => movementFrozen = true;

    /// <summary>Gibt die Bewegung wieder frei.</summary>
    public void UnfreezeMovement() => movementFrozen = false;

    // ── Episode-Lifecycle ────────────────────────────────────────────────────

    public override void OnEpisodeBegin()
    {
        // Im Wettkampf-Modus übernimmt CompetitionManager das gesamte Reset/Positioning.
        if (competitionMode)
        {
            episodeEndedByTerminal = false;
            lavaJumpAttempts       = 0;
            wasAboveLava           = false;
            return;
        }

        var stats = Academy.Instance.StatsRecorder;

        // ── Erfolg & Rolling Average ───────────────────────────────────────────
        float successVal = lastEpisodeWasSuccess ? 1f : 0f;
        rollingSuccesses.Enqueue(successVal);
        if (rollingSuccesses.Count > ROLLING_WINDOW)
            rollingSuccesses.Dequeue();

        float rollingSuccess = 0f;
        foreach (float v in rollingSuccesses) rollingSuccess += v;
        rollingSuccess /= rollingSuccesses.Count;

        stats.Add(statPrefix + "SuccessRate",        successVal);
        stats.Add(statPrefix + "RollingSuccessRate", rollingSuccess);

        // ── Episodenlänge & Effizienz ─────────────────────────────────────────
        stats.Add(statPrefix + "EpisodeLength",      lastEpisodeStepCount);
        if (lastEpisodeWasSuccess)
            stats.Add(statPrefix + "StepsToGoal",    lastEpisodeStepCount);

        // ── Distanz bei Timeout ───────────────────────────────────────────────
        if (lastDeathReason == DeathReason.Timeout)
            stats.Add(statPrefix + "DistanceAtTimeout", lastDistanceToGoal);

        // ── Curriculum ────────────────────────────────────────────────────────
        stats.Add(statPrefix + "CurriculumPhase",    CurriculumTracker.CurrentPhaseIndex);

        // ── Todesursachen ─────────────────────────────────────────────────────
        stats.Add(statPrefix + "DeathByLava",        lastDeathReason == DeathReason.Lava    ? 1f : 0f);
        stats.Add(statPrefix + "DeathByHole",        lastDeathReason == DeathReason.Hole    ? 1f : 0f);
        stats.Add(statPrefix + "DeathByTimeout",     lastDeathReason == DeathReason.Timeout ? 1f : 0f);

        // ── Explorationsverhalten ─────────────────────────────────────────────
        stats.Add(statPrefix + "LavaJumpAttempts",   lavaJumpAttempts);
        stats.Add(statPrefix + "LavaCrossings",      lavaCrossingsThisEpisode);

        Debug.Log($"[{statPrefix}Episode] Steps={lastEpisodeStepCount} | Reward={lastEpisodeCumulativeReward:F3} | Erfolg={lastEpisodeWasSuccess} | Tod={lastDeathReason} | Phase={CurriculumTracker.CurrentPhaseIndex}");
        lastEpisodeWasSuccess    = false;
        lastDeathReason          = DeathReason.None;
        lavaJumpAttempts         = 0;
        wasAboveLava             = false;
        episodeEndedByTerminal   = false;
        lavaCrossingsThisEpisode = 0;

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

        // MaxStep NACH GenerateRuntimeMap setzen: GetNextLayout() kann die Phase advancen,
        // sonst läuft die erste Episode der neuen Phase mit dem MaxStep der alten Phase.
        if (testOverrideMaxSteps > 0)
        {
            MaxStep = testOverrideMaxSteps;
        }
        else
        {
            int phase = CurriculumTracker.CurrentPhaseIndex;
            if (phaseMaxSteps != null && phase >= 0 && phase < phaseMaxSteps.Length)
            {
                MaxStep = phaseMaxSteps[phase];
            }
        }

        FindGoal();
        previousDistance = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position)
            : 0f;
    }

    public override void CollectObservations(VectorSensor sensor)
    {
        // === Boden-Sensor (18 Observations: 9 Positionen × 2) ===
        Vector3[] checkOffsets = new Vector3[]
        {
            Vector3.zero,
            transform.forward * 1f,
            transform.forward * 2f,
            transform.forward * 0.7f + transform.right * 0.7f,
            transform.forward * 0.7f - transform.right * 0.7f,
            transform.right * 1f,
            -transform.right * 1f,
            transform.forward * 1.41f + transform.right * 1.41f,
            transform.forward * 1.41f - transform.right * 1.41f,
        };

        string[] offsetNames = new string[] {
            "Unter Agent", "1 Zelle voraus", "2 Zellen voraus",
            "1 Zelle rechts-vorne", "1 Zelle links-vorne",
            "1 Zelle rechts", "1 Zelle links",
            "2 Zellen diagonal rechts", "2 Zellen diagonal links"
        };

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
        Vector3 normalizedVelocity = transform.InverseTransformDirection(rb.velocity) / moveSpeed;
        sensor.AddObservation(normalizedVelocity.x);
        sensor.AddObservation(normalizedVelocity.y);
        sensor.AddObservation(normalizedVelocity.z);

        // V24-Kompatibilitätsmodus: nur 21 Obs (Boden 18 + Velocity 3)
        // Das V24-Transformer-Modell wurde ohne die folgenden Sensoren trainiert.
        if (v24CompatMode) return;

        // === Ground-Status (1 Observation) ===
        sensor.AddObservation(isGrounded ? 1f : 0f);

        // === Distanz zum Ziel normalisiert (1 Observation) ===
        float distToGoal = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position)
            : 0f;
        sensor.AddObservation(distToGoal / maxObservationDistance);

        if (debugSensors)
        {
            Debug.Log($"[Status] Velocity=({normalizedVelocity.x:F2}, {normalizedVelocity.y:F2}, {normalizedVelocity.z:F2}) isGrounded={isGrounded} DistToGoal={distToGoal:F2}");
        }

        // === Wand-Raycasts horizontal (4 Observations) ===
        Vector3 wallRayOrigin = transform.position + Vector3.up * wallRaycastHeight;
        Vector3[] wallDirs = new Vector3[] { transform.forward, transform.right, -transform.right, -transform.forward };
        string[] wallDirNames = new string[] { "vorwärts", "rechts", "links", "rückwärts" };

        for (int i = 0; i < wallDirs.Length; i++)
        {
            RaycastHit wallHit;
            if (Physics.Raycast(wallRayOrigin, wallDirs[i], out wallHit, wallRaycastRange,
                Physics.DefaultRaycastLayers, QueryTriggerInteraction.Ignore))
            {
                float wallDist = wallHit.distance / wallRaycastRange;
                sensor.AddObservation(wallDist);
                if (debugSensors)
                    Debug.Log($"[WandSensor] {wallDirNames[i]}: dist={wallDist:F2}");
            }
            else
            {
                sensor.AddObservation(1f);
                if (debugSensors)
                    Debug.Log($"[WandSensor] {wallDirNames[i]}: kein Treffer");
            }
        }

        // === Line-of-Sight zum Ziel (1 Observation) ===
        hasLineOfSight = false;
        if (goalTransform != null)
        {
            Vector3 agentEye = transform.position + Vector3.up * 0.5f;
            Vector3 dirToGoal = (goalTransform.position - transform.position).normalized;
            RaycastHit losHit;
            if (!Physics.Raycast(agentEye, dirToGoal, out losHit, distToGoal,
                Physics.DefaultRaycastLayers, QueryTriggerInteraction.Ignore))
                hasLineOfSight = true;
            else if (losHit.collider.CompareTag("Goal"))
                hasLineOfSight = true;

            if (debugSensors)
                Debug.Log($"[LOS] Sichtbar={hasLineOfSight}");
        }
        sensor.AddObservation(hasLineOfSight ? 1f : 0f);
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        // ── Im Wettkampf-Modus: keine Rewards, kein Curriculum-Tracking ─────────
        if (!competitionMode)
        {
            CurriculumTracker.NotifyStep();
            AddReward(stepPenalty);

            if (!episodeEndedByTerminal && MaxStep > 0 && StepCount >= MaxStep - 1)
            {
                lastDeathReason = DeathReason.Timeout;
                AddReward(timeoutPenalty);
                Debug.Log($"[Timeout] MaxStep={MaxStep} erreicht | Penalty={timeoutPenalty}");
            }

            if (goalTransform != null)
            {
                float currentDistance = Vector3.Distance(transform.position, goalTransform.position);
                AddReward((previousDistance - pbrsGamma * currentDistance) * distanceShapingScale);
                previousDistance    = currentDistance;
                lastDistanceToGoal  = currentDistance;
            }

            if (hasLineOfSight && lineOfSightReward > 0f)
                AddReward(lineOfSightReward);

            if (transform.position.y > spawnY + wallClimbMaxY)
            {
                AddReward(wallClimbPenalty);
                Debug.Log($"[WallClimb] Y={transform.position.y:F2} > SpawnY+{wallClimbMaxY} | Penalty={wallClimbPenalty}");
            }

            bool currentlyAboveLava = DetectAboveLava();
            if (currentlyAboveLava && !wasAboveLava)
            {
                lavaJumpAttempts++;
                float attemptReward = GetLavaAttemptReward(lavaJumpAttempts);
                if (attemptReward > 0f)
                {
                    AddReward(attemptReward);
                    Debug.Log($"[LavaJump] Versuch={lavaJumpAttempts} | Reward={attemptReward:F4}");
                }
            }
            bool landedAfterLava = wasAboveLava && !currentlyAboveLava &&
                                   (isGrounded || episodeEndedByTerminal);
            if (landedAfterLava)
            {
                AddReward(lavaCrossingReward);
                lavaCrossingsThisEpisode++;

                // Erstes Mal dieser Architektur — einmalig loggen
                if (!firstLavaCrossingDone.ContainsKey(statPrefix) || !firstLavaCrossingDone[statPrefix])
                {
                    firstLavaCrossingDone[statPrefix] = true;
                    Academy.Instance.StatsRecorder.Add(statPrefix + "FirstLavaCrossingAtStep", StepCount);
                    Debug.Log($"[MILESTONE] {statPrefix} Erste Lava-Überquerung nach {StepCount} Steps!");
                }

                Debug.Log($"[LavaKreuzung] Erfolgreich überquert | Reward={lavaCrossingReward} | Total={lavaCrossingsThisEpisode}");
            }
            wasAboveLava = currentlyAboveLava;

            lastEpisodeStepCount        = StepCount;
            lastEpisodeCumulativeReward = GetCumulativeReward();
        }

        // ── Bewegungssperre (Countdown / nach Ziel erreicht) ──────────────────
        if (movementFrozen) return;

        int moveAction = actions.DiscreteActions[0];
        int turnAction = actions.DiscreteActions[1];
        int jumpAction = actions.DiscreteActions[2];

        float turnAmount = 0f;
        switch (turnAction)
        {
            case 0: break;
            case 1: turnAmount = -turnSpeed * Time.fixedDeltaTime; break;
            case 2: turnAmount = turnSpeed * Time.fixedDeltaTime; break;
        }

        Quaternion targetRotation = rb.rotation;
        if (turnAmount != 0f)
        {
            targetRotation = rb.rotation * Quaternion.Euler(0f, turnAmount, 0f);
            rb.MoveRotation(targetRotation);
        }

        Vector3 direction = Vector3.zero;

        switch (moveAction)
        {
            case 0: break;
            case 1: direction = targetRotation * Vector3.forward; break;
            case 2: direction = targetRotation * Vector3.back; break;
        }

        if (direction != Vector3.zero)
        {
            rb.MovePosition(transform.position + direction.normalized * moveSpeed * Time.fixedDeltaTime);
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

        discreteActions[1] = 0;
        if (Input.GetKey(KeyCode.A)) discreteActions[1] = 1;
        else if (Input.GetKey(KeyCode.D)) discreteActions[1] = 2;

        discreteActions[2] = 0;
        if (Input.GetKey(KeyCode.Space)) discreteActions[2] = 1;
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
                      || hit.collider.CompareTag("Platform")
                      || hit.collider.CompareTag("Goal");
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
        // Wenn die Komponente deaktiviert ist (z.B. Competition-Szene: ScriptedAIAgent
        // läuft auf demselben GameObject), OnTriggerEnter ignorieren – Unity feuert
        // physikalische Callbacks auch auf deaktivierten MonoBehaviours.
        if (!enabled) return;

        if (other.CompareTag("Goal"))
        {
            if (competitionMode)
            {
                // Bewegung einfrieren, CompetitionManager benachrichtigen
                FreezeMovement();
                rb.velocity = Vector3.zero;
                onGoalReached?.Invoke();
            }
            else
            {
                episodeEndedByTerminal = true;
                lastEpisodeWasSuccess  = true;
                AddReward(goalReward);
                Debug.Log($"[Ziel] Ziel erreicht | Reward={goalReward} | LavaJumps={lavaJumpAttempts}");
                EndEpisode();
            }
        }
        else if (other.CompareTag("Lava"))
        {
            if (competitionMode)
            {
                RespawnAtStart();
                onAgentDied?.Invoke();
            }
            else
            {
                episodeEndedByTerminal = true;
                lastDeathReason        = DeathReason.Lava;
                AddReward(lavaDeathPenalty);
                Debug.Log($"[Tod] Todesursache=Lava | Reward={lavaDeathPenalty} | LavaJumps={lavaJumpAttempts}");
                EndEpisode();
            }
        }
        else if (other.CompareTag("KillZone"))
        {
            if (competitionMode)
            {
                RespawnAtStart();
                onAgentDied?.Invoke();
            }
            else
            {
                episodeEndedByTerminal = true;
                lastDeathReason        = DeathReason.Hole;
                AddReward(holeDeathPenalty);
                Debug.Log($"[Tod] Todesursache=Hole | Reward={holeDeathPenalty}");
                EndEpisode();
            }
        }
    }

    private bool DetectAboveLava()
    {
        if (isGrounded) return false;
        RaycastHit hit;
        if (Physics.Raycast(transform.position, Vector3.down, out hit, groundSensorRange))
            return hit.collider.CompareTag("Lava") && hit.distance > lavaAboveMinDistance;
        return false;
    }

    private float GetLavaAttemptReward(int attempt)
    {
        if (attempt == 1) return lavaAttemptBaseReward;
        if (attempt == 2) return lavaAttemptBaseReward / 4f;
        if (attempt == 3) return lavaAttemptBaseReward / 8f;
        return 0f;
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
            transform.forward * 2f,
            transform.forward * 0.7f + transform.right * 0.7f,
            transform.forward * 0.7f - transform.right * 0.7f,
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
