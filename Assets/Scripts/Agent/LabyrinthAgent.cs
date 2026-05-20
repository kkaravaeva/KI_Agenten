using Unity.MLAgents;
using Unity.MLAgents.Actuators;
using Unity.MLAgents.Sensors;
using UnityEngine;

public class LabyrinthAgent : Agent
{
    [Header("Bewegung")]
    public float moveSpeed = 3f;
    public float turnSpeed = 180f;

    [Header("Sprung")]
    public float jumpForce = 4.5f;
    [Tooltip("Phasenspezifischer Jump-Force-Override. Index = CurrentPhaseIndex. <=0 nutzt jumpForce.")]
    // V16: 12 Phasen (0..3 Trivial, 4 JumpWarmup, 5..7 Lava*, 8 Hazard, 9..11 Easy/Med/Hard).
    [SerializeField] private float[] phaseJumpForces = new float[] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    [Header("Air-Control (Fix 6.2)")]
    [Tooltip("Faktor auf moveSpeed wenn nicht grounded. 1.0 = volle Kontrolle. 0.5 = halbe.")]
    [SerializeField, Range(0f, 1f)] private float airControlFactor = 0.5f;

    [Header("Macro-Jump (Sprung-Sequence)")]
    [Tooltip("Action-Wert 2 in Branch 2 startet eine garantierte Sprung-Sequenz: forward+jump fuer mehrere FixedUpdates, bis isGrounded oder Timeout. Soll 1 Lava-Feld direkt vor dem Agenten sicher ueberbruecken.")]
    [SerializeField] private int macroJumpDurationFrames = 40;
    [Tooltip("Mindest-Air-Frames bevor die isGrounded-Pruefung die Sequenz beenden darf (verhindert Sofort-Abbruch im Take-off-Frame).")]
    [SerializeField] private int macroJumpMinAirborneFrames = 5;

    [Header("Physik (Fix 6.1)")]
    [Tooltip("Wenn true: Velocity-basierte Bewegung statt MovePosition. Experimentell — kann frühere Phasen regressionieren.")]
    [SerializeField] private bool useVelocityMovement = false;

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
    [SerializeField] private float lavaDeathPenalty = -0.3f;  // Fix 1.4
    [Tooltip("Phasenspezifischer Lava-Death-Penalty-Override. 0 = nutzt lavaDeathPenalty.")]
    // V16: P4 (JumpWarmup) hat keine Lava → 0. P5..P7 = Lava-Phasen mit milder Strafe.
    [SerializeField] private float[] phaseLavaDeathPenalties = new float[] { 0, 0, 0, 0, 0, -0.1f, -0.1f, -0.1f, -0.1f, 0, 0, -1f };
    [SerializeField] private float holeDeathPenalty = -1f;

    [Header("Reward – Timeout")]
    [SerializeField] private float timeoutPenalty = -5f;

    [Header("Reward – Lava-Sprung")]
    [SerializeField] private float lavaAttemptBaseReward = 0f;
    [SerializeField] private float lavaAboveMinDistance = 0.3f;
    [Tooltip("Belohnung bei erfolgreicher Landung nach 'über Lava' (Edge-Trigger, Fix 1.1)")]
    [SerializeField] private float lavaCrossSuccessReward = 5f;
    [Tooltip("V16 Fix I: Mini-Reward pro ausgeführtem Sprung in Lava-Phasen (P4..P8), nur wenn Lava in der Nähe. 0 = deaktiviert.")]
    [SerializeField] private float jumpSampleBonus = 0f;

    [Header("Reward – Zeit")]
    [SerializeField] private float stepPenalty = -0.005f;
    [Tooltip("Phasenspezifischer Step-Penalty-Override (Fix 4.4). 0 = nutzt stepPenalty.")]
    // V16: P0..P3 stärker bestrafen, P4..P7 (JumpWarmup + Lava) lockern,
    // P8 (Hazard) Default, P9..P11 zunehmend strenger. Siehe Plan §4 Fix K.
    [SerializeField] private float[] phaseStepPenalties = new float[] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    [Header("Wall-Climb Guard")]
    [SerializeField] private float wallClimbMaxY = 5.0f;
    [SerializeField] private float wallClimbPenalty = -1f;
    [SerializeField] private float maxUpwardVelocity = 3.5f;

