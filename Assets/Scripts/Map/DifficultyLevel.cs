public enum DifficultyLevel { Easy, Medium, Hard }

public struct DifficultySettings
{
    public int GridWidthMin,  GridWidthMax;
    public int GridHeightMin, GridHeightMax;
    public int Level1CorridorsMin, Level1CorridorsMax;
    public int MaxBranchDepth;
    public int MaxTotalRooms;
    public int TerminalFromStartMin, TerminalFromStartMax;
    public int TerminalLengthMin,    TerminalLengthMax;
    public float LoopProbability;
    public float BranchProbability;
    public float DeadEndNoObstacleChance;
    public float DeadEndHoleChance;
    public float GoalLavaDepth3Chance;

    public static DifficultySettings For(DifficultyLevel level)
    {
        switch (level)
        {
            case DifficultyLevel.Easy:
                return new DifficultySettings
                {
                    GridWidthMin  = 15, GridWidthMax  = 20,
                    GridHeightMin = 18, GridHeightMax = 25,
                    Level1CorridorsMin = 3, Level1CorridorsMax = 4,
                    MaxBranchDepth = 2,
                    MaxTotalRooms  = 12,
                    TerminalFromStartMin = 1, TerminalFromStartMax = 2,
                    TerminalLengthMin = 3,    TerminalLengthMax = 7,
                    LoopProbability       = 0f,
                    BranchProbability     = 0.5f,
                    DeadEndNoObstacleChance = 0.50f,
                    DeadEndHoleChance       = 0.08f,
                    GoalLavaDepth3Chance    = 0f
                };

            case DifficultyLevel.Medium:
                return new DifficultySettings
                {
                    GridWidthMin  = 20, GridWidthMax  = 28,
                    GridHeightMin = 25, GridHeightMax = 35,
                    Level1CorridorsMin = 4, Level1CorridorsMax = 6,
                    MaxBranchDepth = 3,
                    MaxTotalRooms  = 18,
                    TerminalFromStartMin = 1, TerminalFromStartMax = 3,
                    TerminalLengthMin = 3,    TerminalLengthMax = 9,
                    LoopProbability       = 0.15f,
                    BranchProbability     = 0.60f,
                    DeadEndNoObstacleChance = 0.35f,
                    DeadEndHoleChance       = 0.10f,
                    GoalLavaDepth3Chance    = 0.10f
                };

            default: // Hard
                return new DifficultySettings
                {
                    GridWidthMin  = 25, GridWidthMax  = 37,
                    GridHeightMin = 30, GridHeightMax = 45,
                    Level1CorridorsMin = 6, Level1CorridorsMax = 9,
                    MaxBranchDepth = 5,
                    MaxTotalRooms  = 28,
                    TerminalFromStartMin = 2, TerminalFromStartMax = 4,
                    TerminalLengthMin = 3,    TerminalLengthMax = 12,
                    LoopProbability       = 0.30f,
                    BranchProbability     = 0.70f,
                    DeadEndNoObstacleChance = 0.25f,
                    DeadEndHoleChance       = 0.12f,
                    GoalLavaDepth3Chance    = 0.20f
                };
        }
    }
}
