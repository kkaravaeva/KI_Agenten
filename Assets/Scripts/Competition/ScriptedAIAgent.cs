using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Skriptierter KI-Gegner für den Competition-Modus.
///
/// Kernverhalten:
///   – BFS findet den kürzesten Weg zum Ziel auf dem aktuellen Grid.
///   – Mit einer gewissen Wahrscheinlichkeit weicht der Agent kurz vom
///     Optimalweg ab (erkundet eine Nebengasse), bevor er den Weg neu
///     berechnet und weitermacht. Das wirkt wie "Ausprobieren".
///   – Lava-Tiles (Breite 1) werden per Sprung überquert.
///   – Menschlich wirkende Details: Geschwindigkeitsvariation, kurze Pausen,
///     Verlangsamung vor Lava, Denkpause nach Respawn.
/// </summary>
[RequireComponent(typeof(Rigidbody))]
public class ScriptedAIAgent : MonoBehaviour
{
    // ── Bewegung ──────────────────────────────────────────────────────────────

    [Header("Bewegung")]
    public float moveSpeed           = 5.2f;
    public float turnSpeed           = 540f;
    public float jumpForce           = 9.0f;
    public float groundCheckDistance = 0.15f;
    public float maxUpwardVelocity   = 7f;
    public float waypointRadius      = 0.40f;

    // ── Verhalten ─────────────────────────────────────────────────────────────

    [Header("Verhalten")]
    [Tooltip("Wie oft (Faktor pro Sekunde) der Agent kurz vom Optimalweg abweicht")]
    public float explorationChance   = 0.10f;
    [Tooltip("Wie viele Schritte der Agent in eine Seitenrichtung erkundet bevor er neu plant")]
    public int   explorationSteps    = 3;
    [Tooltip("Geschwindigkeitsschwankung ±")]
    public float speedVariance       = 0.15f;
    [Tooltip("Pausenwahrscheinlichkeit pro Sekunde")]
    public float hesitationChance    = 0.06f;
    [Tooltip("Pausendauer in Sekunden")]
    public float hesitationDuration  = 0.32f;
    [Tooltip("Verlangsamung vor Lava-Sprüngen")]
    public float lavaApproachFactor  = 0.55f;
    [Tooltip("Denkpause nach Respawn")]
    public float respawnThinkTime    = 0.4f;

    // ── Referenzen / Events ───────────────────────────────────────────────────

    [Header("Referenzen")]
    public MapGenerator mapGenerator;

    public System.Action onGoalReached;
    public System.Action onAgentDied;

    // ── Interner State ────────────────────────────────────────────────────────

    private Rigidbody rb;
    private bool isGrounded;
    private bool frozen;
    private bool inJump;

    private struct WP { public Vector3 pos; public bool jumpBefore; }
    private readonly List<WP> path = new List<WP>();
    private int wpIdx;

    // Erkundungs-State
    private bool  exploring;
    private int   exploreRemaining;
    private Vector3 exploreTarget;

    // Timing
    private float hesitateTimer;
    private float speedFactor      = 1f;
    private float speedRerollTimer = 0f;

    // ── Lifecycle ────────────────────────────────────────────────────────────

    private void Awake()
    {
        rb             = GetComponent<Rigidbody>();
        rb.constraints = RigidbodyConstraints.FreezeRotation;
    }

    private void FixedUpdate()
    {
        GroundCheck();

        if (rb.velocity.y > maxUpwardVelocity)
            rb.velocity = new Vector3(rb.velocity.x, maxUpwardVelocity, rb.velocity.z);

        if (frozen) return;

        TickTimers();

        if (hesitateTimer > 0f) return;

        if (exploring)
            DoExplore();
        else
            FollowPath();
    }

    // ── Hauptpfad-Verfolgung ──────────────────────────────────────────────────

    private void FollowPath()
    {
        if (path.Count == 0 || wpIdx >= path.Count) return;

        WP      wp       = path[wpIdx];
        Vector3 pos      = transform.position;
        float   flatDist = Flat2D(pos, wp.pos);

        // Waypoint erreicht
        if (flatDist < waypointRadius)
        {
            inJump = false;
            wpIdx++;
            if (wpIdx >= path.Count) return;
            wp       = path[wpIdx];
            flatDist = Flat2D(pos, wp.pos);

            // Gelegentlich in eine Nebengasse abbiegen
            if (!wp.jumpBefore && Random.value < explorationChance * Time.fixedDeltaTime * 60f)
            {
                TryStartExploration();
                return;
            }
        }

        MoveTowards(wp.pos, wp.jumpBefore, flatDist);
    }

