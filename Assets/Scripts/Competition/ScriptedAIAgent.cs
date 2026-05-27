using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Geskripteter KI-Gegner der aussieht wie ein ~80%-trainierter LSTM-Agent.
///
/// Kern-Idee: BFS liefert den optimalen Pfad als "Wissen". Darüber liegen mehrere
/// Verhaltens-Schichten, die das imperfekte, stochastische Erscheinungsbild eines
/// teilweise trainierten neuronalen Netzes imitieren:
///
///  – Perlin-Noise-Geschwindigkeit   → organische, glatte Temposchwankungen
///  – Richtungsrauschen              → keine geraden Linien, leicht pendelnde Bewegung
///  – Zögern / Pausen               → Modell-Inferenz-Artefakt: kurze Freeze-Momente
///  – Falsche Schritte               → Policy-Fehler: kurze Schritte in falsche Richtung
///  – Exploration                    → Erkundungsverhalten: kurze Abstecher
///  – Recovery                       → Stuck-Verhalten: zufällige Bewegung wenn blockiert
///  – Lava-Zögern + Timing-Varianz   → Unsicherheit bei Hindernissen
///  – Ziel-Urgency                   → Beschleunigung / Fokus wenn Ziel nahe
/// </summary>
[RequireComponent(typeof(Rigidbody))]
public class ScriptedAIAgent : MonoBehaviour
{
    // ── Bewegungs-Parameter ───────────────────────────────────────────────────

    [Header("Bewegung")]
    public float moveSpeed           = 2.5f;
    public float turnSpeed           = 500f;
    public float jumpForce           = 11.0f;
    public float groundCheckDistance = 0.15f;
    public float maxUpwardVelocity   = 7f;
    public float waypointRadius      = 0.44f;

    // ── Natürlichkeits-Parameter ──────────────────────────────────────────────

    [Header("Natürliche Variation")]
    [Tooltip("Glatte Perlin-Geschwindigkeitsschwankung (±Faktor)")]
    public float speedVariance       = 0.22f;
    [Tooltip("Winkelrauschen pro Frame in Grad — wirkt wie unvollkommene Zielverfolgung")]
    public float dirNoiseDeg         = 14.0f;
    [Tooltip("Geschwindigkeit mit der speedSmooth zum Target interpoliert")]
    public float speedLerpRate       = 2.8f;

    // ── Verhaltens-Wahrscheinlichkeiten ───────────────────────────────────────

    [Header("Verhaltens-Wahrscheinlichkeiten (pro Sekunde)")]
    [Tooltip("Chance pro Sekunde für eine kurze Pause (Modell-Freeze-Artefakt)")]
    public float pauseChance         = 0.12f;
    [Tooltip("Chance pro Sekunde für einen kurzen Abstecher in Nebengasse")]
    public float wanderChance        = 0.22f;
    [Tooltip("Chance pro Sekunde für einen kurzen Schritt in falsche Richtung")]
    public float falseStepChance     = 0.16f;

    // ── Lava-Verhalten ────────────────────────────────────────────────────────

    [Header("Lava")]
    [Tooltip("Ab dieser Distanz zum Post-Lava-Waypoint: Verlangsamung")]
    public float lavaSlowRadius      = 4.0f;
    [Tooltip("Unter dieser Distanz: Sprung wird ausgelöst (muss > Lava-Breite in Cells sein)")]
    public float lavaJumpRadius      = 3.5f;
    [Tooltip("Geschwindigkeitsfaktor beim Lava-Annähern (0–1)")]
    public float lavaApproachFactor  = 0.55f;
    [Tooltip("Chance vor dem Sprung kurz zu stoppen (Unsicherheit)")]
    public float lavaHesitateChance  = 0.25f;
    [Tooltip("Nach dieser Zeit vor der Lava wird zwingend gesprungen (Fallback)")]
    public float lavaJumpTimeout     = 1.2f;

    // ── Ziel-Urgency ──────────────────────────────────────────────────────────

    [Header("Ziel-Urgency")]
    [Tooltip("Ab dieser Distanz zum Ziel: Geschwindigkeitsboost + weniger Abweichungen")]
    public float urgencyDist         = 5.5f;
    [Tooltip("Maximaler Geschwindigkeitsmultiplikator nahe am Ziel")]
    public float urgencyBoost        = 1.28f;

    [Header("Ziel-Garantie")]
    [Tooltip("Sekunden ohne Annäherung ans Ziel bevor Direktmodus aktiviert wird")]
    public float noProgressTimeout    = 20f;
    [Tooltip("Chance pro ComputePath-Aufruf, einen zufälligen Umweg zu wählen (0 = immer optimal)")]
    [Range(0f, 0.55f)]
    public float detourChance         = 0.40f;

    // ── Stuck-Detection ───────────────────────────────────────────────────────

    [Header("Erkundungsphase")]
    [Tooltip("Minimale Erkundungszeit (s) bevor der Agent das Ziel sucht")]
    public float explorePhaseMin      = 20f;
    [Tooltip("Maximale Erkundungszeit (s) — zufällig pro Runde")]
    public float explorePhaseMax      = 50f;