    [Header("Reward – Shaping (PBRS)")]
    [SerializeField] private float distanceShapingScale = 0.1f;
    [SerializeField] private float pbrsGamma = 0.997f;  // Fix 4.3
    [Tooltip("Wenn true: PBRS basiert auf BFS-Pfad-Distanz statt euklidischer Distanz (Fix 3.3).")]
    [SerializeField] private bool usePathDistanceForPBRS = true;
    [Tooltip("PBRS pausiert wenn Agent über Lava oder Lava direkt voraus (Fix 1.2).")]
    [SerializeField] private bool pausePbrsOverLava = true;

    [Header("Curriculum – MaxStep pro Phase")]
    // V16: 12 Einträge — Phase 4 = JumpWarmup neu eingeschoben.
    // 0..3 Trivial (600), 4 JumpWarmup (800), 5..7 Lava* (1500), 8 Hazard (1500), 9 Easy (1500), 10 Medium (2000), 11 Hard (2500).
    [SerializeField] private int[] phaseMaxSteps = new int[] { 600, 600, 600, 600, 800, 1500, 1500, 1500, 1500, 1500, 2000, 2500 };

    [Tooltip("Wenn > 0, ueberschreibt phaseMaxSteps fuer diese Szene/Instanz. Nur fuer Tests, im Training auf 0 lassen.")]
    [SerializeField] private int testOverrideMaxSteps = 0;

    [Header("Observation – Distanz zum Ziel")]
    [SerializeField] private float maxObservationDistance = 20f;

    [Header("Debug")]
    public bool debugSensors = false;

    private Rigidbody rb;
    private bool isGrounded;
    private string lastGroundTag = "";
    private Transform goalTransform;

    // PBRS-State
    private float previousDistance = 0f;
    private float previousPathDistance = 0f;

    // Episoden-Tracking
    private int lastEpisodeStepCount = 0;
    private float lastEpisodeCumulativeReward = 0f;
    private float spawnY = 0f;
    private bool lastEpisodeWasSuccess = false;
    private bool episodeEndedByTerminal = false;

    // Lava-Stats (Fix 5.1)
    private int lavaJumpAttempts    = 0;
    private int lavaJumpsSuccessful = 0;
    private int lavaJumpsFailed     = 0;
    private bool wasAboveLava       = false;
    private bool pendingLavaLanding = false;
    private bool sensorSawLavaAhead = false; // Cache aus CollectObservations für PBRS-Pause

    // V16 Fix M: Sprung-/PBRS-Diagnostik
    private int   jumpsTotal      = 0;   // tatsächlich ausgeführte Sprünge (nur bei isGrounded)
    private int   jumpsNearLava   = 0;   // Sprünge mit Lava in Sicht/Anflug

    // Macro-Jump State (V18+)
    private bool macroJumpActive          = false;
    private int  macroJumpFramesElapsed   = 0;
    private int  macroJumpsTotal          = 0;   // gestartete Macro-Sequenzen pro Episode
    private float pathDistInit    = 0f;  // norm. Pfaddistanz zu Episode-Beginn
    private float pathDistFinal   = 0f;  // norm. Pfaddistanz beim Episode-Ende

    // V18 Diagnostik (für V19-Analyse): Wegentscheidungs-Tracking
    private int pathStepsCloser     = 0;   // Schritte mit ΔPathDist < 0 (Annäherung)
    private int pathStepsFarther    = 0;   // Schritte mit ΔPathDist > 0 (Entfernung — Sackgasse oder Rückweg)
    private int pathStepsEqual      = 0;   // Schritte ohne Pfaddistanz-Änderung (Wand, Idle, parallel)
    private int pathDistRawInit     = -1;  // Roh-Pfaddistanz in Zellen zu Episode-Beginn
    private int pathDistRawMax      = -1;  // Höchste erreichte Roh-Pfaddistanz in der Episode (Excursion-Indikator)
    private int pathDistRawFinal    = -1;  // Roh-Pfaddistanz beim Episode-Ende
    private int prevPathDistRaw     = -1;  // Letzter Wert für Delta-Berechnung
    private int branchTilesSeen     = 0;   // Wie oft der Agent ein Branch-Tile betreten hat
    private int branchWrongChoices  = 0;   // Wie oft die direkt-folgende Wahl suboptimal war
    private int branchOptimalDistPending = -1; // Speichert "optimal next pathDist" wenn letzter Step ein Branch war

