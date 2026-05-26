using UnityEngine;

/// Attached dynamically by MapFXSpawner to the goal object.
/// Adds pulsing glow light, gold sparkle particles, and a bobbing animation.
[DisallowMultipleComponent]
public class GoalBeacon : MonoBehaviour
{
    static readonly int EmissionColor = Shader.PropertyToID("_EmissionColor");

    Renderer             _rend;
    MaterialPropertyBlock _mpb;
    Light                _light;
    Vector3              _basePos;
    float                _timeOffset;

    void Awake()
    {
        _rend       = GetComponent<Renderer>();
        _mpb        = new MaterialPropertyBlock();
        _timeOffset = Random.Range(0f, Mathf.PI * 2f);
        _basePos    = transform.localPosition;
        SetupLight();
        SetupParticles();
    }

    void OnEnable()
    {
        _basePos = transform.localPosition;
        if (_light) _light.enabled = true;
    }

    void OnDisable()
    {
        if (_light) _light.enabled = false;
    }

    void Update()
    {
        float t     = Time.time + _timeOffset;
        float pulse = 0.65f + 0.35f * Mathf.Sin(t * 2.1f);
        float bob   = Mathf.Sin(t * 1.4f) * 0.12f;

        // Bobbing
        transform.localPosition = _basePos + Vector3.up * bob;
        transform.localRotation = Quaternion.Euler(0f, t * 45f, 0f);

        // Emission pulse
        if (_rend != null)
        {
            _rend.GetPropertyBlock(_mpb);
            _mpb.SetColor(EmissionColor, new Color(0.2f * pulse, 2.5f * pulse, 0.4f * pulse));
            _rend.SetPropertyBlock(_mpb);
        }

        if (_light)
        {
            _light.intensity = 3f * pulse;
            _light.color     = new Color(0.15f + 0.05f * pulse, 1f, 0.3f + 0.1f * pulse);
        }
    }

    void SetupLight()
    {
        var lg = new GameObject("GoalGlow");
        lg.transform.SetParent(transform);
        lg.transform.localPosition = new Vector3(0f, 0.5f, 0f);
        _light = lg.AddComponent<Light>();
        _light.type      = LightType.Point;
        _light.color     = new Color(0.2f, 1f, 0.35f);
        _light.intensity = 3f;
        _light.range     = 5f;
        _light.shadows   = LightShadows.None;
    }

    void SetupParticles()
    {
        var psGO = new GameObject("GoalSparkles");
        psGO.transform.SetParent(transform);
        psGO.transform.localPosition = new Vector3(0f, 0.1f, 0f);

        var ps   = psGO.AddComponent<ParticleSystem>();
        var main = ps.main;
        main.startLifetime   = new ParticleSystem.MinMaxCurve(1.0f, 2.0f);
        main.startSpeed      = new ParticleSystem.MinMaxCurve(0.3f, 1.2f);
        main.startSize       = new ParticleSystem.MinMaxCurve(0.03f, 0.10f);
        main.startColor      = new ParticleSystem.MinMaxGradient(
            new Color(0.3f, 1f, 0.4f, 1f),
            new Color(0.8f, 1f, 0.2f, 1f));
        main.simulationSpace = ParticleSystemSimulationSpace.World;
        main.maxParticles    = 60;
        main.loop            = true;
        main.gravityModifier = -0.15f;

        var em = ps.emission;
        em.rateOverTime = 20f;

        var sh = ps.shape;
        sh.enabled   = true;
        sh.shapeType = ParticleSystemShapeType.Sphere;
        sh.radius    = 0.35f;

        var col = ps.colorOverLifetime;
        col.enabled = true;
        var g = new Gradient();
        g.SetKeys(
            new[] {
                new GradientColorKey(new Color(0.5f, 1f, 0.3f), 0f),
                new GradientColorKey(new Color(1f,   1f, 0.5f), 0.4f),
                new GradientColorKey(new Color(0.2f, 0.8f, 0.3f), 1f)
            },
            new[] {
                new GradientAlphaKey(1f,   0f),
                new GradientAlphaKey(0.8f, 0.5f),
                new GradientAlphaKey(0f,   1f)
            });
        col.color = g;

        var sz = ps.sizeOverLifetime;
        sz.enabled = true;
        sz.size    = new ParticleSystem.MinMaxCurve(1f,
            AnimationCurve.EaseInOut(0f, 1f, 1f, 0f));

        var rend = psGO.GetComponent<ParticleSystemRenderer>();
        rend.renderMode = ParticleSystemRenderMode.Billboard;
        var mat = new Material(Shader.Find("Particles/Standard Unlit"));
        if (mat.shader.name == "Hidden/InternalErrorShader")
            mat = new Material(Shader.Find("Legacy Shaders/Particles/Additive"));
        mat.SetColor("_Color", new Color(0.5f, 1f, 0.3f, 1f));
        rend.sharedMaterial = mat;
        rend.sortingOrder   = 1;
    }
}
