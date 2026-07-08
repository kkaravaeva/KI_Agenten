using System;
using System.IO;
using UnityEngine;

public static class CurriculumTracker
{
    private static CurriculumConfig config;
    private static int currentPhaseIndex;
    private static int currentLayoutIndexInPhase;
    private static int episodeCountInPhase;
    private static int stepCountInPhase;
    private static bool initialized;
    private static string stateFilePath;

    public static int CurrentPhaseIndex    => currentPhaseIndex;
    public static int EpisodeCountInPhase  => episodeCountInPhase;
    public static int StepCountInPhase     => stepCountInPhase;

    [Serializable]
    private class CurriculumState
    {
        public int phaseIndex;
        public int layoutIndexInPhase;
        public int episodeCountInPhase;
        public int stepCountInPhase;
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
        stateFilePath             = null;
    }

    // ML-Agents startet pro --num-envs einen eigenen Unity-Prozess und übergibt jedem
    // via "--mlagents-port <port>" einen eigenen, über Neustarts hinweg stabilen Port.
    // Damit bekommt jede parallele Environment-Instanz ihre eigene State-Datei
    // (kein gemeinsames Schreiben mehrerer Prozesse in dieselbe Datei).
    private static string GetStateFilePath()
    {
        string workerTag = "shared";
        string[] args = Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == "--mlagents-port")
            {
                workerTag = args[i + 1];
                break;
            }
        }
        return Path.Combine(Application.persistentDataPath, $"curriculum_state_{workerTag}.json");
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
        stateFilePath     = GetStateFilePath();
        currentPhaseIndex = Mathf.Clamp(cfg.initialPhaseIndex, 0, (cfg.phases?.Length ?? 1) - 1);
        LoadState();
        initialized       = true;
        Debug.Log($"[Curriculum] Initialisiert. Phasen: {cfg.phases?.Length ?? 0} | Startphase: {currentPhaseIndex} ({cfg.phases?[currentPhaseIndex].difficulty}) | Episode {episodeCountInPhase}/{cfg.phases?[currentPhaseIndex].threshold} | State-Datei: {stateFilePath}");
    }

    private static void LoadState()
    {
        try
        {
            if (!File.Exists(stateFilePath)) return;
            CurriculumState state = JsonUtility.FromJson<CurriculumState>(File.ReadAllText(stateFilePath));
            if (state == null || config.phases == null) return;
            if (state.phaseIndex < 0 || state.phaseIndex >= config.phases.Length) return;

            currentPhaseIndex         = state.phaseIndex;
            currentLayoutIndexInPhase = state.layoutIndexInPhase;
            episodeCountInPhase       = state.episodeCountInPhase;
            stepCountInPhase          = state.stepCountInPhase;
            Debug.Log($"[Curriculum] Gespeicherten Fortschritt geladen: Phase {currentPhaseIndex}, Episode {episodeCountInPhase}");
        }
        catch (Exception e)
        {
            Debug.LogWarning($"[Curriculum] Konnte gespeicherten Fortschritt nicht laden ({stateFilePath}): {e.Message}");
        }
    }

    private static void SaveState()
    {
        try
        {
            var state = new CurriculumState
            {
                phaseIndex          = currentPhaseIndex,
                layoutIndexInPhase  = currentLayoutIndexInPhase,
                episodeCountInPhase = episodeCountInPhase,
                stepCountInPhase    = stepCountInPhase,
            };
            string tmpPath = stateFilePath + ".tmp";
            File.WriteAllText(tmpPath, JsonUtility.ToJson(state));
            File.Copy(tmpPath, stateFilePath, true);
            File.Delete(tmpPath);
        }
        catch (Exception e)
        {
            Debug.LogWarning($"[Curriculum] Konnte Fortschritt nicht speichern ({stateFilePath}): {e.Message}");
        }
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
        SaveState();

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
        SaveState();

        Debug.Log($"[Curriculum] Phase gewechselt → Phase {currentPhaseIndex} ({config.phases[currentPhaseIndex].difficulty})");
    }
}
