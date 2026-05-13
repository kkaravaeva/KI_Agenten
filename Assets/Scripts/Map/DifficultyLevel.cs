public enum DifficultyLevel
{
    Trivial              = 0,  // 7×7 offener Raum, Spawn Ecke, Goal random
    TrivialCorr          = 1,  // SpawnRaum + GoalRaum + 1 direkter Korridor
    TrivialBranch        = 2,  // + 1 Ast-Korridor (kein Raum am Ende)
    TrivialHole          = 3,  // + Ast-Korridor endet mit 2×2 Hole
    TrivialHazard        = 4,  // + 2×1 Lava im Hauptkorridor + Hole-Ast (Originalwert beibehalten)
    Easy                 = 5,
    Medium               = 6,
    Hard                 = 7,
    // ── Sub-Phasen 4a/4b/4c (hinten angehängt für Asset-Rückwärtskompatibilität) ──
    TrivialLavaSurround  = 8,  // 4a: Lava am Branch-Ende statt Hole (Agent muss Lava sehen, nicht überqueren)
    TrivialLavaCrossable = 9,  // 4b: 1-Tile-Lava im Hauptkorridor, breiter Anlauf, kein Hole-Ast
    TrivialLavaWide      = 10, // 4c: 2-Tile-Lava in Längsrichtung, knapper Anlauf, kein Hole-Ast
}

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
            // Trivial-Varianten nutzen keine DifficultySettings (direkte Grid-Konstruktion)
            case DifficultyLevel.Trivial:
            case DifficultyLevel.TrivialCorr:
            case DifficultyLevel.TrivialBranch:
            case DifficultyLevel.TrivialHole:
            case DifficultyLevel.TrivialHazard:
            case DifficultyLevel.TrivialLavaSurround:
            case DifficultyLevel.TrivialLavaCrossable:
            case DifficultyLevel.TrivialLavaWide:
                return new DifficultySettings
                {
                    GridWidthMin  = 7, GridWidthMax  = 7,
                    GridHeightMin = 7, GridHeightMax = 7,
                };

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
