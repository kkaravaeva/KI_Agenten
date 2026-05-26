using System;
using UnityEngine;
using Random = UnityEngine.Random;

/// Singleton audio manager with procedurally generated clips.
/// No external audio assets needed.
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    [Range(0f, 1f)] public float masterVolume   = 0.9f;
    [Range(0f, 1f)] public float sfxVolume      = 0.8f;
    [Range(0f, 1f)] public float ambienceVolume = 0.4f;

    const int SampleRate = 44100;

    AudioSource _sfxSource;
    AudioSource _ambienceSource;

    AudioClip _clipFootstep;
    AudioClip _clipFootstepLava;
    AudioClip _clipGoal;
    AudioClip _clipDeath;
    AudioClip _clipLavaLoop;
    AudioClip _clipWindLoop;
    AudioClip _clipJump;

    AudioSource _windSource;

    float _lastFootstepTime;
    const float FootstepCooldown = 0.28f;

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
        BuildClips();
        SetupSources();
    }

    void SetupSources()
    {
        _sfxSource = gameObject.AddComponent<AudioSource>();
        _sfxSource.spatialBlend = 0f;
        _sfxSource.volume       = sfxVolume * masterVolume;

        _ambienceSource = gameObject.AddComponent<AudioSource>();
        _ambienceSource.spatialBlend = 0f;
        _ambienceSource.loop         = true;
        _ambienceSource.volume       = ambienceVolume * masterVolume;

        _windSource = gameObject.AddComponent<AudioSource>();
        _windSource.spatialBlend = 0f;
        _windSource.loop         = true;
        _windSource.volume       = 0.18f * masterVolume;
        _windSource.clip         = _clipWindLoop;
        _windSource.Play();
    }

    // ── Public API ─────────────────────────────────────────────────────────────

    public void PlayFootstep(bool onLava = false)
    {
        if (Time.time - _lastFootstepTime < FootstepCooldown) return;
        _lastFootstepTime = Time.time;
        PlaySFX(onLava ? _clipFootstepLava : _clipFootstep, 0.55f, Random.Range(0.9f, 1.1f));
    }

    public void PlayJump()         => PlaySFX(_clipJump,  0.50f, Random.Range(0.92f, 1.08f));
    public void PlayGoalReached()  => PlaySFX(_clipGoal,  0.9f, 1f);
    public void PlayDeath()        => PlaySFX(_clipDeath, 0.8f, 1f);

    public void StartLavaAmbience()
    {
        if (_ambienceSource.isPlaying) return;
        _ambienceSource.clip    = _clipLavaLoop;
        _ambienceSource.volume  = ambienceVolume * masterVolume;
        _ambienceSource.pitch   = 1f;
        _ambienceSource.Play();
    }

    public void StopLavaAmbience()
    {
        _ambienceSource.Stop();
    }

    // ── Clip generation ────────────────────────────────────────────────────────

    void BuildClips()
    {
        _clipFootstep     = MakeFootstep(false);
        _clipFootstepLava = MakeFootstep(true);
        _clipGoal         = MakeGoalChime();
        _clipDeath        = MakeDeathSound();
        _clipLavaLoop     = MakeLavaLoop();
        _clipWindLoop     = MakeWindLoop();
        _clipJump         = MakeJumpSound();
    }

    AudioClip MakeFootstep(bool onLava)
    {
        // Stone/cobblestone impact: sharp transient click + resonant thud + brief scrape
        int   len     = SampleRate / 8; // ~125ms
        var   samples = new float[len];
        float baseFreq = onLava ? 80f : 130f;

        for (int i = 0; i < len; i++)
        {
            float t = (float)i / SampleRate;

            // Transient click (0–5ms broadband noise burst)
            float click = (Random.value * 2f - 1f) * Mathf.Exp(-t * 700f) * 0.75f;

            // Resonant impact thud
            float thud = Mathf.Sin(2f * Mathf.PI * baseFreq * t)
                       * Mathf.Exp(-t * (onLava ? 22f : 38f)) * 0.55f;

            // Brief scrape texture (band-limited FM noise)
            float scrapeF = onLava ? 180f : 380f;
            float scrape  = Mathf.Sin(2f * Mathf.PI * scrapeF * t
                              + Mathf.Sin(t * 1300f) * 3.5f)
                          * Mathf.Exp(-t * 90f) * 0.22f;

            samples[i] = Mathf.Clamp(click + thud + scrape, -1f, 1f);
        }
        return MakeClip("Footstep", samples);
    }

    AudioClip MakeGoalChime()
    {
        // Triumphant major arpeggio: C5→E5→G5→C6, each note rich with harmonics
        float[] freqs      = { 523.25f, 659.25f, 783.99f, 1046.50f };
        float[] noteStarts = { 0f,      0.15f,   0.30f,   0.48f    };
        int     totalLen   = SampleRate * 3;
        var     samples    = new float[totalLen];

        for (int n = 0; n < freqs.Length; n++)
        {
            int   si = (int)(noteStarts[n] * SampleRate);
            float f  = freqs[n];
            for (int i = si; i < totalLen; i++)
            {
                float t   = (float)(i - si) / SampleRate;
                // Bell-like envelope: fast attack, long resonant decay
                float env = (1f - Mathf.Exp(-t * 60f)) * Mathf.Exp(-t * 1.4f);
                // Gentle vibrato for a musical, natural feel
                float vib = 1f + Mathf.Sin(t * 5.8f + n * 0.9f) * 0.004f;
                float val = (Mathf.Sin(2f * Mathf.PI * f * vib * t) * 0.22f
                           + Mathf.Sin(2f * Mathf.PI * f * 2f * t) * 0.08f
                           + Mathf.Sin(2f * Mathf.PI * f * 3f * t) * 0.03f) * env;
                samples[i] = Mathf.Clamp(samples[i] + val, -1f, 1f);
            }
        }
        return MakeClip("GoalChime", samples);
    }

    AudioClip MakeDeathSound()
    {
        // Descending wail: 400Hz → 80Hz over 0.8s
        int len     = (int)(SampleRate * 0.85f);
        var samples = new float[len];
        for (int i = 0; i < len; i++)
        {
            float t     = (float)i / SampleRate;
            float env   = Mathf.Exp(-2.5f * t) * Mathf.Clamp01(t * 20f);
            float freq  = Mathf.Lerp(400f, 70f, t / 0.85f);
            float noise = (Random.value * 2f - 1f) * 0.1f;
            samples[i]  = (Mathf.Sin(2f * Mathf.PI * freq * t) * 0.45f + noise) * env;
        }
        return MakeClip("Death", samples);
    }

    AudioClip MakeLavaLoop()
    {
        // 2-second seamless loop: low rumble + hiss
        int len     = SampleRate * 2;
        var samples = new float[len];
        // Seed for deterministic noise
        float phase1 = 0f, phase2 = 0f, phase3 = 0f;

        for (int i = 0; i < len; i++)
        {
            float t = (float)i / SampleRate;

            // Low rumble (50-80 Hz, modulated)
            phase1 += (55f + 12f * Mathf.Sin(t * 0.7f)) / SampleRate * 2f * Mathf.PI;
            float rumble = Mathf.Sin(phase1) * 0.18f;

            // Mid crackle (bandlimited noise)
            phase2 += 220f / SampleRate * 2f * Mathf.PI;
            float crackle = Mathf.Sin(phase2 + Mathf.Sin(phase2 * 3.1f) * 2f) * 0.08f;

            // High hiss (filtered noise approximation)
            phase3 += 2200f / SampleRate * 2f * Mathf.PI;
            float hiss = Mathf.Sin(phase3) * (0.5f + 0.5f * Mathf.Sin(phase3 * 0.37f)) * 0.05f;

            float env = 1f; // constant — looped
            samples[i] = (rumble + crackle + hiss) * env;
        }

        // Cross-fade the ends for a seamless loop
        int fadeLen = SampleRate / 10;
        for (int i = 0; i < fadeLen; i++)
        {
            float alpha   = (float)i / fadeLen;
            samples[i]             = Mathf.Lerp(samples[len - fadeLen + i], samples[i], alpha);
            samples[len - 1 - i]   = Mathf.Lerp(samples[fadeLen - 1 - i], samples[len - 1 - i], alpha);
        }

        return MakeClip("LavaLoop", samples);
    }

    AudioClip MakeJumpSound()
    {
        // Short upward whoosh: rising-pitch tone + air puff burst
        int   len = (int)(SampleRate * 0.13f); // 130ms
        var   samples = new float[len];
        float dur = 0.13f;

        for (int i = 0; i < len; i++)
        {
            float t = (float)i / SampleRate;
            float p = t / dur;

            // Rising frequency sweep (body effort sound)
            float freq = Mathf.Lerp(120f, 480f, p * p);
            float env  = Mathf.SmoothStep(0f, 1f, p * 6f) * (1f - p * p);
            float tone = Mathf.Sin(2f * Mathf.PI * freq * t) * 0.28f * env;

            // Air puff (broadband burst at launch)
            float puff = (Random.value * 2f - 1f) * Mathf.Exp(-t * 55f) * 0.45f;

            // Slight wind whoosh tail
            float whoosh = Mathf.Sin(2f * Mathf.PI * 280f * t + Mathf.Sin(t * 900f) * 3f)
                         * Mathf.Exp(-t * 22f) * 0.18f;

            samples[i] = Mathf.Clamp(tone + puff + whoosh, -1f, 1f);
        }
        return MakeClip("Jump", samples);
    }

    AudioClip MakeWindLoop()
    {
        // 4-second gentle breeze: filtered noise with slow AM modulation
        int   len     = SampleRate * 4;
        var   samples = new float[len];
        float phase1 = 0f, phase2 = 0f, phase3 = 0f;

        for (int i = 0; i < len; i++)
        {
            float t = (float)i / SampleRate;
            // Slow gust envelope (0.1–0.3 Hz)
            float gust = 0.55f + 0.35f * Mathf.Sin(t * 0.18f * Mathf.PI * 2f)
                               + 0.10f * Mathf.Sin(t * 0.43f * Mathf.PI * 2f);

            // Layered noise bands (approximate wind spectrum)
            phase1 += 320f / SampleRate * 2f * Mathf.PI;
            phase2 += 850f / SampleRate * 2f * Mathf.PI;
            phase3 += 1800f / SampleRate * 2f * Mathf.PI;

            float low  = Mathf.Sin(phase1 + Mathf.Sin(phase1 * 0.5f) * 2.2f) * 0.28f;
            float mid  = Mathf.Sin(phase2 + Mathf.Sin(phase2 * 0.3f) * 3.1f) * 0.16f;
            float high = Mathf.Sin(phase3 + Mathf.Sin(phase3 * 0.2f) * 1.8f) * 0.08f;

            samples[i] = (low + mid + high) * gust * 0.55f;
        }

        // Cross-fade ends for seamless loop
        int fade = SampleRate / 5;
        for (int i = 0; i < fade; i++)
        {
            float a = (float)i / fade;
            samples[i]           = Mathf.Lerp(samples[len - fade + i], samples[i], a);
            samples[len - 1 - i] = Mathf.Lerp(samples[fade - 1 - i], samples[len - 1 - i], a);
        }

        return MakeClip("Wind", samples);
    }

    void PlaySFX(AudioClip clip, float volume, float pitch)
    {
        if (clip == null) return;
        _sfxSource.pitch  = pitch;
        _sfxSource.volume = volume * sfxVolume * masterVolume;
        _sfxSource.PlayOneShot(clip);
    }

    static AudioClip MakeClip(string name, float[] samples)
    {
        var clip = AudioClip.Create(name, samples.Length, 1, SampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }
}
