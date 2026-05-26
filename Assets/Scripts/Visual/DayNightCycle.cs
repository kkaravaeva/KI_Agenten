using UnityEngine;
using UnityEngine.Rendering;

/// Real-time day/night cycle.
/// Attach to any persistent GameObject (e.g. the scene manager).
/// [P] pauses time, [N] jumps to night, [D] jumps to day.
public class DayNightCycle : MonoBehaviour
{
    [Header("Timing")]
    [Range(0f, 1f)] public float timeOfDay     = 0.30f; // 0=midnight · 0.25=sunrise · 0.5=noon
    public float dayDurationSeconds             = 240f;
    public bool  paused                         = false;

    [Header("Sun")]
    public Light sun;
    [Range(-180f, 180f)] public float sunAzimuth = -40f;

    // ── Runtime state ──────────────────────────────────────────────────────────
    Light     _moon;
    Light[]   _torchLights;
    Material  _skyInstance;   // cloned so we don't dirty the shared asset
    bool      _ready;

    // ── Lifecycle ──────────────────────────────────────────────────────────────

    void Start()
    {
        // Auto-find directional sun
        if (sun == null)
            foreach (var l in FindObjectsOfType<Light>())
                if (l.type == LightType.Directional && l.intensity > 0.3f) { sun = l; break; }

        // Create moon light
        var moonGO = new GameObject("Moon");
        moonGO.transform.SetParent(transform);
        _moon               = moonGO.AddComponent<Light>();
        _moon.type          = LightType.Directional;
        _moon.color         = new Color(0.62f, 0.72f, 0.90f);
        _moon.intensity     = 0f;
        _moon.shadows       = LightShadows.None;
        _moon.transform.rotation = Quaternion.Euler(55f, sunAzimuth + 170f, 0f);

        // Clone skybox material so we can change exposure per-frame without dirtying the asset
        if (RenderSettings.skybox != null)
            _skyInstance = new Material(RenderSettings.skybox);
        if (_skyInstance != null)
            RenderSettings.skybox = _skyInstance;

        _torchLights = CollectTorchLights();
        _ready = true;
        Apply();
    }

    void Update()
    {
        if (!_ready) return;

        if (Input.GetKeyDown(KeyCode.P)) paused = !paused;
        if (Input.GetKeyDown(KeyCode.N)) timeOfDay = 0.02f;  // jump to night
        if (Input.GetKeyDown(KeyCode.D)) timeOfDay = 0.50f;  // jump to noon

        if (!paused)
            timeOfDay = (timeOfDay + Time.deltaTime / dayDurationSeconds) % 1f;

        Apply();
    }

    // ── Core update ────────────────────────────────────────────────────────────

    void Apply()
    {
        // elevation: +1 at noon, 0 at sunrise/sunset, -1 at midnight
        float elevation = Mathf.Sin(timeOfDay * Mathf.PI * 2f - Mathf.PI * 0.5f);

        ApplySun(elevation);
        ApplyMoon(elevation);
        ApplyAmbient(elevation);
        ApplyFog(elevation);
        ApplySky(elevation);
        ApplyTorches(elevation);
    }

    void ApplySun(float elev)
    {
        if (sun == null) return;
        // Rotate sun: -90° at midnight → 90° at noon → 270° at next midnight
        sun.transform.rotation = Quaternion.Euler(timeOfDay * 360f - 90f, sunAzimuth, 0f);

        if (elev > 0.18f)
        {
            // Full day — warm white to bright gold
            float t = Mathf.InverseLerp(0.18f, 1f, elev);
            sun.intensity = Mathf.Lerp(0.65f, 1.55f, t);
            sun.color     = Color.Lerp(new Color(1.00f, 0.72f, 0.36f), new Color(1.00f, 0.97f, 0.88f), t);
        }
        else if (elev > -0.18f)
        {
            // Dusk / dawn — deep orange
            float t = Mathf.InverseLerp(-0.18f, 0.18f, elev);
            sun.intensity = Mathf.Lerp(0.00f, 0.65f, t);
            sun.color     = Color.Lerp(new Color(0.85f, 0.30f, 0.05f), new Color(1.00f, 0.72f, 0.36f), t);
        }
        else
        {
            sun.intensity = 0f;
        }
    }

