using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// Zeigt das Wettkampf-HUD und alle Overlays.
///
/// UI-Hierarchie (wird per CompetitionSceneBuilder erstellt):
///
///   Canvas
///   ├── HUDBar                      ← volle Breite, ~90 px hoch, dunkler Hintergrund
///   │   ├── PlayerSection           ← links
///   │   │   ├── PlayerNameLabel     TMP  "DU"
///   │   │   └── PlayerDotsLabel     TMP  "● ● ○ ○ ○"
///   │   ├── CenterSection           ← Mitte
///   │   │   ├── RoundLabel          TMP  "RUNDE 2 / 5"
///   │   │   └── TimerLabel          TMP  "1:23"
///   │   └── AISection               ← rechts
///   │       ├── AIDotsLabel         TMP  "○ ○ ○ ○ ○"
///   │       └── AINameLabel         TMP  "KI"
///   ├── CountdownPanel              (Panel, wird ein-/ausgeblendet)
///   │   └── CountdownLabel          TMP  "5"…"LOS!"
///   ├── GoalFlashPanel              (Panel, kurz einblenden bei erstem Ziel)
///   │   └── GoalFlashLabel          TMP  "Du bist im Ziel! +1"
///   ├── RoundResultPanel            (Panel)
///   │   ├── ResultHeadlineLabel     TMP  "Du gewinnst diese Runde!"
///   │   ├── ResultTimesLabel        TMP  "Du: 0:42  |  KI: 0:55"
///   │   └── ScoreAfterLabel         TMP  "Stand: 2 : 1"
///   └── GameOverPanel               (Panel)
///       ├── GameOverHeadlineLabel   TMP  "Glückwunsch!"
///       ├── FinalScoreLabel         TMP  "Du 3  :  2 KI"
///       └── RestartButton           Button
/// </summary>
public class CompetitionUI : MonoBehaviour
{
    // ── HUD-Bar ───────────────────────────────────────────────────────────────

    [Header("HUD – Spieler (links)")]
    public TextMeshProUGUI playerNameLabel;   // "DU"
    public TextMeshProUGUI playerDotsLabel;   // "● ● ○ ○ ○"

    [Header("HUD – Mitte")]
    public TextMeshProUGUI roundLabel;        // "RUNDE 2 / 5"
    public TextMeshProUGUI timerLabel;        // "1:23"

    [Header("HUD – KI (rechts)")]
    public TextMeshProUGUI aiDotsLabel;       // "○ ○ ○ ○ ○"
    public TextMeshProUGUI aiNameLabel;       // "KI"

    // ── Ziel-Flash ────────────────────────────────────────────────────────────

    [Header("Ziel-Flash (kurze Einblendung)")]
    public GameObject      goalFlashPanel;
    public TextMeshProUGUI goalFlashLabel;

    // ── Countdown-Overlay ────────────────────────────────────────────────────

    [Header("Countdown-Panel")]
    public GameObject      countdownPanel;
    public TextMeshProUGUI countdownLabel;

    // ── Runden-Ergebnis-Overlay ───────────────────────────────────────────────

    [Header("Runden-Ergebnis-Panel")]
    public GameObject      roundResultPanel;
    public TextMeshProUGUI resultHeadlineLabel;
    public TextMeshProUGUI resultTimesLabel;
    public TextMeshProUGUI scoreAfterLabel;

    // ── Game-Over-Screen ─────────────────────────────────────────────────────

    [Header("Game-Over-Panel")]
    public GameObject      gameOverPanel;
    public TextMeshProUGUI gameOverHeadlineLabel;
    public TextMeshProUGUI finalScoreLabel;
    public Button          restartButton;

    // ── Farben ───────────────────────────────────────────────────────────────

    [Header("Farben")]
    public Color playerWinColor  = new Color(0.20f, 0.85f, 0.30f);  // Grün
    public Color aiWinColor      = new Color(0.95f, 0.30f, 0.25f);  // Rot
    public Color playerDotColor  = new Color(0.98f, 0.80f, 0.15f);  // Gold
    public Color aiDotColor      = new Color(0.85f, 0.25f, 0.25f);  // Rot
    public Color emptyDotColor   = new Color(0.25f, 0.25f, 0.25f);  // Dunkelgrau

    // ── Interner State ─────────────────────────────────────────────────────────

    private CompetitionManager mgr;
    private int cachedTotalRounds = 5;

    // ── Lifecycle ────────────────────────────────────────────────────────────

    private void Awake()
    {
        SetActive(countdownPanel,    false);
        SetActive(goalFlashPanel,    false);
        SetActive(roundResultPanel,  false);
        SetActive(gameOverPanel,     false);
    }

