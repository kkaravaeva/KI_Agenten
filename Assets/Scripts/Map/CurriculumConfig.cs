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
}

[CreateAssetMenu(fileName = "CurriculumConfig", menuName = "Training/Curriculum Config")]
public class CurriculumConfig : ScriptableObject
{
    public CurriculumPhase[] phases;
    [Tooltip("Nach der letzten Phase wieder von vorne beginnen. false = auf letzter Phase einfrieren.")]
    public bool loopPhases = false;
}
