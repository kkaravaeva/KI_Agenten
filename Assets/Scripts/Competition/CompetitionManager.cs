using System.Collections;
using UnityEngine;

/// <summary>
/// Orchestriert den 4-Runden-Wettkampf zwischen Mensch (PlayerController) und KI (LabyrinthAgent).
///
/// Ablauf pro Runde:
///   1. Vordefinierte Map laden (competitionMaps[rundenIndex])
///   2. Beide Spieler am Spawn positionieren + einfrieren
///   3. Countdown 5 – 4 – 3 – 2 – 1 – LOS!
///   4. Spieler freigeben, Timer läuft
///   5. Wer zuerst das Ziel erreicht ODER wer den Gegner durch Tod gewinnt, bekommt den Punkt
///   6. Erst wenn BEIDE fertig (Ziel oder Tod): kurze Ergebniseinblendung, dann nächste Runde
/// Nach 5 Runden: Gesamtsieger + Endbildschirm.
/// </summary>
public class CompetitionManager : MonoBehaviour
{
    // ── Singleton ────────────────────────────────────────────────────────────
    public static CompetitionManager Instance { get; private set; }

    // ── Inspector-Referenzen ─────────────────────────────────────────────────

    [Header("Referenzen")]
    public ScriptedAIAgent  aiAgent;
    public PlayerController humanPlayer;
    public MapGenerator     mapGenerator;

    [Header("Maps (händisch erstellt, sequenziell)")]
    [Tooltip("Vordefinierte MapData-Assets, eine pro Runde. Werden sequenziell verwendet.")]
    public MapData[] competitionMaps;

    [Header("Einstellungen")]
    [Tooltip("Anzahl Runden (Standard: 4)")]
    public int   totalRounds          = 4;
    [Tooltip("Anzeige-Dauer des Runden-Ergebnisses in Sekunden")]
    public float resultDisplaySeconds = 3f;
    [Tooltip("Countdown-Dauer vor jeder Runde in Sekunden")]
    public float countdownSeconds     = 5f;
    [Tooltip("Maximale Rundenzeit. Danach gilt wer nicht ankam als DNF.")]
    public float maxRoundTimeSeconds  = 300f;

    // ── Öffentliche Events ───────────────────────────────────────────────────

    /// <summary>Neue Runde beginnt. Parameter: Rundennummer (1-based), Gesamtrunden.</summary>
    public event System.Action<int, int>           OnRoundStarted;
    /// <summary>Punktestand geändert. Parameter: Spieler-Score, KI-Score.</summary>
    public event System.Action<int, int>           OnScoreUpdated;
    /// <summary>Countdown-Tick. Parameter: verbleibende Sekunden (5..1) oder 0 = LOS!</summary>
    public event System.Action<int>                OnCountdownTick;
    /// <summary>Jeder Frame während aktiver Runde. Parameter: vergangene Zeit.</summary>
    public event System.Action<float>              OnTimerUpdated;
    /// <summary>Erster Spieler hat Punkt geholt. Parameter: true = Mensch war erster.</summary>
    public event System.Action<bool>               OnFirstFinished;
    /// <summary>Beide fertig – Runde vorbei. Parameter: humanWasFirst, humanTime, aiTime.</summary>
    public event System.Action<bool, float, float> OnRoundEnded;
    /// <summary>Spiel vorbei. Parameter: Mensch gewinnt, Mensch-Score, KI-Score.</summary>
    public event System.Action<bool, int, int>     OnGameEnded;

    // ── Interner Zustand ─────────────────────────────────────────────────────

    private int   currentRound  = 0;
    private int   humanScore    = 0;
    private int   aiScore       = 0;

    private float roundStartTime;
    private bool  humanFinished;
    private bool  aiFinished;
    private float humanFinishTime;
    private float aiFinishTime;
    private bool  firstFinishFired;

    private bool  roundActive;

    // ── Lifecycle ────────────────────────────────────────────────────────────