    // ── Erkundungs-Modus ──────────────────────────────────────────────────────

    private void TryStartExploration()
    {
        if (mapGenerator == null) return;
        MapData md = mapGenerator.CurrentMapData;
        if (md == null) return;

        Vector3    origin  = mapGenerator.MapOrigin;
        float      cs      = mapGenerator.cellSize;
        Vector2Int cur     = WorldToCell(transform.position, origin, cs);
        Vector2Int goalCell= WorldToCell(mapGenerator.GetGoalPosition(), origin, cs);

        // Alle orthogonalen Nachbarn, die NICHT der nächste Optimal-Waypoint-Richtung entsprechen
        var optDir = path.Count > 0 && wpIdx < path.Count
            ? WorldToCell(path[wpIdx].pos, origin, cs) - cur
            : Vector2Int.zero;

        Vector2Int[] dirs = { Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right };
        var candidates = new List<Vector2Int>();
        foreach (var d in dirs)
        {
            if (d == optDir) continue;                          // nicht den Optimalweg
            Vector2Int n = cur + d;
            if (!InBounds(md, n) || !IsWalkable(md, n)) continue;
            if (n == goalCell) continue;                        // Ziel nie überspringen
            candidates.Add(n);
        }

        if (candidates.Count == 0) return;

        Vector2Int pick   = candidates[Random.Range(0, candidates.Count)];
        exploreTarget     = origin + new Vector3(pick.x * cs, 0f, pick.y * cs);
        exploring         = true;
        exploreRemaining  = explorationSteps;
    }

    private void DoExplore()
    {
        Vector3 pos      = transform.position;
        float   flatDist = Flat2D(pos, exploreTarget);

        if (flatDist < waypointRadius)
        {
            exploreRemaining--;
            if (exploreRemaining <= 0)
            {
                // Erkundung beenden, Pfad neu berechnen
                exploring = false;
                ComputePath();
                return;
            }

            // Nächsten zufälligen Schritt wählen
            MapData    md     = mapGenerator?.CurrentMapData;
            Vector3    origin = mapGenerator.MapOrigin;
            float      cs     = mapGenerator.cellSize;
            Vector2Int cur    = WorldToCell(pos, origin, cs);
            Vector2Int[] dirs = { Vector2Int.up, Vector2Int.down, Vector2Int.left, Vector2Int.right };
            var opts = new List<Vector2Int>();
            foreach (var d in dirs)
            {
                Vector2Int n = cur + d;
                if (InBounds(md, n) && IsWalkable(md, n)) opts.Add(n);
            }
            if (opts.Count == 0) { exploring = false; ComputePath(); return; }

            Vector2Int next = opts[Random.Range(0, opts.Count)];
            exploreTarget   = origin + new Vector3(next.x * cs, 0f, next.y * cs);
        }

        MoveTowards(exploreTarget, false, flatDist);
    }

    // ── Bewegungs-Primitive ───────────────────────────────────────────────────

    private void MoveTowards(Vector3 target, bool jumpBefore, float flatDist)
    {
        Vector3 pos = transform.position;
        Vector3 dir = FlatDir(pos, target);

        // Drehen
        if (dir.sqrMagnitude > 0.01f)
        {
            Quaternion tgt = Quaternion.LookRotation(dir);
            rb.MoveRotation(Quaternion.RotateTowards(
                transform.rotation, tgt, turnSpeed * Time.fixedDeltaTime));
        }

        // Sprung kurz vor Lava
        if (jumpBefore && flatDist < 1.5f && isGrounded && !inJump)
        {
            if (Random.value < 0.35f)
            {
                hesitateTimer = Random.Range(0.06f, 0.20f);
                return;
            }
            rb.AddForce(Vector3.up * jumpForce + dir * 1.8f, ForceMode.Impulse);
            isGrounded = false;
            inJump     = true;
        }

        // Geschwindigkeit
        float eff = moveSpeed * speedFactor;
        if (jumpBefore && flatDist < 2f) eff *= lavaApproachFactor;
        if (inJump) eff *= 0.70f;

        Vector3 newPos = pos + dir * eff * Time.fixedDeltaTime;
        rb.MovePosition(new Vector3(newPos.x, pos.y, newPos.z));
    }

