using System;
using UnityEngine;

public enum TrainingMode { Standard, Curriculum }

public enum ThresholdType { Episodes, Steps, SuccessRate }

[Serializable]
public struct CurriculumPhase
{
    public DifficultyLevel difficulty;
    public MapData[] layouts;
    public ThresholdType thresholdType;
    [Min(1)] public int threshold;
}

[CreateAssetMenu(fileName = "CurriculumConfig", menuName = "Training/Curriculum Config")]
public class CurriculumConfig : ScriptableObject
{
    public CurriculumPhase[] phases;
    [Tooltip("Nach der letzten Phase wieder von vorne beginnen. false = auf letzter Phase einfrieren.")]
    public bool loopPhases = false;

    [Header("Phase-Mixing (Anti-Catastrophic-Forgetting)")]
    [Tooltip("Wenn true: Layouts werden teilweise aus früheren Phasen gemischt.")]
    public bool enablePhaseMixing = false;
    [Tooltip("Anteil aktuelle Phase. Rest splittet sich nach mixingPreviousWeight auf direkten Vorgänger und Rest auf zufällige frühere Phasen.")]
    [Range(0f, 1f)] public float mixingCurrentWeight  = 0.70f;
    [Tooltip("Anteil direkter Vorgänger. mixingCurrent + mixingPrevious <= 1.")]
    [Range(0f, 1f)] public float mixingPreviousWeight = 0.20f;

    [Header("SuccessRate-basiertes Advancement (Fix 2.2)")]
    [Tooltip("Wenn true UND thresholdType==SuccessRate: Phase advancet wenn EMA > Threshold UND Min-Episoden.")]
    public bool useSuccessRateAdvance = false;
    [Range(0f, 1f)] public float successRateThreshold = 0.7f;
    [Min(1)] public int minEpisodesBeforeAdvance = 1000;
    [Range(0.001f, 1f)] public float successRateEMAAlpha = 0.02f;
}