    // Reward-Komponenten Logging (Fix 4.2)
    private float rewGoal, rewPBRS, rewStep, rewDeath, rewTimeout, rewLavaJump, rewLavaCross, rewWallClimb;

    // Terminal Reason (Fix 5.3): 0=Goal, 1=Lava, 2=Hole, 3=Timeout, -1=unknown
    private int terminalReason = -1;

    public override void Initialize()
    {
        rb = GetComponent<Rigidbody>();
        FindGoal(warnIfMissing: false);
    }

    public override void OnEpisodeBegin()
    {
        // ── Letzte Episode reporten (Fix 4.2, 5.1, 5.3, sowie Custom/SuccessRate für Kompat.) ──
        Academy.Instance.StatsRecorder.Add("Custom/SuccessRate", lastEpisodeWasSuccess ? 1f : 0f);
        Academy.Instance.StatsRecorder.Add("Custom/LavaJumpAttempts", lavaJumpAttempts);
        Academy.Instance.StatsRecorder.Add("Custom/LavaJumps/Attempted",  lavaJumpAttempts);
        Academy.Instance.StatsRecorder.Add("Custom/LavaJumps/Successful", lavaJumpsSuccessful);
        Academy.Instance.StatsRecorder.Add("Custom/LavaJumps/Failed",     lavaJumpsFailed);
        Academy.Instance.StatsRecorder.Add("Custom/CurriculumPhase",        CurriculumTracker.CurrentPhaseIndex);
        Academy.Instance.StatsRecorder.Add("Custom/CurriculumPhaseSampled", CurriculumTracker.LastSampledPhaseIndex);
        Academy.Instance.StatsRecorder.Add("Custom/TerminalReason",         terminalReason);

        Academy.Instance.StatsRecorder.Add("Reward/Goal",      rewGoal);
        Academy.Instance.StatsRecorder.Add("Reward/PBRS",      rewPBRS);
        Academy.Instance.StatsRecorder.Add("Reward/Step",      rewStep);
        Academy.Instance.StatsRecorder.Add("Reward/Death",     rewDeath);
        Academy.Instance.StatsRecorder.Add("Reward/Timeout",   rewTimeout);
        Academy.Instance.StatsRecorder.Add("Reward/LavaJump",  rewLavaJump);
        Academy.Instance.StatsRecorder.Add("Reward/LavaCross", rewLavaCross);
        Academy.Instance.StatsRecorder.Add("Reward/WallClimb", rewWallClimb);

        // V16 Fix M: Diagnostik — Sprung-Aktivität + PBRS-Gradient
        Academy.Instance.StatsRecorder.Add("Custom/JumpsTotal",     jumpsTotal);
        Academy.Instance.StatsRecorder.Add("Custom/JumpsNearLava",  jumpsNearLava);
        Academy.Instance.StatsRecorder.Add("Custom/MacroJumpsTotal", macroJumpsTotal);
        Academy.Instance.StatsRecorder.Add("Custom/PathDistInit",   pathDistInit);
        Academy.Instance.StatsRecorder.Add("Custom/PathDistFinal",  pathDistFinal);
        Academy.Instance.StatsRecorder.Add("Custom/PathDistDelta",  pathDistInit - pathDistFinal);

        // V18 Diagnostik (für V19): Wegentscheidungs-Telemetrie
        // - Path/RegressionRatio nahe 0 = sauber zielgerichtet | nahe 0.5 = oszillierend | >0.3 = oft falsch
        // - Path/MaxExcursion = wie tief in Sackgasse abgewichen (in Roh-Cells), 0 = nie aus dem optimalen Pfad
        // - Branch/WrongRatio nahe 0 = Branches werden gemeistert | nahe 0.5 = würfelt 50/50 | nahe 1 = systematisch falsch
        Academy.Instance.StatsRecorder.Add("Custom/Path/InitialCells", Mathf.Max(0, pathDistRawInit));
        Academy.Instance.StatsRecorder.Add("Custom/Path/FinalCells",   Mathf.Max(0, pathDistRawFinal));
        Academy.Instance.StatsRecorder.Add("Custom/Path/MaxCells",     Mathf.Max(0, pathDistRawMax));
        Academy.Instance.StatsRecorder.Add("Custom/Path/MaxExcursion",
            (pathDistRawInit >= 0 && pathDistRawMax >= 0) ? Mathf.Max(0, pathDistRawMax - pathDistRawInit) : 0);
        Academy.Instance.StatsRecorder.Add("Custom/Path/StepsCloser",  pathStepsCloser);
        Academy.Instance.StatsRecorder.Add("Custom/Path/StepsFarther", pathStepsFarther);
        Academy.Instance.StatsRecorder.Add("Custom/Path/StepsEqual",   pathStepsEqual);
        int totalMove = pathStepsCloser + pathStepsFarther;
        Academy.Instance.StatsRecorder.Add("Custom/Path/RegressionRatio",
            totalMove > 0 ? (float)pathStepsFarther / totalMove : 0f);
        Academy.Instance.StatsRecorder.Add("Custom/Branch/TilesSeen",     branchTilesSeen);
        Academy.Instance.StatsRecorder.Add("Custom/Branch/WrongChoices",  branchWrongChoices);
        Academy.Instance.StatsRecorder.Add("Custom/Branch/WrongRatio",
            branchTilesSeen > 0 ? (float)branchWrongChoices / branchTilesSeen : 0f);

        // Curriculum: EMA + Per-Phase-SuccessRate aktualisieren (Fix 2.2 + 5.2)
        CurriculumTracker.NotifyEpisodeEnd(lastEpisodeWasSuccess);

        Debug.Log($"[Episode] Neu | Steps={lastEpisodeStepCount} | CumReward={lastEpisodeCumulativeReward:F3} | Erfolg={lastEpisodeWasSuccess} | LavaAtt/Succ/Fail={lavaJumpAttempts}/{lavaJumpsSuccessful}/{lavaJumpsFailed} | Term={terminalReason}");

        // State-Reset
        lastEpisodeWasSuccess = false;
        lavaJumpAttempts      = 0;
        lavaJumpsSuccessful   = 0;
        lavaJumpsFailed       = 0;
        wasAboveLava          = false;
        pendingLavaLanding    = false;
        episodeEndedByTerminal = false;
        terminalReason        = -1;
        rewGoal = rewPBRS = rewStep = rewDeath = rewTimeout = rewLavaJump = rewLavaCross = rewWallClimb = 0f;

        // V16 Fix M: Diagnostik-Reset
        jumpsTotal       = 0;
        jumpsNearLava    = 0;
        pathDistInit     = 0f;
        pathDistFinal    = 0f;

        // Macro-Jump Reset
        macroJumpActive        = false;
        macroJumpFramesElapsed = 0;
        macroJumpsTotal        = 0;

        // V18 Diagnostik-Reset
        pathStepsCloser         = 0;
        pathStepsFarther        = 0;
        pathStepsEqual          = 0;
        pathDistRawInit         = -1;
        pathDistRawMax          = -1;
        pathDistRawFinal        = -1;
        prevPathDistRaw         = -1;
        branchTilesSeen         = 0;
        branchWrongChoices      = 0;
        branchOptimalDistPending = -1;

        if (mapGenerator != null)
        {
            mapGenerator.GenerateRuntimeMap();
            Vector3 spawnPos = mapGenerator.GetSpawnPosition();
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

        // MaxStep NACH GenerateRuntimeMap setzen
        int phase = CurriculumTracker.CurrentPhaseIndex;
        if (testOverrideMaxSteps > 0)
        {
            MaxStep = testOverrideMaxSteps;
        }
        else if (phaseMaxSteps != null && phase >= 0 && phase < phaseMaxSteps.Length)
        {
            MaxStep = phaseMaxSteps[phase];
        }

        FindGoal();
        previousDistance = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position)
            : 0f;
        previousPathDistance = mapGenerator != null
            ? mapGenerator.GetNormalizedPathDistance(transform.position)
            : 0f;

        // V16 Fix M: initiale Pfaddistanz für Diagnostik festhalten.
        pathDistInit  = previousPathDistance;
        pathDistFinal = previousPathDistance;

        // V18 Diagnostik: Roh-Pfaddistanz (in Cells) für Branch/Excursion-Analyse.
        if (mapGenerator != null)
        {
            pathDistRawInit  = mapGenerator.GetPathDistanceCells(transform.position);
            pathDistRawMax   = pathDistRawInit;
            pathDistRawFinal = pathDistRawInit;
            prevPathDistRaw  = pathDistRawInit;
        }
    }

