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

    [Header("Settings")]
    public int selectedMapIndex = 0;
    public float spawnOffset = 0.6f;
    public float spawnHeight = 0.6f;

    private Vector3 playerSpawn;
    private Vector3 aiSpawn;

    private float playerTime;
    private float aiTime;

    private bool gameRunning;
    private bool playerFinished;
    private bool aiFinished;

    private void Update()
    {
        if (!gameRunning)
            return;

        if (!playerFinished)
            playerTime += Time.deltaTime;

        if (!aiFinished)
            aiTime += Time.deltaTime;
    }

    public void StartGame()
    {
        Debug.Log("STARTGAME WURDE GEKLICKT");

        startPanel.SetActive(false);
        hudPanel.SetActive(true);
        resultPanel.SetActive(false);

        selectedMapIndex = Mathf.Clamp(selectedMapIndex, 0, mapGenerator.mapLayouts.Length - 1);

        mapGenerator.selectionMode = MapSelectionMode.Fixed;
        mapGenerator.selectedLayoutIndex = selectedMapIndex;
        mapGenerator.GenerateSelectedMap();

        SetupSpawns();
        ResetAgents();

        playerTime = 0f;
        aiTime = 0f;
        playerFinished = false;
        aiFinished = false;
        gameRunning = true;

        Debug.Log("Demo-Spiel gestartet.");
   }

    private void SetupSpawns()
    {
        Vector3 baseSpawn = mapGenerator.GetSpawnPosition();

        playerSpawn = baseSpawn + Vector3.left * spawnOffset + Vector3.up * spawnHeight;
        aiSpawn = baseSpawn + Vector3.right * spawnOffset + Vector3.up * spawnHeight;
    }

    private void ResetAgents()
    {
        ResetSingleAgent(playerAgent, playerSpawn);
        ResetSingleAgent(aiAgent, aiSpawn);
    }

    private void ResetSingleAgent(Transform agent, Vector3 position)
    {
        agent.position = position;
        agent.rotation = Quaternion.identity;

        Rigidbody rb = agent.GetComponent<Rigidbody>();

        if (rb != null)
        {
            rb.velocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
    }

    public void AgentReachedGoal(DemoParticipant participant)
    {
        if (!gameRunning)
            return;

        if (participant == DemoParticipant.Player)
        {
            playerFinished = true;
            Debug.Log("Spieler ist im Ziel. Zeit: " + playerTime);
        }
        else
        {
            aiFinished = true;
            Debug.Log("KI ist im Ziel. Zeit: " + aiTime);
        }

        if (playerFinished && aiFinished)
        {
            EndGame();
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

    private void EndGame()
    {
        gameRunning = false;

        if (playerTime < aiTime)
            Debug.Log("Du gewinnst!");
        else
            Debug.Log("KI gewinnt!");
    }
}