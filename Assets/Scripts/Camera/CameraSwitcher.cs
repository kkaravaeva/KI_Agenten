using UnityEngine;

/// Cycles through Drone / Ego / Front cameras via Tab.
/// Ego mode: near clip 0.01, camera at head center, agent head hidden.
/// Front mode: FrontFollowCamera tracks from in front of the agent's face.
public class CameraSwitcher : MonoBehaviour
{
    public enum Mode { Drone, Ego, Front }

    [Header("Cameras")]
    public Camera egoCamera;
    public Camera droneCamera;
    public Camera frontCamera;
    public Camera thirdPersonCamera;

    [Header("Settings")]
    public KeyCode switchKey = KeyCode.Tab;
    public Mode    startMode = Mode.Drone;

    Mode _current;

    void Start()
    {
        // Auto-wire front camera target to the agent in the scene
        if (frontCamera != null)
        {
            var fc = frontCamera.GetComponent<FrontFollowCamera>();
            if (fc != null && fc.target == null)
            {
                var agent = Object.FindObjectOfType<LabyrinthAgent>();
                if (agent != null) fc.SetTarget(agent.transform);
            }
        }

        // Attach EgoClipGuard to ego camera if not already present
        if (egoCamera != null && egoCamera.GetComponent<EgoClipGuard>() == null)
            egoCamera.gameObject.AddComponent<EgoClipGuard>();

        SetMode(startMode);
    }

    void Update()
    {
        if (Input.GetKeyDown(switchKey))
        {
            Mode next = _current switch
            {
                Mode.Drone => Mode.Ego,
                Mode.Ego   => Mode.Front,
                _          => Mode.Drone
            };
            SetMode(next);
        }
    }

    void SetMode(Mode mode)
    {
        _current = mode;

        if (egoCamera        != null) egoCamera.enabled        = mode == Mode.Ego;
        if (droneCamera      != null) droneCamera.enabled      = mode == Mode.Drone;
        if (frontCamera      != null) frontCamera.enabled      = mode == Mode.Front;
        if (thirdPersonCamera!= null) thirdPersonCamera.enabled = false;

        // Ego mode: pull camera into safe head position, tiny near clip
        if (mode == Mode.Ego && egoCamera != null)
        {
            egoCamera.nearClipPlane            = 0.01f;
            egoCamera.transform.localPosition  = new Vector3(0f, 0.42f, 0f);
            egoCamera.transform.localRotation  = Quaternion.identity;
        }

        // Show/hide agent head — never want to see your own head in first-person
        SetAgentHeadVisible(mode != Mode.Ego);

        Debug.Log($"[Kamera] {mode}  (Tab = nächste)");
    }

    // Wire the FrontFollowCamera target once we know the agent.
    public void SetFrontTarget(Transform agentRoot)
    {
        if (frontCamera == null) return;
        var fc = frontCamera.GetComponent<FrontFollowCamera>();
        if (fc != null) fc.SetTarget(agentRoot);
    }

    static void SetAgentHeadVisible(bool visible)
    {
        var v = Object.FindObjectOfType<HumanAgentVisual>();
        if (v != null) v.SetHeadVisible(visible);
    }

    void OnGUI()
    {
        string label = _current switch
        {
            Mode.Drone => "Drohne (oben)",
            Mode.Ego   => "Ego (POV)",
            Mode.Front => "Front (Gesicht)",
            _          => _current.ToString()
        };
        GUI.Label(new Rect(10, 10, 240, 25), $"Kamera: {label}  [Tab]");
    }
}