    public override void CollectObservations(VectorSensor sensor)
    {
        // === Boden-Sensor: 6 Strahlen (Fix 3.1) ===
        //  0: unter Agent
        //  1: 1 vor
        //  2: 2 vor
        //  3: 3 vor
        //  4: 1 vor + halb-rechts
        //  5: 1 vor + halb-links
        Vector3[] checkOffsets = new Vector3[]
        {
            Vector3.zero,
            transform.forward * 1f,
            transform.forward * 2f,
            transform.forward * 3f,
            transform.forward * 1f + transform.right * 0.5f,
            transform.forward * 1f - transform.right * 0.5f,
        };

        bool lavaAhead = false;
        for (int i = 0; i < checkOffsets.Length; i++)
        {
            Vector3 rayOrigin = transform.position + checkOffsets[i] + Vector3.up * groundSensorHeight;
            RaycastHit hit;

            if (Physics.Raycast(rayOrigin, Vector3.down, out hit, groundSensorRange))
            {
                float typeCode = 0f;
                if (hit.collider.CompareTag("Floor")) typeCode = 1f;
                else if (hit.collider.CompareTag("Lava")) { typeCode = -1f; if (i >= 1 && i <= 3) lavaAhead = true; }
                else if (hit.collider.CompareTag("Hole")) typeCode = -0.5f;
                else if (hit.collider.CompareTag("Bridge")) typeCode = 0.5f;

                sensor.AddObservation(typeCode);
                sensor.AddObservation(hit.distance / groundSensorRange);
            }
            else
            {
                sensor.AddObservation(-1.5f);
                sensor.AddObservation(1f);
            }
        }
        sensorSawLavaAhead = lavaAhead;

        // === Eigengeschwindigkeit normalisiert (3 Observations) ===
        Vector3 normalizedVelocity = transform.InverseTransformDirection(rb.velocity) / moveSpeed;
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
            Vector3 directionToGoal = transform.InverseTransformDirection((goalTransform.position - transform.position).normalized);
            sensor.AddObservation(directionToGoal.x);
            sensor.AddObservation(directionToGoal.y);
            sensor.AddObservation(directionToGoal.z);
        }
        else
        {
            sensor.AddObservation(0f);
            sensor.AddObservation(0f);
            sensor.AddObservation(0f);
        }

