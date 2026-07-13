using UnityEngine;

/// Lässt das Ziel mystisch pulsierend leuchten (weiche Emission-Welle) — rein
/// visuell über einen MaterialPropertyBlock, ohne das geteilte Material oder die
/// Kollision/Ziel-Erkennung zu verändern.
[RequireComponent(typeof(Renderer))]
public class MysticGlow : MonoBehaviour
{
    [Tooltip("Grund-Emissionsfarbe (HDR) — mystisches Grün-Cyan.")]
    public Color baseEmission = new Color(0.20f, 3.5f, 0.70f);
    [Tooltip("Pulsstärke: ±Anteil der Grundhelligkeit.")]
    [Range(0f, 0.9f)] public float pulseAmplitude = 0.40f;
    [Tooltip("Pulsgeschwindigkeit (Wellen pro Sekunde ~ speed/2π).")]
    public float pulseSpeed = 2.2f;

    Renderer _r;
    MaterialPropertyBlock _mpb;
    static readonly int EmissionId = Shader.PropertyToID("_EmissionColor");

    void Awake()
    {
        _r = GetComponent<Renderer>();
        _mpb = new MaterialPropertyBlock();
    }

    void Update()
    {
        // Zwei überlagerte Sinuswellen → lebendigeres, "magisches" Flackern.
        float k = 1f + pulseAmplitude * (0.7f * Mathf.Sin(Time.time * pulseSpeed)
                                       + 0.3f * Mathf.Sin(Time.time * pulseSpeed * 2.7f));
        _r.GetPropertyBlock(_mpb);
        _mpb.SetColor(EmissionId, baseEmission * Mathf.Max(0f, k));
        _r.SetPropertyBlock(_mpb);
    }
}
