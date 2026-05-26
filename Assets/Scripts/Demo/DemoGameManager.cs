using UnityEngine;

public enum DemoParticipant
{
    Player,
    AI
}

public class DemoGameManager : MonoBehaviour
{
    [Header("References")]
    public MapGenerator mapGenerator;
    public Transform playerAgent;
    public Transform aiAgent;

    [Header("UI")]
    public GameObject startPanel;
    public GameObject hudPanel;
    public GameObject resultPanel;

    [Header("Match Settings")]
    public int numberOfMaps = 5;
    public float countdownDuration = 5f;
    public int selectedMapIndex = 0;
    public float spawnOffset = 0.6f;
    public float spawnHeight = 0.6f;

    [Header("Audio")]
    public AudioSource audioSource;
    public AudioClip playerWinSound;

    private int currentMapIndex = 0;
    private int playerWins = 0;
    private int aiWins = 0;

    private float[] playerTimes;
    private float[] aiTimes;

    private Vector3 playerSpawn;
    private Vector3 aiSpawn;

    private float playerTime;
    private float aiTime;

    private bool gameRunning;
    private bool countdownRunning;
    private bool playerFinished;
    private bool aiFinished;

    private float countdownTime;

    private void Start()
    {
        gameRunning = false;
        countdownRunning = false;

        playerTimes = new float[numberOfMaps];
        aiTimes = new float[numberOfMaps];

        if (playerAgent != null)
        playerAgent.gameObject.SetActive(false);

        if (aiAgent != null)
        aiAgent.gameObject.SetActive(false);

        StartGame();
    }
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            AbortGame();
        }

        if (countdownRunning)
        {
            countdownTime -= Time.deltaTime;

            if (countdownTime <= 0f)
            {
                countdownRunning = false;
                gameRunning = true;
                SetAgentsMovementActive(true);

                Debug.Log("RUNDE STARTET JETZT");
            }

            return;
        }

        if (!gameRunning)
            return;

        if (!playerFinished)
            playerTime += Time.deltaTime;

        if (!aiFinished)
            aiTime += Time.deltaTime;
    }

    public void StartGame()
    {
        Debug.Log("MATCH STARTET");

        if (mapGenerator == null)
        {
            Debug.LogError("DemoGameManager: MapGenerator ist nicht gesetzt.");
            return;
        }

        if (playerAgent == null)
        {
            Debug.LogError("DemoGameManager: PlayerAgent ist nicht gesetzt.");
            return;
        }

        if (aiAgent == null)
        {
            Debug.LogError("DemoGameManager: AIAgent ist nicht gesetzt.");
            return;
        }

        if (mapGenerator.mapLayouts == null || mapGenerator.mapLayouts.Length == 0)
        {
            Debug.LogError("DemoGameManager: Im MapGenerator sind keine MapLayouts gesetzt.");
            return;
        }

        numberOfMaps = Mathf.Min(numberOfMaps, mapGenerator.mapLayouts.Length);

        currentMapIndex = selectedMapIndex;
        playerWins = 0;
        aiWins = 0;

        playerTimes = new float[numberOfMaps];
        aiTimes = new float[numberOfMaps];

        if (startPanel != null)
            startPanel.SetActive(false);

        if (hudPanel != null)
            hudPanel.SetActive(true);

        if (resultPanel != null)
            resultPanel.SetActive(false);

        StartRound(currentMapIndex);
    }

    private void StartRound(int mapIndex)
    {
        Debug.Log("Starte Map " + (mapIndex + 1));

        gameRunning = false;
        countdownRunning = false;

        SetAgentsMovementActive(false);

        mapGenerator.selectionMode = MapSelectionMode.Fixed;
        mapGenerator.selectedLayoutIndex = mapIndex;
        mapGenerator.GenerateSelectedMap();

        SetupSpawns();

        playerAgent.gameObject.SetActive(true);
        aiAgent.gameObject.SetActive(true);

        ResetAgents();

        playerTime = 0f;
        aiTime = 0f;

        playerFinished = false;
        aiFinished = false;

        StartCountdown();
    }

    private void StartCountdown()
    {
        countdownTime = countdownDuration;
        countdownRunning = true;
        gameRunning = false;

        SetAgentsMovementActive(false);

        Debug.Log("Countdown gestartet: " + countdownDuration + " Sekunden");
    }

    private void SetupSpawns()
    {
        Vector3 baseSpawn = mapGenerator.GetSpawnPosition();

        playerSpawn = baseSpawn + Vector3.left * spawnOffset + Vector3.up * spawnHeight;
        aiSpawn = baseSpawn + Vector3.right * spawnOffset + Vector3.up * spawnHeight;

        Debug.Log("Player Spawn: " + playerSpawn);
        Debug.Log("AI Spawn: " + aiSpawn);
    }

    private void ResetAgents()
    {
        ResetSingleAgent(playerAgent, playerSpawn);
        ResetSingleAgent(aiAgent, aiSpawn);
    }

    private void ResetSingleAgent(Transform agent, Vector3 position)
    {
        if (agent == null)
            return;

        agent.position = position;
        agent.rotation = Quaternion.identity;

        Rigidbody rb = agent.GetComponent<Rigidbody>();

        if (rb != null)
        {
            rb.velocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
    }

    private void SetAgentsMovementActive(bool active)
    {
        if (playerAgent != null)
        {
            LabyrinthAgent player = playerAgent.GetComponent<LabyrinthAgent>();

            if (player != null)
                player.enabled = active;
        }

        if (aiAgent != null)
        {
            LabyrinthAgent ai = aiAgent.GetComponent<LabyrinthAgent>();

            if (ai != null)
                ai.enabled = active;
        }
    }

    public void AgentReachedGoal(DemoParticipant participant)
    {
        if (!gameRunning)
            return;

        if (participant == DemoParticipant.Player && !playerFinished)
        {
            playerFinished = true;
            playerTimes[currentMapIndex - selectedMapIndex] = playerTime;

            Debug.Log("Spieler Ziel Map " + (currentMapIndex + 1) + ": " + playerTime);
        }

        if (participant == DemoParticipant.AI && !aiFinished)
        {
            aiFinished = true;
            aiTimes[currentMapIndex - selectedMapIndex] = aiTime;

            Debug.Log("KI Ziel Map " + (currentMapIndex + 1) + ": " + aiTime);
        }

        if (playerFinished && aiFinished)
        {
            EvaluateRound();
        }
    }

    public void RespawnAgent(DemoParticipant participant)
    {
        if (!gameRunning)
            return;

        if (participant == DemoParticipant.Player)
        {
            ResetSingleAgent(playerAgent, playerSpawn);
        }
        else
        {
            ResetSingleAgent(aiAgent, aiSpawn);
        }
    }

    private void EvaluateRound()
    {
        gameRunning = false;
        countdownRunning = false;

        SetAgentsMovementActive(false);

        int resultIndex = currentMapIndex - selectedMapIndex;

        if (playerTimes[resultIndex] < aiTimes[resultIndex])
        {
            playerWins++;
            Debug.Log("Map " + (currentMapIndex + 1) + ": Spieler gewinnt");
        }
        else
        {
            aiWins++;
            Debug.Log("Map " + (currentMapIndex + 1) + ": KI gewinnt");
        }

        currentMapIndex++;

        int lastMapIndexExclusive = selectedMapIndex + numberOfMaps;

        if (currentMapIndex >= lastMapIndexExclusive)
        {
            EndMatch();
        }
        else
        {
            StartRound(currentMapIndex);
        }
    }

    private void EndMatch()
    {
        gameRunning = false;
        countdownRunning = false;

        SetAgentsMovementActive(false);

        if (hudPanel != null)
            hudPanel.SetActive(false);

        if (resultPanel != null)
            resultPanel.SetActive(true);

        Debug.Log("MATCH BEENDET");
        Debug.Log("Spieler Siege: " + playerWins);
        Debug.Log("KI Siege: " + aiWins);

        for (int i = 0; i < numberOfMaps; i++)
        {
            Debug.Log(
                "Map " + (selectedMapIndex + i + 1) +
                " | Spieler: " + playerTimes[i].ToString("F2") +
                "s | KI: " + aiTimes[i].ToString("F2") + "s"
            );
        }

        if (playerWins > aiWins)
        {
            Debug.Log("GEWONNEN - Spieler darf Süßigkeiten nehmen!");

            if (audioSource != null && playerWinSound != null)
            {
                audioSource.PlayOneShot(playerWinSound);
            }
        }
        else
        {
            Debug.Log("KI gewinnt das Match.");
        }
    }

    public void AbortGame()
    {
        Debug.Log("Spiel wurde abgebrochen.");

        gameRunning = false;
        countdownRunning = false;

        SetAgentsMovementActive(false);

        if (startPanel != null)
            startPanel.SetActive(true);

        if (hudPanel != null)
            hudPanel.SetActive(false);

        if (resultPanel != null)
            resultPanel.SetActive(false);

        if (playerAgent != null)
            playerAgent.gameObject.SetActive(false);

        if (aiAgent != null)
            aiAgent.gameObject.SetActive(false);
    }
}