        // === Distanz zum Ziel normalisiert (1 Observation, euklidisch) ===
        float distToGoal = goalTransform != null
            ? Vector3.Distance(transform.position, goalTransform.position)
            : 0f;
        sensor.AddObservation(distToGoal / maxObservationDistance);

        // === Pfad-Distanz zum Ziel normalisiert (1 Observation, Fix 3.3) ===
        float pathDistNorm = mapGenerator != null
            ? mapGenerator.GetNormalizedPathDistance(transform.position)
            : 1f;
        sensor.AddObservation(pathDistNorm);

        if (debugSensors)
        {
            Debug.Log($"[Sensor] LavaAhead={lavaAhead} Grounded={isGrounded} EuklDist={distToGoal:F2} PathDistN={pathDistNorm:F2}");
        }
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        CurriculumTracker.NotifyStep();

        // ── V18 Diagnostik: Pfad-Trajektorie + Branch-Entscheidungen ──
        // Wird vor der eigentlichen Reward/Action-Logik geprüft, damit die aktuelle
        // Position (= Resultat des letzten Steps) sauber gegen die Vorgänger-Position
        // verglichen werden kann. Konsumiert nur 1 Array-Lookup pro Step + ggf. 4
        // weitere bei Branch-Tile-Check → kein relevanter Overhead.
        if (mapGenerator != null)
        {
            int currentPathRaw = mapGenerator.GetPathDistanceCells(transform.position);
            if (currentPathRaw >= 0)
            {
                if (prevPathDistRaw >= 0)
                {
                    int delta = currentPathRaw - prevPathDistRaw;
                    if (delta > 0)      pathStepsFarther++;
                    else if (delta < 0) pathStepsCloser++;
                    else                pathStepsEqual++;
                }
                if (currentPathRaw > pathDistRawMax) pathDistRawMax = currentPathRaw;
                pathDistRawFinal = currentPathRaw;

                // Wurde im letzten Step eine Branch-Entscheidung getroffen? Dann jetzt prüfen,
                // ob die direkt-folgende Zelle suboptimal ist (PathDist > Min aller Neighbors damals).
                if (branchOptimalDistPending >= 0)
                {
                    if (currentPathRaw > branchOptimalDistPending)
                        branchWrongChoices++;
                    branchOptimalDistPending = -1;
                }

                // Ist die aktuelle Zelle ein Branch-Tile (mind. ein Pfad weiter weg um ≥2 Cells)?
                if (mapGenerator.IsBranchTile(transform.position))
                {
                    branchTilesSeen++;
                    branchOptimalDistPending = mapGenerator.GetMinNeighborPathDist(transform.position);
                }

                prevPathDistRaw = currentPathRaw;
            }
        }

