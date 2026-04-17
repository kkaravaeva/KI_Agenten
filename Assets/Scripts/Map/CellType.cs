public enum CellType
{
    Empty,
    Floor,
    Wall,
    Obstacle,
    Goal,
    SpawnPoint,
    Lava,       // Betretbar (Tod), bis Tiefe 1 überspringbar
    Hole,       // Nicht betretbar, nicht überspringbar (mind. 2x2 groß)
    Platform    // Schwebendes Bodenfeld über Lava (0.75 Units höher)
}