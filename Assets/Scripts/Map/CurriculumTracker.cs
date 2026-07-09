using System;
using System.Collections.Generic;
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

    // Erfolgs-Gate: Rolling-Fenster über die letzten Episoden-Ergebnisse aller Agenten.
    // Wird bewusst NICHT persistiert — nach einem Neustart füllt es sich neu, bevor das
    // Gate wieder greifen kann (verhindert Aufstieg mit veralteten Erfolgsdaten).
    private static readonly Queue<bool> successResults = new Queue<bool>();
    private static int successCount;

    public static int CurrentPhaseIndex    => currentPhaseIndex;
    public static int EpisodeCountInPhase  => episodeCountInPhase;
    public static int StepCountInPhase     => stepCountInPhase;
    /// <summary>Aktuelle Erfolgsrate im Gate-Fenster (0 wenn Fenster leer).</summary>
    public static float GateSuccessRate    => successResults.Count > 0 ? (float)successCount / successResults.Count : 0f;

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
        successResults.Clear();
        successCount              = 0;
    }

    /// <summary>
    /// Meldet das Ergebnis einer abgeschlossenen Episode (alle Agenten teilen sich das Fenster).
    /// </summary>
    public static void NotifyEpisodeResult(bool success)
    {
        if (!initialized || config == null) return;
        successResults.Enqueue(success);
        if (success) successCount++;
        int cap = Mathf.Max(10, config.successWindow);
        while (successResults.Count > cap)
        {
            if (successResults.Dequeue()) successCount--;
        }
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

        // Unity-Lebenszeit-Check: "== null" greift (anders als "?.") auch für zerstörte
        // Objekte. Im Editor kann ein AssetDatabase-Reimport während des Play-Modus die
        // geladenen MapData-Instanzen zerstören — dann hier sauber abbrechen, statt mit
        // einer MissingReferenceException den ML-Agents-Episoden-Reset zu zerschießen.
        if (layout == null)
        {
            Debug.LogError($"CurriculumTracker: Layout {currentLayoutIndexInPhase % phase.layouts.Length} in Phase {currentPhaseIndex} ist null/zerstört (Asset-Reimport im Editor?). Play-Modus stoppen und neu starten.");
            return null;
        }

        currentLayoutIndexInPhase++;
        episodeCountInPhase++;
        SaveState();

        Debug.Log($"[Curriculum] Phase {currentPhaseIndex} ({phase.difficulty}) | Episode {episodeCountInPhase}/{phase.threshold} | Layout: {layout.name}");

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
        bool thresholdReached = phase.thresholdType == ThresholdType.Episodes
            ? episodeCountInPhase >= phase.threshold
            : stepCountInPhase   >= phase.threshold;

        if (!thresholdReached) return;

        // Erfolgs-Gate: Nach der Episoden-Schwelle wird die Phase nur verlassen, wenn die
        // Erfolgsrate im Rolling-Fenster die Mindestrate erreicht — oder der Notausstieg
        // (threshold × hardCapFactor) greift, damit keine Phase endlos blockiert.
        if (phase.minSuccessRate > 0f)
        {
            int  hardCap    = phase.threshold * Mathf.Max(1, config.hardCapFactor);
            int  progress   = phase.thresholdType == ThresholdType.Episodes ? episodeCountInPhase : stepCountInPhase;
            bool windowFull = successResults.Count >= Mathf.Max(10, config.successWindow);
            float rate      = successResults.Count > 0 ? (float)successCount / successResults.Count : 0f;

            if (progress < hardCap && (!windowFull || rate < phase.minSuccessRate))
            {
                if (episodeCountInPhase % 100 == 0)
                    Debug.Log($"[Curriculum] Gate hält Phase {currentPhaseIndex} ({phase.difficulty}): SuccessRate={rate:P0} (Fenster {successResults.Count}, benötigt {phase.minSuccessRate:P0}) | Fortschritt {progress}/{hardCap} bis Notausstieg");
                return;
            }

            Debug.Log($"[Curriculum] Gate passiert für Phase {currentPhaseIndex} ({phase.difficulty}): SuccessRate={rate:P0}, Fortschritt {progress} (Notausstieg bei {hardCap})");
        }

        if (isLastPhase)
            currentPhaseIndex = Mathf.Clamp(config.loopStartPhaseIndex, 0, config.phases.Length - 1);
        else
            currentPhaseIndex++;

        currentLayoutIndexInPhase = 0;
        episodeCountInPhase       = 0;
        stepCountInPhase          = 0;
        successResults.Clear();
        successCount              = 0;
        SaveState();

        Debug.Log($"[Curriculum] Phase gewechselt → Phase {currentPhaseIndex} ({config.phases[currentPhaseIndex].difficulty})");
    }
}
