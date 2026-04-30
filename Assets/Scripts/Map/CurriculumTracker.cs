using UnityEngine;

public static class CurriculumTracker
{
    private static CurriculumConfig config;
    private static int currentPhaseIndex;
    private static int currentLayoutIndexInPhase;
    private static int episodeCountInPhase;
    private static int stepCountInPhase;
    private static bool initialized;

    public static int CurrentPhaseIndex => currentPhaseIndex;
    public static int EpisodeCountInPhase => episodeCountInPhase;
    public static int StepCountInPhase => stepCountInPhase;

    // Wird von RuntimeInitializeOnLoadMethod aufgerufen, damit statische Felder
    // beim Starten des Play Mode im Editor korrekt zurückgesetzt werden.
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    private static void ResetOnDomainReload()
    {
        config = null;
        currentPhaseIndex = 0;
        currentLayoutIndexInPhase = 0;
        episodeCountInPhase = 0;
        stepCountInPhase = 0;
        initialized = false;
    }

    public static void Initialize(CurriculumConfig cfg)
    {
        if (initialized) return;
        if (cfg == null)
        {
            Debug.LogError("CurriculumTracker: CurriculumConfig ist null!");
            return;
        }
        config = cfg;
        initialized = true;
        Debug.Log($"[Curriculum] Initialisiert. Phasen: {cfg.phases?.Length ?? 0} | Startphase: {cfg.phases?[0].difficulty}");
    }

    // Gibt das nächste sequenzielle Layout der aktuellen Phase zurück.
    // Wird einmal pro Episodenstart pro MapGenerator aufgerufen.
    // Jeder Aufruf erhöht den Layout-Index, sodass verschiedene Maps
    // in derselben Episode unterschiedliche Layouts erhalten.
    public static MapData GetNextLayout()
    {
        if (!initialized || config == null || config.phases == null || config.phases.Length == 0)
        {
            Debug.LogError("CurriculumTracker: Nicht initialisiert oder keine Phasen konfiguriert!");
            return null;
        }

        CheckPhaseAdvance();

        CurriculumPhase phase = config.phases[currentPhaseIndex];

        MapData layout;
        if (phase.difficulty == DifficultyLevel.Trivial)
        {
            layout = ProceduralLayoutGenerator.GenerateLayout(
                UnityEngine.Random.Range(0, 99999), DifficultyLevel.Trivial);

            if (layout == null)
            {
                Debug.LogError($"CurriculumTracker: Trivial-Generierung für Phase {currentPhaseIndex} fehlgeschlagen!");
                return null;
            }
        }
        else
        {
            if (phase.layouts == null || phase.layouts.Length == 0)
            {
                Debug.LogError($"CurriculumTracker: Phase {currentPhaseIndex} ({phase.difficulty}) hat keine Layouts zugewiesen!");
                return null;
            }

            layout = phase.layouts[currentLayoutIndexInPhase % phase.layouts.Length];
        }

        currentLayoutIndexInPhase++;
        episodeCountInPhase++;

        Debug.Log($"[Curriculum] Phase {currentPhaseIndex} ({phase.difficulty}) | Episode in Phase: {episodeCountInPhase}/{phase.threshold} | Layout: {layout?.name}");

        return layout;
    }

    public static void NotifyStep()
    {
        if (!initialized) return;
        stepCountInPhase++;
    }

    private static void CheckPhaseAdvance()
    {
        if (!config.loopPhases && currentPhaseIndex >= config.phases.Length - 1) return;

        CurriculumPhase phase = config.phases[currentPhaseIndex];
        bool advance = phase.thresholdType == ThresholdType.Episodes
            ? episodeCountInPhase >= phase.threshold
            : stepCountInPhase >= phase.threshold;

        if (!advance) return;

        currentPhaseIndex = (currentPhaseIndex + 1) % config.phases.Length;
        currentLayoutIndexInPhase = 0;
        episodeCountInPhase = 0;
        stepCountInPhase = 0;

        Debug.Log($"[Curriculum] Phase gewechselt → Phase {currentPhaseIndex} ({config.phases[currentPhaseIndex].difficulty})");
    }
}
