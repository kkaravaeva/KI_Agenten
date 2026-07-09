using System;
using UnityEngine;

public enum TrainingMode { Standard, Curriculum }

public enum ThresholdType { Episodes, Steps }

[Serializable]
public struct CurriculumPhase
{
    public DifficultyLevel difficulty;
    public MapData[] layouts;
    public ThresholdType thresholdType;
    [Min(1)] public int threshold;
    [Tooltip("Mindest-Erfolgsrate (0-1) über das Erfolgsfenster, bevor die Phase verlassen werden darf. 0 = kein Gate (nur Episoden-Schwelle).")]
    [Range(0f, 1f)] public float minSuccessRate;
}

[CreateAssetMenu(fileName = "CurriculumConfig", menuName = "Training/Curriculum Config")]
public class CurriculumConfig : ScriptableObject
{
    public CurriculumPhase[] phases;
    [Tooltip("Nach der letzten Phase wieder von vorne beginnen. false = auf letzter Phase einfrieren.")]
    public bool loopPhases = false;
    [Tooltip("Phase-Index, zu dem beim Loop zurückgekehrt wird. 0 = ganz von vorne, 6 = ab Easy.")]
    [Min(0)] public int loopStartPhaseIndex = 0;
    [Tooltip("Phase-Index, bei dem das Training startet. 0 = Anfang. Unabhängig vom Loop-Startindex.")]
    [Min(0)] public int initialPhaseIndex = 0;
    [Tooltip("Fenstergröße (Episoden) für die Erfolgsraten-Messung des Phase-Gates.")]
    [Min(10)] public int successWindow = 200;
    [Tooltip("Notausstieg: Phase wird spätestens nach threshold × Faktor Episoden verlassen, auch ohne Erfolgsrate.")]
    [Min(1)] public int hardCapFactor = 3;
}
