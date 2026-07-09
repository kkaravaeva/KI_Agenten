using UnityEngine;

/// Attach to the Agent root. Reads movement state and drives AudioManager.
[RequireComponent(typeof(Rigidbody))]
public class AgentAudio : MonoBehaviour
{
    Rigidbody _rb;
    bool      _grounded;
    bool      _wasGrounded;
    float     _lastStepTime;
    bool      _lavaAmbienceStarted;

    const float StepMinSpeed  = 1.5f;
    const float StepInterval  = 0.30f;
    const float JumpMinVelY   = 1.8f;   // minimum upward velocity to trigger jump sound
    const float GroundRayLen  = 0.72f;

    void Awake()
    {
        _rb = GetComponent<Rigidbody>();
    }

    void FixedUpdate()
    {
        if (AudioManager.Instance == null) return;

        _wasGrounded = _grounded;
        _grounded    = Physics.Raycast(transform.position, Vector3.down, GroundRayLen);

        // Jump: was grounded last frame, now airborne, moving upward
        if (_wasGrounded && !_grounded && _rb.linearVelocity.y > JumpMinVelY)
            AudioManager.Instance.PlayJump();

        // Footstep: grounded and moving fast enough
        if (_grounded)
        {
            float horizSpeed = new Vector3(_rb.linearVelocity.x, 0f, _rb.linearVelocity.z).magnitude;
            if (horizSpeed > StepMinSpeed && Time.time - _lastStepTime > StepInterval)
            {
                _lastStepTime = Time.time;
                AudioManager.Instance.PlayFootstep(onLava: false);
            }
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (AudioManager.Instance == null) return;

        if (other.CompareTag("Goal"))
        {
            AudioManager.Instance.PlayGoalReached();
            AudioManager.Instance.StopLavaAmbience();
            _lavaAmbienceStarted = false;
        }
        else if (other.CompareTag("Lava"))
        {
            AudioManager.Instance.PlayDeath();
        }
        else if (other.CompareTag("KillZone"))
        {
            AudioManager.Instance.PlayDeath();
        }
    }

    public void NotifyLavaPresent(bool present)
    {
        if (AudioManager.Instance == null) return;
        if (present && !_lavaAmbienceStarted)
        {
            AudioManager.Instance.StartLavaAmbience();
            _lavaAmbienceStarted = true;
        }
        else if (!present)
        {
            AudioManager.Instance.StopLavaAmbience();
            _lavaAmbienceStarted = false;
        }
    }
}