    [Header("Stuck-Detection")]
    public float stuckInterval       = 2.0f;
    public float stuckThreshold      = 0.38f;

    // ── Respawn ───────────────────────────────────────────────────────────────

    [Header("Respawn")]
    public float respawnThinkTime    = 0.42f;

    // ── Referenzen / Events ───────────────────────────────────────────────────

    [Header("Referenzen")]
    public MapGenerator mapGenerator;

    public System.Action onGoalReached;
    public System.Action onAgentDied;

    // ═════════════════════════════════════════════════════════════════════════
    // Interner State
    // ═════════════════════════════════════════════════════════════════════════

    private Rigidbody rb;
    private bool      isGrounded;
    private bool      frozen;
    private bool      inJump;

    // ── Pfad ──────────────────────────────────────────────────────────────────
    private struct WP { public Vector3 pos; public bool jumpBefore; }
    private readonly List<WP> path = new List<WP>();
    private int wpIdx;

    // ── Verhaltens-Zustand ────────────────────────────────────────────────────
    private enum BState { Follow, Wander, Pause, FalseStep, Recovery }
    private BState bState     = BState.Follow;
    private float  stateTimer = 0f;

    // Wander
    private Vector3    wanderTarget;
    private int        wanderStepsLeft;
    private Vector2Int wanderDir;

    // FalseStep
    private Vector3 falseDir;
    private float   falseSpeed;

    // ── Geschwindigkeits-Noise (Perlin-basiert) ───────────────────────────────
    private float speedSmooth     = 1f;
    private float speedTarget     = 1f;
    private float speedRetimer    = 0f;
    private float perlinSeedA;    // individuelle Perlin-Offset pro Instanz
    private float perlinSeedB;

    // ── Stuck ─────────────────────────────────────────────────────────────────
    private Vector3 stuckLastPos;
    private float   stuckTimer;

    // ── Lava ─────────────────────────────────────────────────────────────────
    private bool  lavaHesitated;   // pro Lava-Überquerung nur einmal zögern
    private float lavaJumpTimer;   // zählt Zeit vor Lava hoch → Fallback-Sprung

    // ── Erkundungsphase ───────────────────────────────────────────────────────
    private bool  exploringPhase;      // true = random Ziele, kein direktes Ziel-BFS
    private float exploreTimer;        // Countdown bis Erkundung endet

    // ── Fortschritts-Garantie ─────────────────────────────────────────────────
    private float noProgressTimer;
    private float lastGoalDist     = float.MaxValue;
    private bool  directMode;          // kein Wander/FalseStep, folgt nur BFS
    private float directModeTimer;
    private float recomputeCooldown;

    // ═════════════════════════════════════════════════════════════════════════
    // Lifecycle
    // ═════════════════════════════════════════════════════════════════════════

    private void Awake()
    {
        rb             = GetComponent<Rigidbody>();
        rb.constraints = RigidbodyConstraints.FreezeRotation;
        perlinSeedA    = Random.Range(0f, 100f);
        perlinSeedB    = Random.Range(100f, 200f);
        stuckLastPos    = transform.position;
        stuckTimer      = stuckInterval;
        noProgressTimer = noProgressTimeout;
    }

    private void Start()
    {
        if (mapGenerator == null)
        {
            mapGenerator = Object.FindObjectOfType<MapGenerator>();
            if (mapGenerator == null)
                Debug.LogWarning("[ScriptedAIAgent] MapGenerator nicht gefunden!");
        }
    }