    private void Start()
    {
        mgr = CompetitionManager.Instance;
        if (mgr == null)
        {
            Debug.LogError("[CompetitionUI] Kein CompetitionManager gefunden!");
            return;
        }

        cachedTotalRounds = mgr.TotalRounds;

        mgr.OnRoundStarted   += HandleRoundStarted;
        mgr.OnScoreUpdated   += HandleScoreUpdated;
        mgr.OnCountdownTick  += HandleCountdownTick;
        mgr.OnTimerUpdated   += HandleTimerUpdated;
        mgr.OnFirstFinished  += HandleFirstFinished;
        mgr.OnRoundEnded     += HandleRoundEnded;
        mgr.OnGameEnded      += HandleGameEnded;

        // Startzustand
        UpdateRoundLabel(0, cachedTotalRounds);
        UpdateScoreDots(0, 0);
        UpdateTimerLabel(0f);
    }

    private void OnDestroy()
    {
        if (mgr == null) return;
        mgr.OnRoundStarted   -= HandleRoundStarted;
        mgr.OnScoreUpdated   -= HandleScoreUpdated;
        mgr.OnCountdownTick  -= HandleCountdownTick;
        mgr.OnTimerUpdated   -= HandleTimerUpdated;
        mgr.OnFirstFinished  -= HandleFirstFinished;
        mgr.OnRoundEnded     -= HandleRoundEnded;
        mgr.OnGameEnded      -= HandleGameEnded;
    }

    // ── Event-Handler ─────────────────────────────────────────────────────────

    private void HandleRoundStarted(int round, int total)
    {
        cachedTotalRounds = total;
        SetActive(roundResultPanel, false);
        SetActive(gameOverPanel,    false);
        SetActive(goalFlashPanel,   false);
        UpdateRoundLabel(round, total);
        UpdateTimerLabel(0f);
    }

    private void HandleScoreUpdated(int humanScore, int aiScore)
    {
        UpdateScoreDots(humanScore, aiScore);
    }

    private void HandleCountdownTick(int remaining)
    {
        if (remaining <= 0)
        {
            if (countdownLabel != null) countdownLabel.text = "<b>LOS!</b>";
            StartCoroutine(HidePanelAfter(countdownPanel, 0.75f));
        }
        else
        {
            SetActive(countdownPanel, true);
            if (countdownLabel != null) countdownLabel.text = remaining.ToString();
        }
    }

    private void HandleTimerUpdated(float elapsed)
    {
        if (!mgr.RoundIsActive) return;
        UpdateTimerLabel(elapsed);
    }

    private void HandleFirstFinished(bool humanWasFirst)
    {
        if (goalFlashLabel != null)
        {
            if (humanWasFirst)
            {
                goalFlashLabel.text  = "<b>Du bist im Ziel!</b>  <size=80%>+1 Punkt</size>";
                goalFlashLabel.color = playerWinColor;
            }
            else
            {
                goalFlashLabel.text  = "<b>KI ist im Ziel!</b>  <size=80%>+1 Punkt</size>";
                goalFlashLabel.color = aiWinColor;
            }
        }
        SetActive(goalFlashPanel, true);
        StartCoroutine(FadeOutPanel(goalFlashPanel, goalFlashLabel, 2.0f));
    }

    private void HandleRoundEnded(bool humanWasFirst, float humanTime, float aiTime)
    {
        SetActive(goalFlashPanel,   false);
        SetActive(roundResultPanel, true);

        if (resultHeadlineLabel != null)
        {
            if (humanWasFirst)
            {
                resultHeadlineLabel.text  = "<b>Du gewinnst diese Runde!</b>";
                resultHeadlineLabel.color = playerWinColor;
            }
            else
            {
                resultHeadlineLabel.text  = "<b>KI gewinnt diese Runde!</b>";
                resultHeadlineLabel.color = aiWinColor;
            }
        }

        if (resultTimesLabel != null)
        {
            string htStr = humanTime >= float.MaxValue / 2 ? "DNF" : FormatTime(humanTime);
            string aiStr = aiTime    >= float.MaxValue / 2 ? "DNF" : FormatTime(aiTime);
            resultTimesLabel.text = $"Du: {htStr}     KI: {aiStr}";
        }

        if (scoreAfterLabel != null && mgr != null)
            scoreAfterLabel.text = $"Stand:  <color=#{ColorHex(playerDotColor)}>{mgr.HumanScore}</color>  :  <color=#{ColorHex(aiDotColor)}>{mgr.AIScore}</color>";
    }