    // ── Timing-Ticks ─────────────────────────────────────────────────────────

    private void TickTimers()
    {
        if (hesitateTimer > 0f) { hesitateTimer -= Time.fixedDeltaTime; return; }

        speedRerollTimer -= Time.fixedDeltaTime;
        if (speedRerollTimer <= 0f)
        {
            speedFactor      = Mathf.Clamp(1f + Random.Range(-speedVariance, speedVariance * 0.4f), 0.65f, 1.15f);
            speedRerollTimer = Random.Range(0.8f, 2.2f);
        }

        if (Random.value < hesitationChance * Time.fixedDeltaTime)
            hesitateTimer = hesitationDuration * Random.Range(0.5f, 1.5f);
    }

    // ── Ground-Check ─────────────────────────────────────────────────────────

    private void GroundCheck()
    {
        float rayLen    = 0.5f + groundCheckDistance;
        bool  wasAir    = !isGrounded;
        if (Physics.Raycast(transform.position, Vector3.down, out RaycastHit hit, rayLen))
            isGrounded = hit.collider.CompareTag("Floor")
                      || hit.collider.CompareTag("Bridge")
                      || hit.collider.CompareTag("Platform");
        else
            isGrounded = false;

        if (wasAir && isGrounded) inJump = false;
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

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

    // ── BFS-Pathfinding ───────────────────────────────────────────────────────

    public void ComputePath()
    {
        path.Clear();
        wpIdx     = 0;
        inJump    = false;
        exploring = false;

        if (mapGenerator == null) return;
        MapData md = mapGenerator.CurrentMapData;
        if (md == null) return;

        Vector3    origin = mapGenerator.MapOrigin;
        float      cs     = mapGenerator.cellSize;
        Vector2Int start  = WorldToCell(transform.position, origin, cs);
        Vector2Int goal   = WorldToCell(mapGenerator.GetGoalPosition(), origin, cs);

        List<Vector2Int> gridPath = BFS(md, start, goal);
        if (gridPath == null || gridPath.Count < 2)
        {
            path.Add(new WP { pos = mapGenerator.GetGoalPosition(), jumpBefore = false });
            return;
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

    // ── BFS ──────────────────────────────────────────────────────────────────

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

    private bool IsWalkable(MapData md, Vector2Int p)
    {
        switch (md.GetCell(p.x, p.y))
        {
            case CellType.Floor: case CellType.SpawnPoint:
            case CellType.Goal:  case CellType.Platform:
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

    // ── Hilfsmethoden ────────────────────────────────────────────────────────

    private static bool InBounds(MapData md, Vector2Int p) =>
        p.x >= 0 && p.x < md.width && p.y >= 0 && p.y < md.height;

    private static Vector2Int WorldToCell(Vector3 w, Vector3 origin, float cs) =>
        new Vector2Int(Mathf.RoundToInt((w.x - origin.x) / cs),
                       Mathf.RoundToInt((w.z - origin.z) / cs));

    private static float   Flat2D(Vector3 a, Vector3 b) =>
        new Vector2(a.x - b.x, a.z - b.z).magnitude;

    private static Vector3 FlatDir(Vector3 from, Vector3 to)
    {
        var d = new Vector3(to.x - from.x, 0f, to.z - from.z);
        return d.sqrMagnitude > 0.0001f ? d.normalized : Vector3.zero;
    }

    // ── Öffentliche API (gleiche Schnittstelle wie LabyrinthAgent) ────────────

    public void FreezeMovement()
    {
        frozen      = true;
        rb.velocity = Vector3.zero;
    }

    public void UnfreezeMovement()
    {
        frozen        = false;
        hesitateTimer = Random.Range(0f, 0.3f);
        ComputePath();
    }

    public void RespawnAtStart()
    {
        if (mapGenerator != null)
        {
            transform.position = mapGenerator.GetSpawnPosition();
            transform.rotation = Quaternion.identity;
        }
        rb.velocity        = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        inJump             = false;
        exploring          = false;
        hesitateTimer      = 0f;
        path.Clear();
        wpIdx = 0;
        StartCoroutine(DelayedPath());
    }

    private IEnumerator DelayedPath()
    {
        yield return new WaitForSeconds(respawnThinkTime);
        if (!frozen) ComputePath();
    }

    public void RefreshGoal()
    {
        if (!frozen) ComputePath();
    }
}