        // ── Step-Penalty (Fix 4.4: phasenspezifisch falls gesetzt) ──
        int phaseIdx = CurriculumTracker.CurrentPhaseIndex;
        float effectiveStepPenalty = (phaseStepPenalties != null
                                       && phaseIdx >= 0
                                       && phaseIdx < phaseStepPenalties.Length
                                       && phaseStepPenalties[phaseIdx] != 0f)
            ? phaseStepPenalties[phaseIdx]
            : stepPenalty;
        AddReward(effectiveStepPenalty);
        rewStep += effectiveStepPenalty;

        // ── Timeout ──
        if (!episodeEndedByTerminal && MaxStep > 0 && StepCount >= MaxStep - 1)
        {
            AddReward(timeoutPenalty);
            rewTimeout += timeoutPenalty;
            terminalReason = 3;
            Debug.Log($"[Timeout] MaxStep={MaxStep} | Penalty={timeoutPenalty}");
        }

        // ── PBRS (Fix 1.2: Pause über/vor Lava, Fix 3.3: Pfad-Distanz, Fix 4.3: korrektes Gamma) ──
        if (goalTransform != null)
        {
            // V16 Fix C: Pause nur über Lava — Annäherung (sensorSawLavaAhead)
            // braucht den Gradienten, damit die Sprung-Action gelernt wird.
            bool aboveLava = DetectAboveLava();
            bool pauseShaping = pausePbrsOverLava && aboveLava;
            float scale = pauseShaping ? 0f : distanceShapingScale;

            float shapingDelta;
            if (usePathDistanceForPBRS && mapGenerator != null)
            {
                float currentPath = mapGenerator.GetNormalizedPathDistance(transform.position);
                shapingDelta = (previousPathDistance - pbrsGamma * currentPath) * scale;
                previousPathDistance = currentPath;
                pathDistFinal = currentPath;  // V16 Fix M
                // euklidisch trotzdem aktualisieren (Observation-Vergleich)
                previousDistance = Vector3.Distance(transform.position, goalTransform.position);
            }
            else
            {
                float currentDistance = Vector3.Distance(transform.position, goalTransform.position);
                shapingDelta = (previousDistance - pbrsGamma * currentDistance) * scale;
                previousDistance = currentDistance;
            }
            AddReward(shapingDelta);
            rewPBRS += shapingDelta;
        }

        // ── Wall-Climb Guard ──
        if (transform.position.y > spawnY + wallClimbMaxY)
        {
            AddReward(wallClimbPenalty);
            rewWallClimb += wallClimbPenalty;
            Debug.Log($"[WallClimb] Y={transform.position.y:F2} | Penalty={wallClimbPenalty}");
        }

        // ── Lava-Sprung-Erkennung (Fix 1.1 Edge-Trigger Landung + Fix 5.1 Stats) ──
        bool currentlyAboveLava = DetectAboveLava();
        // Aufsteigen über Lava
        if (currentlyAboveLava && !wasAboveLava)
        {
            lavaJumpAttempts++;
            pendingLavaLanding = true;
            float attemptReward = GetLavaAttemptReward(lavaJumpAttempts);
            if (attemptReward > 0f)
            {
                AddReward(attemptReward);
                rewLavaJump += attemptReward;
                Debug.Log($"[LavaJump-Attempt] #{lavaJumpAttempts} | Reward={attemptReward:F4}");
            }
        }
        // Erfolgreiche Landung auf Floor nach 'über Lava' → +5
        if (pendingLavaLanding && !currentlyAboveLava && isGrounded && lastGroundTag == "Floor")
        {
            AddReward(lavaCrossSuccessReward);
            rewLavaCross += lavaCrossSuccessReward;
            lavaJumpsSuccessful++;
            pendingLavaLanding = false;
            Debug.Log($"[LavaCross-Success] #{lavaJumpsSuccessful} | Reward={lavaCrossSuccessReward}");
        }
        wasAboveLava = currentlyAboveLava;

