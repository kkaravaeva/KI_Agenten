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
    EgoClipGuard _clipGuard;

    // Animierter Kameraflug beim Ansichtswechsel
    public float transitionDuration = 1.3f;
    bool       _transitioning;
    float      _transTime;
    Vector3    _transStartPos;
    Quaternion _transStartRot;

    static readonly Vector3 OverviewPos = new Vector3(80f, 150f, -10f);
    static readonly Vector3 OverviewRot = new Vector3(62f, 0f, 0f);

    static readonly string[] Labels = new string[]
    {
        "Übersicht",
        "Top-Down LSTM",
        "Top-Down Transformer",
        "Top-Down MLP",
        "Nah-Oben LSTM",
        "Nah-Oben Transformer",
        "Nah-Oben MLP",
        "Verfolger LSTM",
        "Verfolger Transformer",
        "Verfolger MLP",
    };

    void Start()
    {
        _cam = GetComponent<Camera>();
        _clipGuard = GetComponent<EgoClipGuard>();
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
        if (Input.GetKeyDown(KeyCode.Alpha7)) SetPreset(7);
        if (Input.GetKeyDown(KeyCode.Alpha8)) SetPreset(8);
        if (Input.GetKeyDown(KeyCode.Alpha9)) SetPreset(9);
    }

    void LateUpdate()
    {
        ComputeTargetPose();

        // Keine Ego-POV mehr → Schwarzblende (EgoClipGuard) generell aus.
        if (_clipGuard != null) _clipGuard.suppressed = true;

        if (_transitioning)
        {
            _transTime += Time.deltaTime;
            float t = transitionDuration > 0f ? Mathf.Clamp01(_transTime / transitionDuration) : 1f;
            float e = Mathf.SmoothStep(0f, 1f, t);   // sanftes Ein-/Ausblenden der Bewegung
            transform.position = Vector3.Lerp(_transStartPos, _targetPos, e);
            transform.rotation = Quaternion.Slerp(_transStartRot, _targetRot, e);
            if (t >= 1f) _transitioning = false;
        }
        else if (_current >= 4 && _current <= 6)
        {
            transform.position = _targetPos;   // POV: hart folgen, sonst "schwimmt" der Blick
            transform.rotation = _targetRot;
        }
        else
        {
            SmoothMove();                       // Übersicht/Top-Down/Verfolger: sanft nachführen
        }
    }

    // Zielpose der aktuellen Ansicht berechnen (ohne die Kamera direkt zu setzen).
    void ComputeTargetPose()
    {
        if (_current == 0)
        {
            _targetPos = OverviewPos;
            _targetRot = Quaternion.Euler(OverviewRot);
        }
        else if (_current <= 3)
        {
            UpdateTopDown(_current - 1);
        }
        else if (_current <= 6)
        {
            UpdateTopFollow(_current - 4);
        }
        else
        {
            UpdateThirdPerson(_current - 7);
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

    // Nah-Verfolgung von oben: Kamera senkrecht über dem Agenten aus mittlerer Höhe,
    // folgt ihm zentriert (zeigt Agent + nähere Umgebung — Ergänzung zur kompletten
    // Karten-Vogelperspektive der Top-Down-Ansicht).
    void UpdateTopFollow(int idx)
    {
        var agent = _povAgents[idx];
        if (agent == null) return;

        const float height = 12f;
        _targetPos = new Vector3(agent.position.x, agent.position.y + height, agent.position.z);
        _targetRot = Quaternion.Euler(90f, 0f, 0f); // senkrecht nach unten
    }

    // Verfolgerkamera (Third-Person): leicht schraeg oben HINTER dem Agenten, Blick auf ihn
    // (wie in Videospielen). Zieht bei einer Wand im Ruecken naeher heran, damit die Kamera
    // nicht in der Wand steckt.
    void UpdateThirdPerson(int idx)
    {
        var agent = _povAgents[idx];
        if (agent == null) return;

        Vector3 pivot = agent.position + Vector3.up * 0.9f;                // Schulterhoehe
        Vector3 dir   = (-agent.forward + Vector3.up * 0.5f).normalized;   // nach hinten-oben
        float   dist  = 3.4f;

        // Wand im Ruecken? Kamera davor stoppen (Ray etwas hinter dem Koerper starten).
        Vector3 rayStart = pivot - agent.forward * 0.4f;
        if (Physics.Raycast(rayStart, dir, out var hit, dist, ~0, QueryTriggerInteraction.Ignore))
            dist = Mathf.Max(0.9f, hit.distance - 0.25f);

        _targetPos = pivot + dir * dist;
        _targetRot = Quaternion.LookRotation((pivot - _targetPos).normalized, Vector3.up);
    }

    void SmoothMove()
    {
        transform.position = Vector3.Lerp(transform.position, _targetPos, Time.deltaTime * _lerpSpeed);
        transform.rotation = Quaternion.Slerp(transform.rotation, _targetRot, Time.deltaTime * _lerpSpeed);
    }

    void SetPreset(int index, bool instant = false)
    {
        bool changed = index != _current;
        _current = index;

        if (instant)
        {
            ComputeTargetPose();
            transform.position = _targetPos;
            transform.rotation = _targetRot;
            _transitioning = false;
            return;
        }

        // Ansichtswechsel → animierten Kameraflug vom aktuellen Standpunkt starten.
        if (changed)
        {
            _transitioning  = true;
            _transTime      = 0f;
            _transStartPos  = transform.position;
            _transStartRot  = transform.rotation;
        }
    }

    // Architektur-Index (0=LSTM, 1=Transformer, 2=MLP) für Top-Down/POV/Verfolger.
    int ArchIndex() => _current <= 3 ? _current - 1 : (_current <= 6 ? _current - 4 : _current - 7);

    // Architektur, auf die die aktuelle Ansicht zeigt (Übersicht = alle drei).
    string CurrentArchitecture()
    {
        if (_current == 0) return "Gesamtübersicht";
        return BehaviorNames[ArchIndex()].Replace("_Navigator", "");
    }

    // Farbe passend zu den 3D-Labels (LSTM blau, Transformer orange, MLP gruen).
    Color CurrentArchColor()
    {
        if (_current == 0) return Color.white;
        switch (ArchIndex())
        {
            case 0: return new Color(0.35f, 0.60f, 1.00f); // LSTM
            case 1: return new Color(1.00f, 0.65f, 0.15f); // Transformer
            case 2: return new Color(0.30f, 0.85f, 0.40f); // MLP
        }
        return Color.white;
    }

    // Kartentyp der aktuell gezeigten Map (aus dem MapGenerator des Areals).
    string CurrentMapCategory()
    {
        int idx = _current == 0 ? 0 : ArchIndex();
        var gen = _areaMapGens[idx];
        if (gen == null || !gen.HasMapData || gen.CurrentMapData == null) return "-";
        string n = gen.CurrentMapData.name;
        if (n.Contains("Giant"))  return "Giant (OOD - nie im Training)";
        if (n.Contains("Hard"))   return "Hard";
        if (n.Contains("Medium")) return "Medium";
        if (n.Contains("Easy"))   return "Easy";
        return n;
    }

    void OnGUI()
    {
        // ── Grosser Info-Balken (fuer Video): Architektur + Kartentyp + Perspektive ──
        string persp = _current == 0 ? "Übersicht"
                     : _current <= 3 ? "Top-Down (ganze Karte)"
                     : _current <= 6 ? "Nahsicht von oben"
                     : "Verfolgerkamera";

        GUI.color = new Color(0f, 0f, 0f, 0.6f);
        GUI.DrawTexture(new Rect(10f, 10f, 580f, 100f), Texture2D.whiteTexture);
        GUI.color = Color.white;

        var head = new GUIStyle(GUI.skin.label) { fontSize = 30, fontStyle = FontStyle.Bold };
        head.normal.textColor = CurrentArchColor();
        var sub = new GUIStyle(GUI.skin.label) { fontSize = 22 };
        sub.normal.textColor = new Color(0.92f, 0.92f, 0.92f);

        GUI.Label(new Rect(26f, 16f, 552f, 42f), "Architektur: " + CurrentArchitecture(), head);
        GUI.Label(new Rect(26f, 62f, 552f, 34f), $"Karte: {CurrentMapCategory()}    -    Ansicht: {persp}", sub);

        // ── Kompakte Tastenlegende (rechts) ──
        GUI.Box(new Rect(Screen.width - 235f, 10f, 225f, 240f), "");
        GUI.Label(new Rect(Screen.width - 230f, 12f,  215f, 20f), "Ansicht: " + Labels[_current]);
        GUI.Label(new Rect(Screen.width - 230f, 34f,  215f, 20f), "[0/Tab] Übersicht");
        GUI.Label(new Rect(Screen.width - 230f, 52f,  215f, 20f), "[1] Top-Down LSTM");
        GUI.Label(new Rect(Screen.width - 230f, 70f,  215f, 20f), "[2] Top-Down Transformer");
        GUI.Label(new Rect(Screen.width - 230f, 88f,  215f, 20f), "[3] Top-Down MLP");
        GUI.Label(new Rect(Screen.width - 230f, 106f, 215f, 20f), "[4] Nah-Oben LSTM");
        GUI.Label(new Rect(Screen.width - 230f, 124f, 215f, 20f), "[5] Nah-Oben Transformer");
        GUI.Label(new Rect(Screen.width - 230f, 142f, 215f, 20f), "[6] Nah-Oben MLP");
        GUI.Label(new Rect(Screen.width - 230f, 160f, 215f, 20f), "[7] Verfolger LSTM");
        GUI.Label(new Rect(Screen.width - 230f, 178f, 215f, 20f), "[8] Verfolger Transformer");
        GUI.Label(new Rect(Screen.width - 230f, 196f, 215f, 20f), "[9] Verfolger MLP");
    }
}