    private void FixedUpdate()
    {
        GroundCheck();

        // Aufwärts-Velocity begrenzen
        if (rb.velocity.y > maxUpwardVelocity)
            rb.velocity = new Vector3(rb.velocity.x, maxUpwardVelocity, rb.velocity.z);

        if (frozen)
        {
            rb.velocity = new Vector3(0f, rb.velocity.y, 0f);
            return;
        }

        TickSpeedNoise();
        TickStuckCheck();
        TickExplore();
        TickProgressCheck();

        switch (bState)
        {
            case BState.Follow:    TickFollow();    break;
            case BState.Wander:    TickWander();    break;
            case BState.Pause:     TickPause();     break;
            case BState.FalseStep: TickFalseStep(); break;
            case BState.Recovery:  TickRecovery();  break;
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Follow – BFS-Pfad verfolgen
    // ═════════════════════════════════════════════════════════════════════════

    private void TickFollow()
    {
        if (path.Count == 0 || wpIdx >= path.Count)
        {
            recomputeCooldown -= Time.fixedDeltaTime;
            if (recomputeCooldown <= 0f && !frozen)
            {
                // Im Erkundungsmodus: nächstes Zufallsziel; sonst direkt zum Ziel (kein Detour)
                if (!exploringPhase)
                {
                    directMode      = true;
                    directModeTimer = 8f;   // directMode bleibt stabil bis Ziel erreicht
                }
                ComputePath();
                recomputeCooldown = 0.5f;
            }
            // Nur im Zielmodus: zum Ziel driften wenn Pfad leer
            if (!exploringPhase && mapGenerator != null)
                MoveFree(mapGenerator.GetGoalPosition(), 0.8f);
            return;
        }

        WP      wp   = path[wpIdx];
        Vector3 pos  = transform.position;
        float   dist = Flat2D(pos, wp.pos);

        // ── Waypoint erreicht ─────────────────────────────────────────────────
        if (dist < waypointRadius)
        {
            inJump        = false;
            lavaHesitated = false;
            lavaJumpTimer = 0f;
            wpIdx++;

            if (wpIdx >= path.Count)
            {
                rb.velocity = new Vector3(0f, rb.velocity.y, 0f);
                return;
            }

            wp   = path[wpIdx];
            dist = Flat2D(pos, wp.pos);
        }

        // ── Verhaltenswürfel — jedes Frame, korrektes per-Sekunde Scaling ─────
        if (!wp.jumpBefore && !directMode && GoalDist(pos) > urgencyDist * 0.7f && !CanSeeGoal())
        {
            float roll   = Random.value;
            float pPause = pauseChance     * Time.fixedDeltaTime;
            // Kein zusätzlicher Wander-Abstecher während Erkundungsphase (Agent navigiert ohnehin random)
            float pWand  = (exploringPhase ? 0f : wanderChance) * Time.fixedDeltaTime;
            float pFalse = falseStepChance * Time.fixedDeltaTime;

            if (roll < pPause)
            {
                EnterPause(Random.Range(0.08f, 0.30f));
                return;
            }
            else if (roll < pPause + pWand)
            {
                TryEnterWander();
                if (bState != BState.Follow) return;
            }
            else if (roll < pPause + pWand + pFalse)
            {
                TryEnterFalseStep();
                if (bState != BState.Follow) return;
            }
        }

        MoveToWaypoint(wp, dist);
    }

    private void MoveToWaypoint(WP wp, float dist)
    {
        Vector3 pos = transform.position;
        Vector3 dir = FlatDir(pos, wp.pos);

        // ── Drehen mit Richtungsrauschen ─────────────────────────────────────
        if (dir.sqrMagnitude > 0.01f)
        {
            float   noise    = Random.Range(-dirNoiseDeg, dirNoiseDeg);
            Vector3 noisyDir = Quaternion.Euler(0f, noise, 0f) * dir;
            Quaternion tgtRot = Quaternion.LookRotation(noisyDir);
            rb.MoveRotation(Quaternion.RotateTowards(
                transform.rotation, tgtRot, turnSpeed * Time.fixedDeltaTime));
        }

        // ── Lava-Behandlung ───────────────────────────────────────────────────
        if (wp.jumpBefore)
        {
            lavaJumpTimer += Time.fixedDeltaTime;

            // Einmaliges Zögern kurz vor dem Absprung
            if (!lavaHesitated && dist < lavaJumpRadius + 0.3f
                && isGrounded && !inJump && Random.value < lavaHesitateChance)
            {
                lavaHesitated = true;
                EnterPause(Random.Range(0.08f, 0.20f));
                rb.velocity = new Vector3(0f, rb.velocity.y, 0f);
                return;
            }

            // Sprung: normaler Trigger ODER Timeout-Fallback (nie festsitzen)
            // Timeout nur wenn Agent bereits nahe genug an der Lava ist – sonst springt er ins Leere
            bool timeoutJump = lavaJumpTimer >= lavaJumpTimeout && dist < lavaSlowRadius && isGrounded && !inJump;
            bool normalJump  = dist < lavaJumpRadius && isGrounded && !inJump;
            if (normalJump || timeoutJump)
            {
                rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
                isGrounded    = false;
                inJump        = true;
                lavaJumpTimer = 0f;
            }
        }
        else
        {
            lavaJumpTimer = 0f;  // Kein Lava-Waypoint → Timer zurücksetzen
        }

        // ── Geschwindigkeitsberechnung ────────────────────────────────────────
        float eff = moveSpeed * speedSmooth;

        // Lava: Verlangsamung nur beim Annähern – NICHT während des Sprungs (sonst zu kurze Weite)
        if (wp.jumpBefore && dist < lavaSlowRadius && !inJump)
        {
            float t = Mathf.InverseLerp(0f, lavaSlowRadius, dist);
            eff *= Mathf.Lerp(lavaApproachFactor, 1f, t);
        }

        // Ziel-Urgency: je näher, desto schneller und fokussierter
        float gd = GoalDist(pos);
        if (gd < urgencyDist)
            eff *= Mathf.Lerp(urgencyBoost, 1f, gd / urgencyDist);

        // Im Sprung etwas langsamer (wirkt realistischer)
        if (inJump) eff *= 0.62f;

        rb.MovePosition(transform.position + new Vector3(dir.x, 0f, dir.z) * eff * Time.fixedDeltaTime);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Wander – Kurzer Abstecher in Nebengasse
    // ═════════════════════════════════════════════════════════════════════════

    private void TryEnterWander()
    {
        if (mapGenerator == null) return;
        MapData md = mapGenerator.CurrentMapData;
        if (md == null) return;

        Vector3    origin  = mapGenerator.MapOrigin;
        float      cs      = mapGenerator.cellSize;
        Vector2Int cur     = WorldToCell(transform.position, origin, cs);

        // Optimal-Richtung bestimmen (soll NICHT eingeschlagen werden)
        Vector2Int optDir = Vector2Int.zero;
        if (path.Count > 0 && wpIdx < path.Count)
            optDir = WorldToCell(path[wpIdx].pos, origin, cs) - cur;

        Vector2Int[] dirs = { Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right };
        var cands = new List<Vector2Int>();
        foreach (var d in dirs)
        {
            if (d == optDir) continue;
            Vector2Int n = cur + d;
            if (InBounds(md, n) && IsWalkable(md, n)
                && md.GetCell(n.x, n.y) != CellType.Lava) cands.Add(n);
        }

        if (cands.Count == 0) return;

        Vector2Int pick = cands[Random.Range(0, cands.Count)];
        wanderDir       = pick - cur;   // Erkundungsrichtung merken (Korridorverfolgung)
        wanderTarget    = origin + new Vector3(pick.x * cs, 0f, pick.y * cs);
        wanderStepsLeft = Random.Range(3, 7);
        bState          = BState.Wander;
        stateTimer      = Random.Range(1.5f, 3.5f);
    }

    private void TickWander()
    {
        // Ziel sichtbar: Abstecher sofort abbrechen und direkt hinlaufen
        if (CanSeeGoal())
        {
            exploringPhase = false;
            bState         = BState.Follow;
            ComputePath();
            return;
        }

        stateTimer -= Time.fixedDeltaTime;
        float dist = Flat2D(transform.position, wanderTarget);

        if (dist < waypointRadius || stateTimer <= 0f)
        {
            wanderStepsLeft--;
            if (wanderStepsLeft <= 0 || stateTimer <= 0f)
            {
                bState = BState.Follow;
                ComputePath();
                return;
            }
            PickNextWanderStep();
        }

        MoveFree(wanderTarget, 0.88f);
    }

    private void PickNextWanderStep()
    {
        if (mapGenerator == null) { bState = BState.Follow; ComputePath(); return; }
        MapData    md     = mapGenerator.CurrentMapData;
        Vector3    origin = mapGenerator.MapOrigin;
        float      cs     = mapGenerator.cellSize;
        Vector2Int cur    = WorldToCell(transform.position, origin, cs);

        Vector2Int[] dirs = { Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right };

        // Korridorverfolgung: 70 % Chance geradeaus weiter (wie ein Agent der einen Gang entlangläuft)
        if (wanderDir != Vector2Int.zero && Random.value < 0.70f)
        {
            Vector2Int straight = cur + wanderDir;
            if (InBounds(md, straight) && IsWalkable(md, straight)
                && md.GetCell(straight.x, straight.y) != CellType.Lava)
            {
                wanderTarget = origin + new Vector3(straight.x * cs, 0f, straight.y * cs);
                return;
            }
        }

        // Nebenrichtungen bevorzugen, Rückweg meiden
        Vector2Int backDir = -wanderDir;
        var opts = new List<Vector2Int>();
        foreach (var d in dirs)
        {
            if (d == backDir) continue;
            Vector2Int n = cur + d;
            if (InBounds(md, n) && IsWalkable(md, n)
                && md.GetCell(n.x, n.y) != CellType.Lava) opts.Add(n);
        }

        // Sackgasse: Rückweg erlauben
        if (opts.Count == 0)
        {
            foreach (var d in dirs)
            {
                Vector2Int n = cur + d;
                if (InBounds(md, n) && IsWalkable(md, n)) opts.Add(n);
            }
        }

        if (opts.Count == 0) { bState = BState.Follow; ComputePath(); return; }

        Vector2Int next = opts[Random.Range(0, opts.Count)];
        wanderDir    = next - cur;
        wanderTarget = origin + new Vector3(next.x * cs, 0f, next.y * cs);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Pause – Kurzes Einfrieren (Modell-Inferenz-Artefakt)
    // ═════════════════════════════════════════════════════════════════════════

    private void EnterPause(float duration)
    {
        bState     = BState.Pause;
        stateTimer = duration;
    }

    private void TickPause()
    {
        stateTimer -= Time.fixedDeltaTime;

        // Sanft abbremsen (kein harter Stop – sieht natürlicher aus)
        rb.velocity = new Vector3(
            rb.velocity.x * 0.86f,
            rb.velocity.y,
            rb.velocity.z * 0.86f);

        // Minimales Dreh-Rauschen (wirkt wie Orientierungssuche)
        float r = Random.Range(-35f, 35f) * Time.fixedDeltaTime;
        rb.MoveRotation(transform.rotation * Quaternion.Euler(0f, r, 0f));

        if (stateTimer <= 0f)
            bState = BState.Follow;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // FalseStep – Kurzer Schritt in die falsche Richtung
    // ═════════════════════════════════════════════════════════════════════════

    private void TryEnterFalseStep()
    {
        // Zielrichtung bestimmen
        Vector3 goalDir = Vector3.forward;
        if (path.Count > 0 && wpIdx < path.Count)
            goalDir = FlatDir(transform.position, path[wpIdx].pos);
        else if (mapGenerator != null)
            goalDir = FlatDir(transform.position, mapGenerator.GetGoalPosition());

        // Falsche Richtung: 110°–160° oder 200°–250° abweichend von Ziel
        float angle = Random.value < 0.5f
            ? Random.Range(110f, 160f)
            : Random.Range(200f, 250f);
        Vector3 candidate = (Quaternion.Euler(0f, angle, 0f) * goalDir).normalized;

        // Sicherheitscheck — kein Loch oder Lava in diese Richtung
        if (mapGenerator != null)
        {
            MapData md = mapGenerator.CurrentMapData;
            if (md != null)
            {
                Vector3    origin = mapGenerator.MapOrigin;
                float      cs     = mapGenerator.cellSize;
                Vector2Int probe  = WorldToCell(transform.position + candidate * 0.6f, origin, cs);
                if (InBounds(md, probe))
                {
                    CellType ct = md.GetCell(probe.x, probe.y);
                    if (ct == CellType.Hole || ct == CellType.Empty || ct == CellType.Lava)
                        return; // Abbruch wenn Richtung gefährlich
                }
            }
        }

        falseDir   = candidate;
        falseSpeed = moveSpeed * Random.Range(0.52f, 0.78f);
        bState     = BState.FalseStep;
        stateTimer = Random.Range(0.18f, 0.42f);
    }

    private void TickFalseStep()
    {
        // Ziel sichtbar: Fehlschritt sofort abbrechen
        if (CanSeeGoal())
        {
            bState = BState.Follow;
            ComputePath();
            return;
        }

        stateTimer -= Time.fixedDeltaTime;

        if (falseDir.sqrMagnitude > 0.01f)
        {
            Quaternion tgtRot = Quaternion.LookRotation(falseDir);
            rb.MoveRotation(Quaternion.RotateTowards(
                transform.rotation, tgtRot, turnSpeed * Time.fixedDeltaTime));
            rb.MovePosition(transform.position +
                new Vector3(falseDir.x, 0f, falseDir.z) * falseSpeed * Time.fixedDeltaTime);
        }

        if (stateTimer <= 0f)
            bState = BState.Follow;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Recovery – Agent war feststeckend, versucht zufällige Bewegungen
    // ═════════════════════════════════════════════════════════════════════════

    private void TickRecovery()
    {
        stateTimer -= Time.fixedDeltaTime;

        if (stateTimer <= 0f)
        {
            bState = BState.Follow;
            ComputePath();
            return;
        }

        // Zu einer zufälligen sicheren Nachbarzelle navigieren
        if (mapGenerator != null)
        {
            MapData md = mapGenerator.CurrentMapData;
            if (md != null)
            {
                Vector3    origin = mapGenerator.MapOrigin;
                float      cs     = mapGenerator.cellSize;
                Vector2Int cur    = WorldToCell(transform.position, origin, cs);
                Vector2Int[] dirs = { Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right };
                var safe = new List<Vector2Int>();
                foreach (var d in dirs)
                {
                    Vector2Int n = cur + d;
                    if (InBounds(md, n) && IsWalkable(md, n)) safe.Add(n);
                }
                if (safe.Count > 0)
                {
                    // Bevorzugt Richtung die dem Ziel am nächsten kommt
                    Vector2Int best = safe[0];
                    float bestDist  = float.MaxValue;
                    Vector2Int goalCell = WorldToCell(mapGenerator.GetGoalPosition(), origin, cs);
                    foreach (var c in safe)
                    {
                        float d = (c - goalCell).sqrMagnitude;
                        if (d < bestDist) { bestDist = d; best = c; }
                    }
                    // Mit ~30% Chance trotzdem eine suboptimale Richtung nehmen
                    if (Random.value < 0.30f) best = safe[Random.Range(0, safe.Count)];

                    Vector3 target = origin + new Vector3(best.x * cs, 0f, best.y * cs);
                    MoveFree(target, 0.72f);
                    return;
                }
            }
        }

        // Fallback: rückwärts laufen
        Vector3 backward = new Vector3(-transform.forward.x, 0f, -transform.forward.z).normalized;
        rb.MovePosition(transform.position + backward * moveSpeed * 0.5f * Time.fixedDeltaTime);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Stuck-Detection
    // ═════════════════════════════════════════════════════════════════════════

    private void TickStuckCheck()
    {
        // Im Sprung, in Recovery/Pause oder direkt vor Lava nicht prüfen
        if (inJump || bState == BState.Recovery || bState == BState.Pause) return;
        bool nearLavaWP = bState == BState.Follow && wpIdx < path.Count && path[wpIdx].jumpBefore;
        if (nearLavaWP) return;

        stuckTimer -= Time.fixedDeltaTime;
        if (stuckTimer > 0f) return;

        float moved = Flat2D(transform.position, stuckLastPos);
        if (moved < stuckThreshold && bState == BState.Follow && path.Count > 0)
        {
            bState     = BState.Recovery;
            stateTimer = Random.Range(0.55f, 1.35f);
        }

        stuckLastPos = transform.position;
        stuckTimer   = stuckInterval;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Fortschritts-Garantie – erzwingt Direktmodus bei ausbleibendem Fortschritt
    // ═════════════════════════════════════════════════════════════════════════

    private void TickProgressCheck()
    {
        if (frozen || exploringPhase) return;  // Kein Fortschrittsdruck während Erkundung

        float gd = GoalDist(transform.position);

        if (directMode)
        {
            directModeTimer -= Time.fixedDeltaTime;
            if (directModeTimer <= 0f)
            {
                directMode      = false;
                noProgressTimer = noProgressTimeout;
                lastGoalDist    = gd;
            }
            return;
        }

        // Fortschritt: Ziel mindestens 1 Unit näher als bisher gemessen
        if (gd < lastGoalDist - 1.0f)
        {
            lastGoalDist    = gd;
            noProgressTimer = noProgressTimeout;
        }
        else
        {
            noProgressTimer -= Time.fixedDeltaTime;
            if (noProgressTimer <= 0f)
            {
                directMode      = true;
                directModeTimer = 12f;
                noProgressTimer = noProgressTimeout;
                lastGoalDist    = gd;
                if (bState == BState.Wander || bState == BState.FalseStep)
                {
                    bState = BState.Follow;
                    ComputePath();
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Erkundungsphase – navigiert zu Zufallszielen bis Timer abläuft
    // ═════════════════════════════════════════════════════════════════════════

    private void TickExplore()
    {
        if (!exploringPhase || frozen) return;

        // Ziel sichtbar: Erkundungsphase sofort beenden und hinlaufen
        if (CanSeeGoal())
        {
            exploringPhase  = false;
            directMode      = false;
            noProgressTimer = noProgressTimeout;
            lastGoalDist    = float.MaxValue;
            if (bState == BState.Wander || bState == BState.FalseStep)
                bState = BState.Follow;
            ComputePath();
            return;
        }

        exploreTimer -= Time.fixedDeltaTime;
        if (exploreTimer <= 0f)
        {
            exploringPhase  = false;
            directMode      = false;
            noProgressTimer = noProgressTimeout;
            lastGoalDist    = float.MaxValue;
            // Jetzt BFS zum echten Ziel starten
            ComputePath();
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Speed-Noise — Perlin-Noise für glatte, organische Temposchwankungen
    // ═════════════════════════════════════════════════════════════════════════

    private void TickSpeedNoise()
    {
        speedRetimer -= Time.fixedDeltaTime;
        if (speedRetimer <= 0f)
        {
            // Zwei unabhängige Perlin-Samples für interessantere Variation
            float pa = Mathf.PerlinNoise(Time.time * 0.55f, perlinSeedA);
            float pb = Mathf.PerlinNoise(Time.time * 0.30f, perlinSeedB);
            float p  = (pa + pb) * 0.5f;   // 0..1

            speedTarget  = 1f + (p - 0.5f) * speedVariance * 2f;
            // Asymmetrisch: Agent ist öfter leicht schneller als langsamer
            speedTarget  = Mathf.Clamp(speedTarget,
                                        1f - speedVariance,
                                        1f + speedVariance * 0.65f);
            speedRetimer = Random.Range(0.25f, 0.80f);
        }
        speedSmooth = Mathf.Lerp(speedSmooth, speedTarget, speedLerpRate * Time.fixedDeltaTime);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Bewegungs-Hilfsmethoden
    // ═════════════════════════════════════════════════════════════════════════

    /// <summary>Bewegt den Agenten zu einem freien Ziel ohne Lava-Speziallogik.</summary>
    private void MoveFree(Vector3 target, float speedMult)
    {
        Vector3 dir = FlatDir(transform.position, target);
        if (dir.sqrMagnitude < 0.01f) return;

        Quaternion tgtRot = Quaternion.LookRotation(dir);
        rb.MoveRotation(Quaternion.RotateTowards(
            transform.rotation, tgtRot, turnSpeed * Time.fixedDeltaTime));

        float eff = moveSpeed * speedSmooth * speedMult;
        if (inJump) eff *= 0.62f;
        rb.MovePosition(transform.position + new Vector3(dir.x, 0f, dir.z) * eff * Time.fixedDeltaTime);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Ground Check
    // ═════════════════════════════════════════════════════════════════════════

    private void GroundCheck()
    {
        float rayLen = 0.5f + groundCheckDistance;
        bool  wasAir = !isGrounded;

        if (Physics.Raycast(transform.position, Vector3.down, out RaycastHit hit, rayLen))
            isGrounded = hit.collider.CompareTag("Floor")
                      || hit.collider.CompareTag("Bridge")
                      || hit.collider.CompareTag("Platform");
        else
            isGrounded = false;

        if (wasAir && isGrounded) inJump = false;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Trigger
    // ═════════════════════════════════════════════════════════════════════════

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Goal"))
        {
            FreezeMovement();
            rb.velocity = Vector3.zero;
            onGoalReached?.Invoke();
        }
        else if (other.CompareTag("Lava") || other.CompareTag("KillZone"))
        {
            RespawnAtStart();
            onAgentDied?.Invoke();
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // BFS-Pathfinding
    // ═════════════════════════════════════════════════════════════════════════

    public void ComputePath()
    {
        path.Clear();
        wpIdx         = 0;
        inJump        = false;
        lavaHesitated = false;
        lavaJumpTimer = 0f;

        if (mapGenerator == null) return;
        MapData md = mapGenerator.CurrentMapData;
        if (md == null) return;

        Vector3    origin = mapGenerator.MapOrigin;
        float      cs     = mapGenerator.cellSize;
        Vector2Int start  = WorldToCell(transform.position, origin, cs);

        // ── Erkundungsphase: Zufallsziel statt echtem Goal ────────────────────
        Vector2Int goal = exploringPhase
            ? PickRandomExploreTarget(md, start)
            : WorldToCell(mapGenerator.GetGoalPosition(), origin, cs);

        List<Vector2Int> gridPath = BFS(md, start, goal);
        if (gridPath == null || gridPath.Count < 2)
        {
            // Fallback: direkt weiter erkunden oder zum Goal
            if (!exploringPhase)
                path.Add(new WP { pos = mapGenerator.GetGoalPosition(), jumpBefore = false });
            return;
        }

        // Zufälliger Umweg nur im Zielmodus (Erkundung bringt ohnehin random Pfade)
        if (!exploringPhase && !directMode && detourChance > 0f
            && Random.value < detourChance && gridPath.Count > 4)
        {
            var optSet = new HashSet<Vector2Int>(gridPath);
            Vector2Int? detour = TryPickDetourCell(md, optSet);
            if (detour.HasValue)
            {
                var p1 = BFS(md, start, detour.Value);
                var p2 = BFS(md, detour.Value, WorldToCell(mapGenerator.GetGoalPosition(), origin, cs));
                if (p1 != null && p2 != null
                    && p1.Count + p2.Count - 1 <= gridPath.Count * 2)
                {
                    var combined = new List<Vector2Int>(p1);
                    for (int i = 1; i < p2.Count; i++) combined.Add(p2[i]);
                    gridPath = combined;
                }
            }
        }

        bool nextNeedsJump = false;
        for (int i = 1; i < gridPath.Count; i++)
        {
            Vector2Int cell = gridPath[i];
            CellType   type = md.GetCell(cell.x, cell.y);

            if (type == CellType.Lava) { nextNeedsJump = true; continue; }

            float   yOff = md.cellHeightOffsets.TryGetValue(cell, out float h) ? h : 0f;
            Vector3 wp   = origin + new Vector3(cell.x * cs, yOff, cell.y * cs);
            path.Add(new WP { pos = wp, jumpBefore = nextNeedsJump });
            nextNeedsJump = false;
        }
    }

    private List<Vector2Int> BFS(MapData md, Vector2Int start, Vector2Int goal)
    {
        if (!InBounds(md, start) || !InBounds(md, goal)) return null;

        var prev  = new Dictionary<Vector2Int, Vector2Int>();
        var queue = new Queue<Vector2Int>();
        prev[start] = start;
        queue.Enqueue(start);

        Vector2Int[] dirs = { Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right };
        while (queue.Count > 0)
        {
            Vector2Int cur = queue.Dequeue();
            if (cur == goal) break;
            foreach (var d in dirs)
            {
                Vector2Int n = cur + d;
                if (prev.ContainsKey(n) || !InBounds(md, n) || !IsWalkable(md, n)) continue;
                prev[n] = cur;
                queue.Enqueue(n);
            }
        }

        if (!prev.ContainsKey(goal)) return null;

        var result = new List<Vector2Int>();
        for (Vector2Int c = goal; c != start; c = prev[c]) result.Add(c);
        result.Add(start);
        result.Reverse();
        return result;
    }

    private Vector2Int? TryPickDetourCell(MapData md, HashSet<Vector2Int> optSet)
    {
        for (int attempt = 0; attempt < 20; attempt++)
        {
            int rx   = Random.Range(0, md.width);
            int ry   = Random.Range(0, md.height);
            var cell = new Vector2Int(rx, ry);
            if (!InBounds(md, cell) || optSet.Contains(cell)) continue;
            if (!IsWalkable(md, cell))                        continue;
            if (md.GetCell(cell.x, cell.y) == CellType.Lava) continue;
            return cell;
        }
        return null;
    }

    /// <summary>
    /// Wählt eine zufällige begehbare Zelle als Erkundungsziel.
    /// Das echte Goal wird ausgeschlossen damit die KI es nicht zufällig direkt anläuft.
    /// </summary>
    private Vector2Int PickRandomExploreTarget(MapData md, Vector2Int start)
    {
        Vector2Int goalCell = WorldToCell(
            mapGenerator.GetGoalPosition(), mapGenerator.MapOrigin, mapGenerator.cellSize);

        for (int attempt = 0; attempt < 40; attempt++)
        {
            int rx   = Random.Range(0, md.width);
            int ry   = Random.Range(0, md.height);
            var cell = new Vector2Int(rx, ry);
            if (!InBounds(md, cell) || cell == start)         continue;
            if (!IsWalkable(md, cell))                        continue;
            if (md.GetCell(cell.x, cell.y) == CellType.Lava) continue;
            // Nicht zu nah am echten Ziel — sonst läuft die KI es versehentlich an
            if ((cell - goalCell).sqrMagnitude < 9)           continue;
            return cell;
        }
        // Fallback: bleibt in der Nähe des Starts, nächster TickFollow recomputed
        return start;
    }

    private bool IsWalkable(MapData md, Vector2Int p)
    {
        switch (md.GetCell(p.x, p.y))
        {
            case CellType.Floor:    case CellType.SpawnPoint:
            case CellType.Goal:     case CellType.Platform:
            case CellType.Obstacle: return true;
            case CellType.Lava:     return IsSingleTileLava(md, p);
            default:                return false;
        }
    }

    private bool IsSingleTileLava(MapData md, Vector2Int p)
    {
        int w = LavaRun(md, p, Vector2Int.right) + LavaRun(md, p, Vector2Int.left)  + 1;
        int h = LavaRun(md, p, Vector2Int.up)    + LavaRun(md, p, Vector2Int.down)  + 1;
        return w == 1 || h == 1;
    }

    private int LavaRun(MapData md, Vector2Int p, Vector2Int dir)
    {
        int n = 0; Vector2Int c = p + dir;
        while (InBounds(md, c) && md.GetCell(c.x, c.y) == CellType.Lava) { n++; c += dir; }
        return n;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Hilfsmethoden
    // ═════════════════════════════════════════════════════════════════════════

    private bool CanSeeGoal()
    {
        if (mapGenerator == null) return false;
        Vector3 eye    = transform.position + Vector3.up * 0.5f;
        Vector3 goal   = mapGenerator.GetGoalPosition() + Vector3.up * 0.5f;
        Vector3 toGoal = goal - eye;
        if (toGoal.sqrMagnitude < 0.01f) return true;
        return !Physics.Raycast(eye, toGoal.normalized, toGoal.magnitude,
            Physics.DefaultRaycastLayers, QueryTriggerInteraction.Ignore);
    }

    private float GoalDist(Vector3 pos) =>
        mapGenerator != null ? Flat2D(pos, mapGenerator.GetGoalPosition()) : float.MaxValue;

    private static bool InBounds(MapData md, Vector2Int p) =>
        p.x >= 0 && p.x < md.width && p.y >= 0 && p.y < md.height;

    private static Vector2Int WorldToCell(Vector3 w, Vector3 origin, float cs) =>
        new Vector2Int(Mathf.RoundToInt((w.x - origin.x) / cs),
                       Mathf.RoundToInt((w.z - origin.z) / cs));

    private static float Flat2D(Vector3 a, Vector3 b) =>
        new Vector2(a.x - b.x, a.z - b.z).magnitude;

    private static Vector3 FlatDir(Vector3 from, Vector3 to)
    {
        var d = new Vector3(to.x - from.x, 0f, to.z - from.z);
        return d.sqrMagnitude > 0.0001f ? d.normalized : Vector3.zero;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Öffentliche API (identisch zu LabyrinthAgent – CompetitionManager-kompatibel)
    // ═════════════════════════════════════════════════════════════════════════

    public void FreezeMovement()
    {
        frozen      = true;
        rb.velocity = Vector3.zero;
    }

    public void UnfreezeMovement()
    {
        frozen          = false;
        directMode      = false;
        noProgressTimer = noProgressTimeout;
        lastGoalDist    = float.MaxValue;
        // Neue Runde → neue zufällige Erkundungszeit
        exploringPhase  = true;
        exploreTimer    = Random.Range(explorePhaseMin, explorePhaseMax);
        // Kurze Post-Countdown-Pause: wirkt wie Modell das aus dem Freeze aufwacht
        EnterPause(Random.Range(0.12f, 0.45f));
        ComputePath();  // Berechnet Pfad zu zufälligem Erkundungsziel
    }

    public void RespawnAtStart()
    {
        if (mapGenerator != null)
        {
            transform.position = mapGenerator.GetSpawnPosition() + Vector3.up * 0.6f;
            transform.rotation = Quaternion.identity;
        }
        rb.velocity        = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        inJump             = false;
        lavaHesitated      = false;
        path.Clear();
        wpIdx           = 0;
        bState          = BState.Pause;
        stateTimer      = 0f;
        directMode      = false;
        noProgressTimer = noProgressTimeout;
        lastGoalDist    = float.MaxValue;
        exploringPhase  = true;
        exploreTimer    = Random.Range(explorePhaseMin, explorePhaseMax);
        StartCoroutine(DelayedReplan());
    }

    private IEnumerator DelayedReplan()
    {
        yield return new WaitForSeconds(respawnThinkTime);
        if (!frozen) ComputePath();
    }

    public void RefreshGoal()
    {
        if (!frozen) ComputePath();
    }
}