    void ApplyMoon(float elev)
    {
        if (_moon == null) return;
        // Moon rises when sun sets
        float moonElev = Mathf.Sin((timeOfDay + 0.5f) % 1f * Mathf.PI * 2f - Mathf.PI * 0.5f);
        _moon.intensity = Mathf.Clamp01(-elev * 3f) * Mathf.Clamp01(moonElev * 5f) * 0.18f;
        _moon.transform.rotation = Quaternion.Euler(
            (timeOfDay + 0.5f) % 1f * 360f - 90f, sunAzimuth + 170f, 0f);
    }

    void ApplyAmbient(float elev)
    {
        // Sky-based ambient during day; flat near-black at night
        float t = Mathf.Clamp01((elev + 0.15f) / 0.4f);
        RenderSettings.ambientMode      = AmbientMode.Trilight;
        RenderSettings.ambientSkyColor  = Color.Lerp(
            new Color(0.02f, 0.03f, 0.06f), new Color(0.50f, 0.65f, 0.90f), t);
        RenderSettings.ambientEquatorColor = Color.Lerp(
            new Color(0.01f, 0.02f, 0.04f), new Color(0.42f, 0.52f, 0.44f), t);
        RenderSettings.ambientGroundColor = Color.Lerp(
            new Color(0.00f, 0.01f, 0.02f), new Color(0.18f, 0.15f, 0.12f), t);
    }

    void ApplyFog(float elev)
    {
        float t = Mathf.Clamp01((elev + 0.2f) / 0.5f);
        RenderSettings.fogColor   = Color.Lerp(new Color(0.04f, 0.05f, 0.12f),
                                               new Color(0.58f, 0.54f, 0.46f), t);
        RenderSettings.fogDensity = Mathf.Lerp(0.014f, 0.005f, t);
    }

    void ApplySky(float elev)
    {
        if (_skyInstance == null) return;
        float exp = Mathf.Lerp(0.015f, 1.20f, Mathf.Clamp01((elev + 0.15f) / 0.45f));
        _skyInstance.SetFloat("_Exposure", exp);
        DynamicGI.UpdateEnvironment();
    }

    void ApplyTorches(float elev)
    {
        // Torches are brighter at night
        float night = 1f - Mathf.Clamp01((elev + 0.05f) / 0.25f);
        float baseI = 2.2f + night * 3.5f;
        float time  = Time.time;
        foreach (var l in _torchLights)
        {
            if (l == null) continue;
            // Subtle flicker
            float flicker = 1f + Mathf.Sin(time * 9.7f + l.GetInstanceID() * 0.37f) * 0.11f
                               + Mathf.Sin(time * 4.2f + l.GetInstanceID() * 0.91f) * 0.07f;
            l.intensity = baseI * flicker;
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    static Light[] CollectTorchLights()
    {
        var list = new System.Collections.Generic.List<Light>();
        foreach (var l in FindObjectsOfType<Light>())
            if (l.type == LightType.Point && l.gameObject.name == "TorchLight")
                list.Add(l);
        return list.ToArray();
    }

    void OnGUI()
    {
        float h   = timeOfDay * 24f;
        int   hr  = (int)h % 24;
        int   min = (int)((h - (int)h) * 60f);
        float elev = Mathf.Sin(timeOfDay * Mathf.PI * 2f - Mathf.PI * 0.5f);
        string phase = elev >  0.20f ? "Tag" :
                       elev >  0.00f ? "Abenddämmerung" :
                       elev > -0.20f ? "Nacht (Dämmerung)" : "Nacht";
        string pauseHint = paused ? " [PAUSE]" : "";
        GUI.Label(new Rect(10, 35, 280, 22), $"{hr:D2}:{min:D2}  {phase}{pauseHint}  [P/N/D]");
    }
}
