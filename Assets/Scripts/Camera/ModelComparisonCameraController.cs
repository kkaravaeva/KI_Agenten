using UnityEngine;
using Unity.MLAgents.Policies;

public class ModelComparisonCameraController : MonoBehaviour
{
    int _current = 0;
    float _lerpSpeed = 4f;

    Vector3    _targetPos;
    Quaternion _targetRot;

    // Pro Architektur: ein Referenz-Agent (fuer POV) und dessen MapGenerator (fuer Top-Down)
    static readonly string[] BehaviorNames = { "LSTM_Navigator", "Transformer_Navigator", "MLP_Navigator" };
    readonly Transform[]    _povAgents   = new Transform[3];
    readonly MapGenerator[] _areaMapGens = new MapGenerator[3];

    Camera _cam;

    static readonly Vector3 OverviewPos = new Vector3(80f, 150f, -10f);
    static readonly Vector3 OverviewRot = new Vector3(62f, 0f, 0f);

    static readonly string[] Labels = new string[]
    {
        "Uebersicht",
        "Top-Down LSTM",
        "Top-Down Transformer",
        "Top-Down MLP",
        "POV LSTM",
        "POV Transformer",
        "POV MLP",
    };

    void Start()
    {
        _cam = GetComponent<Camera>();
        FindReferences();
        SetPreset(0, true);
    }

    // Ersten Agenten je Architektur suchen; dessen Area liefert den MapGenerator.
    void FindReferences()
    {
        var agents = FindObjectsOfType<LabyrinthAgent>(true);
        foreach (var agent in agents)
        {
            var bp = agent.GetComponent<BehaviorParameters>();
            if (bp == null) continue;
            for (int i = 0; i < BehaviorNames.Length; i++)
            {
                if (bp.BehaviorName != BehaviorNames[i] || _povAgents[i] != null) continue;
                _povAgents[i] = agent.transform;
                var areaRoot = agent.transform.parent != null ? agent.transform.parent : agent.transform;
                _areaMapGens[i] = areaRoot.GetComponentInChildren<MapGenerator>(true);
            }
        }
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha0) || Input.GetKeyDown(KeyCode.Tab)) SetPreset(0);
        if (Input.GetKeyDown(KeyCode.Alpha1)) SetPreset(1);
        if (Input.GetKeyDown(KeyCode.Alpha2)) SetPreset(2);
        if (Input.GetKeyDown(KeyCode.Alpha3)) SetPreset(3);
        if (Input.GetKeyDown(KeyCode.Alpha4)) SetPreset(4);
        if (Input.GetKeyDown(KeyCode.Alpha5)) SetPreset(5);
        if (Input.GetKeyDown(KeyCode.Alpha6)) SetPreset(6);
    }

    void LateUpdate()
    {
        if (_current == 0)
        {
            _targetPos = OverviewPos;
            _targetRot = Quaternion.Euler(OverviewRot);
            SmoothMove();
        }
        else if (_current <= 3)
        {
            UpdateTopDown(_current - 1);
            SmoothMove();
        }
        else
        {
            UpdatePov(_current - 4); // POV folgt hart (ohne Lerp), sonst "schwimmt" der Blick
        }
    }

    // Kamera senkrecht ueber der Map, Hoehe so gewaehlt, dass die ganze Map ins Bild passt.
    void UpdateTopDown(int idx)
    {
        var gen = _areaMapGens[idx];
        if (gen == null || !gen.HasMapData) return;

        var data = gen.CurrentMapData;
        float cell = gen.cellSize;
        float w = data.width  * cell;
        float h = data.height * cell;

        Vector3 center = gen.MapOrigin + new Vector3((data.width - 1) * cell * 0.5f, 0f, (data.height - 1) * cell * 0.5f);

        // Benoetigte Hoehe aus vertikalem FOV (fuer Map-"Hoehe" = Z) und horizontalem FOV (fuer Breite = X)
        float fovV = _cam != null ? _cam.fieldOfView : 60f;
        float aspect = _cam != null ? _cam.aspect : 16f / 9f;
        float tanV = Mathf.Tan(fovV * 0.5f * Mathf.Deg2Rad);
        float tanH = tanV * aspect;
        float needed = Mathf.Max(h * 0.5f / tanV, w * 0.5f / tanH) * 1.15f; // 15% Rand

        _targetPos = center + Vector3.up * needed;
        _targetRot = Quaternion.Euler(90f, 0f, 0f); // senkrecht nach unten, Norden oben
    }

    // Ego-Perspektive: Kamera am Kopf des Agenten, blickt in seine Laufrichtung.
    void UpdatePov(int idx)
    {
        var agent = _povAgents[idx];
        if (agent == null) return;

        transform.position = agent.position + Vector3.up * 0.45f + agent.forward * 0.15f;
        transform.rotation = agent.rotation * Quaternion.Euler(10f, 0f, 0f); // leicht nach unten geneigt
        _targetPos = transform.position;
        _targetRot = transform.rotation;
    }

    void SmoothMove()
    {
        transform.position = Vector3.Lerp(transform.position, _targetPos, Time.deltaTime * _lerpSpeed);
        transform.rotation = Quaternion.Slerp(transform.rotation, _targetRot, Time.deltaTime * _lerpSpeed);
    }

    void SetPreset(int index, bool instant = false)
    {
        _current = index;
        if (instant)
        {
            _targetPos = OverviewPos;
            _targetRot = Quaternion.Euler(OverviewRot);
            transform.position = _targetPos;
            transform.rotation = _targetRot;
        }
    }

    void OnGUI()
    {
        GUI.Box(new Rect(Screen.width - 235f, 10f, 225f, 165f), "");
        GUI.Label(new Rect(Screen.width - 230f, 12f,  215f, 20f), "Ansicht: " + Labels[_current]);
        GUI.Label(new Rect(Screen.width - 230f, 34f,  215f, 20f), "[0/Tab] Uebersicht");
        GUI.Label(new Rect(Screen.width - 230f, 52f,  215f, 20f), "[1] Top-Down LSTM");
        GUI.Label(new Rect(Screen.width - 230f, 70f,  215f, 20f), "[2] Top-Down Transformer");
        GUI.Label(new Rect(Screen.width - 230f, 88f,  215f, 20f), "[3] Top-Down MLP");
        GUI.Label(new Rect(Screen.width - 230f, 106f, 215f, 20f), "[4] POV LSTM");
        GUI.Label(new Rect(Screen.width - 230f, 124f, 215f, 20f), "[5] POV Transformer");
        GUI.Label(new Rect(Screen.width - 230f, 142f, 215f, 20f), "[6] POV MLP");
    }
}
