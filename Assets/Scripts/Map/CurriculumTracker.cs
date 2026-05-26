using UnityEngine;

public static class CurriculumTracker
{
    private static CurriculumConfig config;
    private static int currentPhaseIndex;
    private static int currentLayoutIndexInPhase;
    private static int episodeCountInPhase;
    private static int stepCountInPhase;
    private static bool initialized;

    public static int CurrentPhaseIndex    => currentPhaseIndex;
    public static int EpisodeCountInPhase  => episodeCountInPhase;
    public static int StepCountInPhase     => stepCountInPhase;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    private static void ResetOnDomainReload()
    {
        config                    = null;
        currentPhaseIndex         = 0;
        currentLayoutIndexInPhase = 0;
        episodeCountInPhase       = 0;
        stepCountInPhase          = 0;
        initialized               = false;
    }

    public static void Initialize(CurriculumConfig cfg)
    {
        if (initialized) return;
        if (cfg == null)
        {
            Debug.LogError("CurriculumTracker: CurriculumConfig ist null!");
            return;
        }
        config            = cfg;
        currentPhaseIndex = Mathf.Clamp(cfg.initialPhaseIndex, 0, (cfg.phases?.Length ?? 1) - 1);
        initialized       = true;
        Debug.Log($"[Curriculum] Initialisiert. Phasen: {cfg.phases?.Length ?? 0} | Startphase: {currentPhaseIndex} ({cfg.phases?[currentPhaseIndex].difficulty})");
    }

    /// <summary>
    /// Gibt das nächste Layout der aktuellen Phase zurück.
    /// Alle Phasen nutzen layouts[] — keine Sonderfälle mehr.
    /// </summary>
    public static MapData GetNextLayout()
    {
        if (!initialized || config == null || config.phases == null || config.phases.Length == 0)
        {
            Debug.LogError("CurriculumTracker: Nicht initialisiert oder keine Phasen konfiguriert!");
            return null;
        }

        CheckPhaseAdvance();

        CurriculumPhase phase = config.phases[currentPhaseIndex];

        if (phase.layouts == null || phase.layouts.Length == 0)
        {
            Debug.LogError($"CurriculumTracker: Phase {currentPhaseIndex} ({phase.difficulty}) hat keine Layouts zugewiesen!");
            return null;
        }

        MapData layout = phase.layouts[currentLayoutIndexInPhase % phase.layouts.Length];

        currentLayoutIndexInPhase++;
        episodeCountInPhase++;

        Debug.Log($"[Curriculum] Phase {currentPhaseIndex} ({phase.difficulty}) | Episode {episodeCountInPhase}/{phase.threshold} | Layout: {layout?.name}");

        return layout;
    }

    public static void NotifyStep()
    {
        if (!initialized) return;
        stepCountInPhase++;
    }

    private static void CheckPhaseAdvance()
    {
        bool isLastPhase = currentPhaseIndex >= config.phases.Length - 1;
        if (!config.loopPhases && isLastPhase) return;

        CurriculumPhase phase = config.phases[currentPhaseIndex];
        bool advance = phase.thresholdType == ThresholdType.Episodes
            ? episodeCountInPhase >= phase.threshold
            : stepCountInPhase   >= phase.threshold;

        if (!advance) return;

        if (isLastPhase)
            currentPhaseIndex = Mathf.Clamp(config.loopStartPhaseIndex, 0, config.phases.Length - 1);
        else
            currentPhaseIndex++;

        currentLayoutIndexInPhase = 0;
        episodeCountInPhase       = 0;
        stepCountInPhase          = 0;

        Debug.Log($"[Curriculum] Phase gewechselt → Phase {currentPhaseIndex} ({config.phases[currentPhaseIndex].difficulty})");
    }
}
