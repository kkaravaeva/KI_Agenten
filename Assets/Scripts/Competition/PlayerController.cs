using UnityEngine;

/// <summary>
/// Steuert den menschlichen Spieler im Wettkampf-Modus.
/// Unterstützt Controller (linker Stick + A-Taste) und Tastatur (Pfeiltasten + Enter).
/// Gleiche Physik-Parameter wie LabyrinthAgent.
/// </summary>
[RequireComponent(typeof(Rigidbody))]
public class PlayerController : MonoBehaviour
{
    // ── Bewegungsparameter (identisch zu LabyrinthAgent) ─────────────────────

    [Header("Bewegung")]
    public float moveSpeed         = 5f;
    public float turnSpeed         = 180f;
    public float jumpForce         = 9.0f;
    public float groundCheckDistance = 0.15f;
    public float maxUpwardVelocity = 7f;

    [Header("Referenzen")]
    public MapGenerator mapGenerator;

    // ── Events für CompetitionManager ────────────────────────────────────────

    /// <summary>Wird ausgeloest, wenn der Spieler das Ziel betritt.</summary>
    public System.Action onGoalReached;
    /// <summary>Wird ausgeloest bei Tod (Respawn erfolgt automatisch).</summary>
    public System.Action onPlayerDied;

    // ── Interne State ─────────────────────────────────────────────────────────

    private Rigidbody  rb;
    private bool       isGrounded;
    private bool       movementFrozen;

    // Spawn-Referenz für Respawn
    private Vector3    spawnPosition;
    private Quaternion spawnRotation = Quaternion.identity;

    // Jump-Input muss in Update abgefragt werden (GetButtonDown nur 1 Frame)
    private bool jumpQueued;

    // ── Lifecycle ────────────────────────────────────────────────────────────

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
        rb.constraints = RigidbodyConstraints.FreezeRotation;
    }

    private void Update()
    {
        // Jump in Update abfragen, damit kein Frame verloren geht
        if (!movementFrozen && (Input.GetButtonDown("Jump") || Input.GetKeyDown(KeyCode.Return)
                                || Input.GetKeyDown(KeyCode.RightControl)))
        {
            jumpQueued = true;
        }
    }

    private void FixedUpdate()
    {
        GroundCheck();

        // Maximale Aufwärts-Geschwindigkeit begrenzen (kein Durchfliegen)
        if (rb.velocity.y > maxUpwardVelocity)
            rb.velocity = new Vector3(rb.velocity.x, maxUpwardVelocity, rb.velocity.z);

        if (!movementFrozen)
            ProcessMovement();
    }

    // ── Bewegung ─────────────────────────────────────────────────────────────

    private void ProcessMovement()
    {
        // ── Drehen (linker Stick X oder Pfeiltasten links/rechts) ────────────
        // Unity's "Horizontal"-Achse: A/D + Pfeiltasten + Controller Left Stick X
        float horizontal = Input.GetAxisRaw("Horizontal");
        if (Mathf.Abs(horizontal) > 0.1f)
        {
            float turnAmount = horizontal * turnSpeed * Time.fixedDeltaTime;
            rb.MoveRotation(rb.rotation * Quaternion.Euler(0f, turnAmount, 0f));
        }

        // ── Vorwärts / Rückwärts (linker Stick Y oder Pfeiltasten) ──────────
        // Unity's "Vertical"-Achse: W/S + Pfeiltasten + Controller Left Stick Y
        float vertical = Input.GetAxisRaw("Vertical");
        if (Mathf.Abs(vertical) > 0.1f)
        {
            Vector3 direction = vertical > 0f ? transform.forward : -transform.forward;
            rb.MovePosition(transform.position + direction * moveSpeed * Time.fixedDeltaTime);
        }

        // ── Sprung ───────────────────────────────────────────────────────────
        if (jumpQueued && isGrounded)
        {
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
            isGrounded = false;
        }
        jumpQueued = false;
    }

    // ── Boden-Check (identisch zu LabyrinthAgent) ────────────────────────────

    private void GroundCheck()
    {
        float rayLength = 0.5f + groundCheckDistance;
        RaycastHit hit;
        if (Physics.Raycast(transform.position, Vector3.down, out hit, rayLength))
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

    // ── Trigger-Events ───────────────────────────────────────────────────────

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
            onPlayerDied?.Invoke();
        }
    }

    // ── Öffentliche API ───────────────────────────────────────────────────────

    /// <summary>Spawn-Position setzen (muss vor dem ersten RespawnAtStart aufgerufen werden).</summary>
    public void SetSpawnPoint(Vector3 position, Quaternion rotation)
    {
        spawnPosition = position;
        spawnRotation = rotation;
    }

    /// <summary>Spieler an Spawn zurücksetzen (kein Respawn-Delay).</summary>
    public void RespawnAtStart()
    {
        transform.position = spawnPosition;
        transform.rotation = spawnRotation;
        rb.velocity        = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        jumpQueued         = false;
    }

    public void FreezeMovement()
    {
        movementFrozen = true;
        jumpQueued     = false;
    }

    public void UnfreezeMovement()
    {
        movementFrozen = false;
        jumpQueued     = false;
    }

    public bool IsGrounded => isGrounded;
}