    private void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
    }

    private void Start()
    {
        if (aiAgent == null || humanPlayer == null || mapGenerator == null)
        {
            Debug.LogError("[CompetitionManager] Referenzen fehlen!");
            enabled = false;
            return;
        }

        if (competitionMaps == null || competitionMaps.Length == 0)
        {
            Debug.LogError("[CompetitionManager] Keine competitionMaps zugewiesen!");
            enabled = false;
            return;
        }

        aiAgent.onGoalReached   = HandleAIGoalReached;
        aiAgent.onAgentDied     = HandleAIDied;

        humanPlayer.onGoalReached = HandleHumanGoalReached;
        humanPlayer.onPlayerDied  = HandleHumanDied;

        StartCoroutine(IntroThenStart());
    }

    private void Update()
    {
        if (!roundActive) return;

        float elapsed = Time.time - roundStartTime;
        OnTimerUpdated?.Invoke(elapsed);

        // Zeitlimit: nicht fertige Spieler als DNF markieren
        if (elapsed >= maxRoundTimeSeconds)
        {
            if (!humanFinished) { humanFinishTime = float.MaxValue; humanFinished = true; }
            if (!aiFinished)    { aiFinishTime    = float.MaxValue; aiFinished    = true; }
            TryFinishRound();
        }
    }

    // ── Spielablauf ──────────────────────────────────────────────────────────

    private IEnumerator IntroThenStart()
    {
        yield return null;
        yield return null;
        BeginNextRound();
    }

    private void BeginNextRound()
    {
        currentRound++;
        humanFinished    = false;
        aiFinished       = false;
        firstFinishFired = false;

        // ── Map laden (vordefinierte Assets, sequenziell) ──────────────────
        int mapIndex = (currentRound - 1) % competitionMaps.Length;
        MapData layout = competitionMaps[mapIndex];

        if (layout == null)
        {
            Debug.LogError($"[CompetitionManager] competitionMaps[{mapIndex}] ist null!");
            return;
        }

        mapGenerator.GenerateMap(layout);

        // ── Positionen setzen ───────────────────────────────────────────────
        Vector3 spawnPos    = mapGenerator.GetSpawnPosition();
        Vector3 playerSpawn = spawnPos + new Vector3(0.6f, 0.6f, 0f);

        aiAgent.FreezeMovement();
        aiAgent.RespawnAtStart();
        aiAgent.RefreshGoal();

        humanPlayer.FreezeMovement();
        humanPlayer.SetSpawnPoint(playerSpawn, Quaternion.identity);
        humanPlayer.RespawnAtStart();

        OnRoundStarted?.Invoke(currentRound, totalRounds);
        OnScoreUpdated?.Invoke(humanScore, aiScore);

        StartCoroutine(CountdownThenStart());
    }

    private IEnumerator CountdownThenStart()
    {
        for (int i = (int)countdownSeconds; i >= 1; i--)
        {
            OnCountdownTick?.Invoke(i);
            yield return new WaitForSeconds(1f);
        }
        OnCountdownTick?.Invoke(0);   // 0 = "LOS!"

        aiAgent.UnfreezeMovement();
        humanPlayer.UnfreezeMovement();

        roundActive    = true;
        roundStartTime = Time.time;
    }

    // ── Ziel-Callbacks ───────────────────────────────────────────────────────

    private void HandleHumanGoalReached()
    {
        if (!roundActive || humanFinished) return;
        humanFinished   = true;
        humanFinishTime = Time.time - roundStartTime;

        if (!firstFinishFired)
        {
            firstFinishFired = true;
            humanScore++;
            OnScoreUpdated?.Invoke(humanScore, aiScore);
            OnFirstFinished?.Invoke(true);
        }

        TryFinishRound();
    }

    private void HandleAIGoalReached()
    {
        if (!roundActive || aiFinished) return;
        aiFinished   = true;
        aiFinishTime = Time.time - roundStartTime;

        if (!firstFinishFired)
        {
            firstFinishFired = true;
            aiScore++;
            OnScoreUpdated?.Invoke(humanScore, aiScore);
            OnFirstFinished?.Invoke(false);
        }

        TryFinishRound();
    }

    // ── Tod-Callbacks: Punkt geht sofort an den anderen ───────────────────────

    private void HandleHumanDied()
    {
        if (!roundActive || humanFinished) return;

        // Spieler stirbt → KI bekommt den Punkt
        if (!firstFinishFired)
        {
            firstFinishFired = true;
            aiScore++;
            OnScoreUpdated?.Invoke(humanScore, aiScore);
            OnFirstFinished?.Invoke(false);   // KI gewinnt
        }

        // Runde sofort beenden (Spieler scheidet aus)
        humanFinished   = true;
        humanFinishTime = float.MaxValue;   // DNF

        // KI gilt als ebenfalls fertig (gewonnen zum aktuellen Zeitpunkt)
        if (!aiFinished)
        {
            aiFinished   = true;
            aiFinishTime = Time.time - roundStartTime;
        }

        TryFinishRound();
    }

    private void HandleAIDied()
    {
        if (!roundActive || aiFinished) return;

        // KI stirbt → Spieler bekommt den Punkt
        if (!firstFinishFired)
        {
            firstFinishFired = true;
            humanScore++;
            OnScoreUpdated?.Invoke(humanScore, aiScore);
            OnFirstFinished?.Invoke(true);   // Spieler gewinnt
        }

        // Runde sofort beenden (KI scheidet aus)
        aiFinished   = true;
        aiFinishTime = float.MaxValue;   // DNF

        // Spieler gilt als ebenfalls fertig
        if (!humanFinished)
        {
            humanFinished   = true;
            humanFinishTime = Time.time - roundStartTime;
        }

        TryFinishRound();
    }

    // ── Rundenende ────────────────────────────────────────────────────────────

    private void TryFinishRound()
    {
        if (!humanFinished || !aiFinished) return;

        roundActive = false;
        aiAgent.FreezeMovement();
        humanPlayer.FreezeMovement();

        bool  humanWasFirst = humanFinishTime <= aiFinishTime;
        float displayHuman  = Mathf.Min(humanFinishTime, maxRoundTimeSeconds);
        float displayAI     = Mathf.Min(aiFinishTime,    maxRoundTimeSeconds);

        OnRoundEnded?.Invoke(humanWasFirst, displayHuman, displayAI);

        if (currentRound >= totalRounds)
            StartCoroutine(DelayThen(resultDisplaySeconds, EndGame));
        else
            StartCoroutine(DelayThen(resultDisplaySeconds, BeginNextRound));
    }

    private void EndGame()
    {
        bool humanWon = humanScore > aiScore;
        OnGameEnded?.Invoke(humanWon, humanScore, aiScore);
    }

    private IEnumerator DelayThen(float seconds, System.Action action)
    {
        yield return new WaitForSeconds(seconds);
        action?.Invoke();
    }

    // ── Öffentliche Getter ────────────────────────────────────────────────────

    public int   CurrentRound  => currentRound;
    public int   TotalRounds   => totalRounds;
    public int   HumanScore    => humanScore;
    public int   AIScore       => aiScore;
    public bool  RoundIsActive => roundActive;
}
