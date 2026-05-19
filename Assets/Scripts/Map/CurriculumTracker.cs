using Unity.MLAgents;
using UnityEngine;

public static class CurriculumTracker
{
    private static CurriculumConfig config;
    private static int currentPhaseIndex;
    private static int currentLayoutIndexInPhase;
    private static int episodeCountInPhase;
    private static int stepCountInPhase;
    private static bool initialized;

    // SuccessRate-EMA pro Phase (für Fix 2.2 + Fix 5.2)
    private static float[] successRateEMA;
    private static int[]   episodesPerPhase;
    private static int[]   successesPerPhase;

    // Letzte gezogene Mixing-Phase (für Logging / Beobachtung welche Phase tatsächlich gespielt wurde)
    private static int lastSampledPhaseIndex;
    public static int LastSampledPhaseIndex => lastSampledPhaseIndex;

    private static System.Random rng = new System.Random();

    public static int CurrentPhaseIndex    => currentPhaseIndex;
    public static int EpisodeCountInPhase  => episodeCountInPhase;
    public static int StepCountInPhase     => stepCountInPhase;

    public static float GetSuccessRateEMA(int phaseIndex)
    {
        if (successRateEMA == null || phaseIndex < 0 || phaseIndex >= successRateEMA.Length) return 0f;
        return successRateEMA[phaseIndex];
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    private static void ResetOnDomainReload()
    {
        config                    = null;
        currentPhaseIndex         = 0;
        currentLayoutIndexInPhase = 0;
        episodeCountInPhase       = 0;
        stepCountInPhase          = 0;
        initialized               = false;
        successRateEMA            = null;
        episodesPerPhase          = null;
        successesPerPhase         = null;
        lastSampledPhaseIndex     = 0;
        rng                       = new System.Random();
    }

    public static void Initialize(CurriculumConfig cfg)
    {
        if (initialized) return;
        if (cfg == null)
        {
            Debug.LogError("CurriculumTracker: CurriculumConfig ist null!");
            return;
        }
        config      = cfg;
        initialized = true;
        int n = cfg.phases?.Length ?? 0;
        successRateEMA    = new float[n];
        episodesPerPhase  = new int[n];
        successesPerPhase = new int[n];
        Debug.Log($"[Curriculum] Initialisiert. Phasen: {n} | Startphase: {(n > 0 ? cfg.phases[0].difficulty.ToString() : "-")} | Mixing={cfg.enablePhaseMixing} | SR-Advance={cfg.useSuccessRateAdvance}");
    }

    /// <summary>
    /// Gibt das nächste Layout zurück. Wenn Phase-Mixing aktiv ist, kann das Layout aus
    /// einer früheren Phase stammen (lastSampledPhaseIndex zeigt die tatsächlich gezogene Phase).
    /// </summary>
    public static MapData GetNextLayout()
    {
        if (!initialized || config == null || config.phases == null || config.phases.Length == 0)
        {
            Debug.LogError("CurriculumTracker: Nicht initialisiert oder keine Phasen konfiguriert!");
            return null;
        }

        CheckPhaseAdvance();

        int sampledPhase = SamplePhaseForMixing();
        lastSampledPhaseIndex = sampledPhase;

        CurriculumPhase phase = config.phases[sampledPhase];

        if (phase.layouts == null || phase.layouts.Length == 0)
        {
            Debug.LogError($"CurriculumTracker: Phase {sampledPhase} ({phase.difficulty}) hat keine Layouts zugewiesen!");
            return null;
        }

        // Bei Mixing zufällig aus Layouts ziehen, sonst sequenziell
        MapData layout = config.enablePhaseMixing
            ? phase.layouts[rng.Next(phase.layouts.Length)]
            : phase.layouts[currentLayoutIndexInPhase % phase.layouts.Length];

        // Pure-Episoden zählen für minEpisodesBeforeAdvance; Mix-Episoden nicht.
        if (!config.enablePhaseMixing || sampledPhase == currentPhaseIndex)
        {
            currentLayoutIndexInPhase++;
            episodeCountInPhase++;
        }

        Debug.Log($"[Curriculum] Phase {currentPhaseIndex} ({config.phases[currentPhaseIndex].difficulty}) | Ep {episodeCountInPhase}/{phase.threshold} | Gezogen: Phase {sampledPhase} ({phase.difficulty}) | Layout: {layout?.name}");

        return layout;
    }

    /// <summary>
    /// Liefert die Phase, aus der das nächste Layout gezogen wird. Bei Mixing:
    /// mixingCurrentWeight aktuelle Phase, mixingPreviousWeight Vorgänger, Rest random aus mixingPool (V16 Fix G).
    /// </summary>
    private static int SamplePhaseForMixing()
    {
        if (!config.enablePhaseMixing || currentPhaseIndex == 0)
            return currentPhaseIndex;

        float wCurrent  = Mathf.Clamp01(config.mixingCurrentWeight);
        float wPrevious = Mathf.Clamp01(config.mixingPreviousWeight);
        if (wCurrent + wPrevious > 1f) wPrevious = Mathf.Max(0f, 1f - wCurrent);
        float wRest = 1f - wCurrent - wPrevious;

        double draw = rng.NextDouble();
        if (draw < wCurrent) return currentPhaseIndex;

        // V16 Fix G: Wenn mixingPool gesetzt ist, ziehe nur aus diesen Indices.
        // Sonst (V15-Default): Vorgänger / alle vorigen Phasen.
        int[] pool = config.phases[currentPhaseIndex].mixingPool;
        bool hasPool = pool != null && pool.Length > 0;

        if (draw < wCurrent + wPrevious)
        {
            if (hasPool)
            {
                // Vorgänger im Pool = größter Pool-Index < currentPhase.
                int prevInPool = -1;
                for (int i = 0; i < pool.Length; i++)
                    if (pool[i] < currentPhaseIndex && pool[i] > prevInPool) prevInPool = pool[i];
                if (prevInPool >= 0) return prevInPool;
            }
            return Mathf.Max(0, currentPhaseIndex - 1);
        }

        if (wRest > 0f)
        {
            if (hasPool)
            {
                // Random aus mixingPool, ausgenommen currentPhaseIndex selbst
                // (wurde bereits über wCurrent abgedeckt).
                int n = pool.Length;
                if (n > 0)
                {
                    // 1. Versuche bis zu 4× ein != currentPhase zu ziehen, sonst fallback.
                    for (int tries = 0; tries < 4; tries++)
                    {
                        int idx = pool[rng.Next(n)];
                        if (idx != currentPhaseIndex && idx >= 0 && idx < config.phases.Length)
                            return idx;
                    }
                }
            }
            else if (currentPhaseIndex > 0)
            {
                return rng.Next(0, currentPhaseIndex); // 0..currentPhase-1
            }
        }
        return currentPhaseIndex;
    }

    public static void NotifyStep()
    {
        if (!initialized) return;
        stepCountInPhase++;
    }

    /// <summary>
    /// Vom Agent am Episodenende aufzurufen. Aktualisiert EMA + Per-Phase-Counter
    /// für die Phase, aus der die Episode tatsächlich gezogen wurde (lastSampledPhaseIndex).
    /// </summary>
    public static void NotifyEpisodeEnd(bool success)
    {
        if (!initialized || config == null) return;

        int phase = lastSampledPhaseIndex;
        if (phase < 0 || phase >= config.phases.Length) return;

        episodesPerPhase[phase]++;
        if (success) successesPerPhase[phase]++;

        // V16 Fix L: EMA nur für die aktuell aktive Phase aktualisieren.
        // Mixing-Episodes verzerren sonst die Advance-Entscheidung, weil
        // CheckPhaseAdvance gegen successRateEMA[currentPhaseIndex] vergleicht.
        if (phase == currentPhaseIndex)
        {
            float alpha = config.successRateEMAAlpha;
            successRateEMA[phase] = (1f - alpha) * successRateEMA[phase] + alpha * (success ? 1f : 0f);
        }

        // ML-Agents Stats: SuccessRate pro Phase (Fix 5.2)
        if (Academy.IsInitialized)
        {
            Academy.Instance.StatsRecorder.Add(
                $"Custom/SuccessRate_P{phase}",
                success ? 1f : 0f);
            Academy.Instance.StatsRecorder.Add(
                $"Custom/SuccessRateEMA_P{phase}",
                successRateEMA[phase]);
        }
    }

    private static void CheckPhaseAdvance()
    {
        if (!config.loopPhases && currentPhaseIndex >= config.phases.Length - 1) return;

        CurriculumPhase phase = config.phases[currentPhaseIndex];

        bool advance;
        if (phase.thresholdType == ThresholdType.SuccessRate || config.useSuccessRateAdvance)
        {
            float ema = successRateEMA != null && currentPhaseIndex < successRateEMA.Length
                ? successRateEMA[currentPhaseIndex] : 0f;
            advance = ema >= config.successRateThreshold
                   && episodeCountInPhase >= config.minEpisodesBeforeAdvance;
        }
        else if (phase.thresholdType == ThresholdType.Episodes)
        {
            advance = episodeCountInPhase >= phase.threshold;
        }
        else // Steps
        {
            advance = stepCountInPhase >= phase.threshold;
        }

        if (!advance) return;

        int previousPhase = currentPhaseIndex;
        currentPhaseIndex         = (currentPhaseIndex + 1) % config.phases.Length;
        currentLayoutIndexInPhase = 0;
        episodeCountInPhase       = 0;
        stepCountInPhase          = 0;

        Debug.Log($"[Curriculum] Phase {previousPhase} → {currentPhaseIndex} ({config.phases[currentPhaseIndex].difficulty}) | EMA war {(successRateEMA != null ? successRateEMA[previousPhase] : 0f):F3}");
    }
}