    private void HandleGameEnded(bool humanWon, int humanScore, int aiScore)
    {
        SetActive(roundResultPanel, false);
        SetActive(goalFlashPanel,   false);
        SetActive(gameOverPanel,    true);

        if (gameOverHeadlineLabel != null)
        {
            if (humanScore == aiScore)
            {
                gameOverHeadlineLabel.text  = "<b>Unentschieden!</b>";
                gameOverHeadlineLabel.color = new Color(0.9f, 0.75f, 0.1f);
            }
            else if (humanWon)
            {
                gameOverHeadlineLabel.text  = "<b>Glückwunsch! Du hast gewonnen!</b>";
                gameOverHeadlineLabel.color = playerWinColor;
            }
            else
            {
                gameOverHeadlineLabel.text  = "<b>Die KI hat gewonnen!</b>";
                gameOverHeadlineLabel.color = aiWinColor;
            }
        }

        if (finalScoreLabel != null)
            finalScoreLabel.text =
                $"<color=#{ColorHex(playerDotColor)}><b>Du  {humanScore}</b></color>" +
                $"  :  " +
                $"<color=#{ColorHex(aiDotColor)}><b>{aiScore}  KI</b></color>";

        if (restartButton != null)
            restartButton.onClick.AddListener(RestartScene);
    }

    // ── HUD-Hilfsmethoden ─────────────────────────────────────────────────────

    private void UpdateRoundLabel(int round, int total)
    {
        if (roundLabel == null) return;
        roundLabel.text = round == 0
            ? $"<size=70%>RUNDE</size>\n<b>– / {total}</b>"
            : $"<size=70%>RUNDE</size>\n<b>{round} / {total}</b>";
    }

    private void UpdateScoreDots(int humanScore, int aiScore)
    {
        if (playerDotsLabel != null)
            playerDotsLabel.text = BuildDots(humanScore, cachedTotalRounds,
                                             playerDotColor, emptyDotColor);
        if (aiDotsLabel != null)
            aiDotsLabel.text     = BuildDots(aiScore,    cachedTotalRounds,
                                             aiDotColor,    emptyDotColor);
    }

    private void UpdateTimerLabel(float elapsed)
    {
        if (timerLabel != null)
            timerLabel.text = "<size=70%>ZEIT</size>\n<b>" + FormatTime(elapsed) + "</b>";
    }

    /// Baut einen String aus gefüllten/leeren Kreisen.
    /// Beispiel für 2/5: "●  ●  ○  ○  ○"
    private string BuildDots(int filled, int total, Color filledColor, Color emptyColor)
    {
        var sb  = new System.Text.StringBuilder();
        string fc = ColorHex(filledColor);
        string ec = ColorHex(emptyColor);
        for (int i = 0; i < total; i++)
        {
            sb.Append(i < filled
                ? $"<color=#{fc}><size=130%>●</size></color>"
                : $"<color=#{ec}><size=130%>●</size></color>");
            if (i < total - 1) sb.Append("  ");
        }
        return sb.ToString();
    }

    // ── Allgemeine Hilfsmethoden ───────────────────────────────────────────────

    private static string FormatTime(float seconds)
    {
        int m = (int)(seconds / 60f);
        int s = (int)(seconds % 60f);
        return $"{m}:{s:D2}";
    }

    private static string ColorHex(Color c)
    {
        return $"{ToByte(c.r):X2}{ToByte(c.g):X2}{ToByte(c.b):X2}";
    }
    private static int ToByte(float f) => Mathf.Clamp(Mathf.RoundToInt(f * 255f), 0, 255);

    private void SetActive(GameObject obj, bool active)
    {
        if (obj != null) obj.SetActive(active);
    }

    private IEnumerator HidePanelAfter(GameObject panel, float delay)
    {
        yield return new WaitForSeconds(delay);
        SetActive(panel, false);
    }

    /// Blendet ein Panel langsam aus (via CanvasGroup oder direkt deaktivieren)
    private IEnumerator FadeOutPanel(GameObject panel, TextMeshProUGUI label, float duration)
    {
        // Optionale weiche Einblendzeit
        float show = 0.8f;
        yield return new WaitForSeconds(show);

        // Ausblenden über Restlaufzeit
        float fadeTime = duration - show;
        float t        = 0f;
        Color startCol = label != null ? label.color : Color.white;

        while (t < fadeTime)
        {
            t += Time.deltaTime;
            float a = Mathf.Lerp(1f, 0f, t / fadeTime);
            if (label != null)
                label.color = new Color(startCol.r, startCol.g, startCol.b, a);
            yield return null;
        }

        SetActive(panel, false);
        // Alpha zurücksetzen für nächste Verwendung
        if (label != null)
            label.color = new Color(startCol.r, startCol.g, startCol.b, 1f);
    }

    private void RestartScene()
    {
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().name);
    }
}