        lastEpisodeStepCount = StepCount;
        lastEpisodeCumulativeReward = GetCumulativeReward();

        // ── Aktionen (mit Macro-Jump-Override) ──
        // Branch 2: 0 = nichts, 1 = Standard-Jump, 2 = Macro-Jump starten.
        // Macro erzwingt forward+jump fuer mehrere FixedUpdates, bis isGrounded
        // (nach Mindest-Air-Frames) oder bis macroJumpDurationFrames erreicht ist.
        int moveAction;
        int turnAction;
        int jumpAction;

        if (!macroJumpActive && actions.DiscreteActions[2] == 2 && isGrounded)
        {
            macroJumpActive = true;
            macroJumpFramesElapsed = 0;
            macroJumpsTotal++;
        }

        if (macroJumpActive)
        {
            moveAction = 1;
            turnAction = 0;
            jumpAction = (macroJumpFramesElapsed == 0) ? 1 : 0;
            macroJumpFramesElapsed++;

            bool landedAfterAirborne = macroJumpFramesElapsed > macroJumpMinAirborneFrames && isGrounded;
            if (landedAfterAirborne || macroJumpFramesElapsed >= macroJumpDurationFrames)
            {
                macroJumpActive = false;
            }
        }
        else
        {
            moveAction = actions.DiscreteActions[0];
            turnAction = actions.DiscreteActions[1];
            jumpAction = (actions.DiscreteActions[2] == 1) ? 1 : 0;
        }

        // Phasenspezifischer Jump-Force-Override (Fix 6.3)
        float effectiveJumpForce = (phaseJumpForces != null
                                    && phaseIdx >= 0
                                    && phaseIdx < phaseJumpForces.Length
                                    && phaseJumpForces[phaseIdx] > 0f)
            ? phaseJumpForces[phaseIdx]
            : jumpForce;

        // Air-Control (Fix 6.2)
        float effectiveMoveSpeed = isGrounded ? moveSpeed : moveSpeed * airControlFactor;

        float turnAmount = 0f;
        switch (turnAction)
        {
            case 0: break;
            case 1: turnAmount = -turnSpeed * Time.fixedDeltaTime; break;
            case 2: turnAmount =  turnSpeed * Time.fixedDeltaTime; break;
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
            case 2: direction = targetRotation * Vector3.back;    break;
        }

        // Bewegung (Fix 6.1: optional Velocity)
        if (direction != Vector3.zero)
        {
            Vector3 horiz = direction.normalized * effectiveMoveSpeed;
            if (useVelocityMovement)
            {
                rb.velocity = new Vector3(horiz.x, rb.velocity.y, horiz.z);
            }
            else
            {
                rb.MovePosition(transform.position + horiz * Time.fixedDeltaTime);
            }
        }
        else if (useVelocityMovement && isGrounded)
        {
            // Bei Velocity-Modus & keine Input → horizontal abbremsen (sonst rutscht der Agent)
            rb.velocity = new Vector3(0f, rb.velocity.y, 0f);
        }

        if (jumpAction == 1 && isGrounded)
        {
            rb.AddForce(Vector3.up * effectiveJumpForce, ForceMode.Impulse);
            isGrounded = false;

            // V16 Fix M: Sprung-Sample-Statistik (nur tatsächlich ausgeführte Sprünge zählen)
            jumpsTotal++;
            bool nearLava = sensorSawLavaAhead || pendingLavaLanding || wasAboveLava;
            if (nearLava) jumpsNearLava++;

            // V16 Fix I: Mini-Reward für aktiv ausgeführten Sprung in Lava-Phasen,
            // ausschließlich wenn Lava im Anflug/sichtbar — verhindert „Spawn-Hüpfen".
            // Phase-Indices in V16: 4=JumpWarmup, 5..7=Lava*, 8=Hazard.
            if (jumpSampleBonus > 0f && nearLava && phaseIdx >= 4 && phaseIdx <= 8)
            {
                AddReward(jumpSampleBonus);
                rewLavaJump += jumpSampleBonus;
            }
        }
    }

    public override void Heuristic(in ActionBuffers actionsOut)
    {
        var d = actionsOut.DiscreteActions;
        d[0] = 0;
        if (Input.GetKey(KeyCode.W)) d[0] = 1;
        else if (Input.GetKey(KeyCode.S)) d[0] = 2;
        d[1] = 0;
        if (Input.GetKey(KeyCode.A)) d[1] = 1;
        else if (Input.GetKey(KeyCode.D)) d[1] = 2;
        d[2] = 0;
        if (Input.GetKey(KeyCode.Space)) d[2] = 1;
        if (Input.GetKey(KeyCode.Q))     d[2] = 2;
    }

    private void FixedUpdate()
    {
        GroundCheck();
        if (rb.velocity.y > maxUpwardVelocity)
            rb.velocity = new Vector3(rb.velocity.x, maxUpwardVelocity, rb.velocity.z);
    }

    private void GroundCheck()
    {
        Vector3 rayOrigin = transform.position;
        float rayLength = 0.5f + groundCheckDistance;

        RaycastHit hit;
        if (Physics.Raycast(rayOrigin, Vector3.down, out hit, rayLength))
        {
            isGrounded = hit.collider.CompareTag("Floor")
                      || hit.collider.CompareTag("Bridge")
                      || hit.collider.CompareTag("Platform");
            lastGroundTag = hit.collider.tag;
        }
        else
        {
            isGrounded = false;
            lastGroundTag = "";
        }
    }

    private void FindGoal(bool warnIfMissing = true)
    {
        goalTransform = mapGenerator != null ? mapGenerator.GetGoalTransform() : null;
        if (goalTransform == null && warnIfMissing)
            Debug.LogWarning("LabyrinthAgent: Kein Goal-Transform gefunden!");
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Goal"))
        {
            episodeEndedByTerminal = true;
            lastEpisodeWasSuccess = true;
            terminalReason = 0;
            AddReward(goalReward);
            rewGoal += goalReward;
            Debug.Log($"[Ziel] Reached | Reward={goalReward} | LavaAtt/Succ/Fail={lavaJumpAttempts}/{lavaJumpsSuccessful}/{lavaJumpsFailed}");
            EndEpisode();
        }
        else if (other.CompareTag("Lava"))
        {
            episodeEndedByTerminal = true;
            terminalReason = 1;
            // Failed lava jump zählen (Fix 5.1)
            if (pendingLavaLanding || wasAboveLava) lavaJumpsFailed++;
            pendingLavaLanding = false;
            int phaseIdx = CurriculumTracker.CurrentPhaseIndex;
            float effectiveLavaDeathPenalty = (phaseLavaDeathPenalties != null
                                               && phaseIdx >= 0
                                               && phaseIdx < phaseLavaDeathPenalties.Length
                                               && phaseLavaDeathPenalties[phaseIdx] != 0f)
                ? phaseLavaDeathPenalties[phaseIdx]
                : lavaDeathPenalty;
            AddReward(effectiveLavaDeathPenalty);
            rewDeath += effectiveLavaDeathPenalty;
            Debug.Log($"[Tod] Lava | Penalty={effectiveLavaDeathPenalty}");
            EndEpisode();
        }
        else if (other.CompareTag("KillZone"))
        {
            episodeEndedByTerminal = true;
            terminalReason = 2;
            AddReward(holeDeathPenalty);
            rewDeath += holeDeathPenalty;
            Debug.Log($"[Tod] Hole | Penalty={holeDeathPenalty}");
            EndEpisode();
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
        Vector3 rayOrigin = transform.position;
        float rayLength = 0.5f + groundCheckDistance;
        Gizmos.color = isGrounded ? Color.green : Color.red;
        Gizmos.DrawLine(rayOrigin, rayOrigin + Vector3.down * rayLength);

        Vector3[] checkOffsets = new Vector3[]
        {
            Vector3.zero,
            transform.forward * 1f,
            transform.forward * 2f,
            transform.forward * 3f,
            transform.forward * 1f + transform.right * 0.5f,
            transform.forward * 1f - transform.right * 0.5f,
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

        if (goalTransform != null)
        {
            Gizmos.color = Color.yellow;
            Vector3 dirToGoal = (goalTransform.position - transform.position).normalized;
            Gizmos.DrawLine(transform.position + Vector3.up * 0.5f,
                            transform.position + Vector3.up * 0.5f + dirToGoal * 2f);
        }
    }
}
