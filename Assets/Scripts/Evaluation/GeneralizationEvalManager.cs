using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using TMPro;

/// <summary>
/// Orchestriert den Generalisierungstest: Drei Areale (MLP / LSTM / Transformer,
/// je EIN Agent) durchlaufen synchron dieselbe Held-out-Map-Sequenz. Pro Episode
/// erhalten alle Areale denselben Random-Seed, sodass Spawn- und Zielposition
/// über die Architekturen identisch gewürfelt werden — der Vergleich ist damit
/// paarweise fair. Die Agenten laufen im competitionMode (keine Rewards, kein
/// Curriculum, Steuerung ausschließlich durch diesen Manager) mit zugewiesenem
/// ONNX-Modell (Inference).
///
/// Ergebnisse: results/generalization/generalization_results.csv
/// (map;kategorie;episode;agent;erfolg;zeitSekunden)
/// </summary>
public class GeneralizationEvalManager : MonoBehaviour
{
    [System.Serializable]
    public class EvalArea
    {
        public string label;
        public LabyrinthAgent agent;
        public MapGenerator mapGenerator;

        [HideInInspector] public int   state;       // 0 = läuft, 1 = Erfolg, 2 = gescheitert
        [HideInInspector] public float finishTime;
        [HideInInspector] public int   successTotal;
        [HideInInspector] public int   attempted;   // gestartete Maps (für HUD)
        [HideInInspector] public bool  laneDone;
    }

    [Header("Areale (eines je Architektur)")]
    public EvalArea[] areas;

    [Header("Held-out-Maps (Reihenfolge = Testreihenfolge)")]
    public MapData[] maps;

    [Header("Protokoll")]
    public int episodesPerMap = 5;
    [Tooltip("Basis für die deterministischen Spawn/Goal-Seeds.")]
    public int randomSeedBase = 777;
    [Tooltip("Simulationsbeschleunigung. Zeitlimits gelten in simulierten Sekunden, das Step-Budget je Episode bleibt also unabhängig vom timeScale gleich.")]
    [Range(1f, 20f)] public float timeScale = 5f;

    [Header("Zeitlimits je Kartenkategorie (Sekunden, unskaliert)")]
    public float secondsEasy   = 45f;
    public float secondsMedium = 75f;
    public float secondsHard   = 110f;
    public float secondsGiant  = 180f;

    [Header("HUD (optional)")]
    public TMP_Text hudLabel;

    private readonly List<string> csvRows = new List<string>();
    private string _hudText = "Generalisierungstest — Play drücken";

    private IEnumerator Start()
    {
        if (areas == null || areas.Length == 0 || maps == null || maps.Length == 0)
        {
            Debug.LogError("[EvalManager] Areale oder Maps nicht konfiguriert.");
            yield break;
        }

        // Agenten in den kontrollierten Modus versetzen und Events verdrahten
        foreach (var area in areas)
        {
            var a = area;
            a.agent.competitionMode = true;
            a.agent.FreezeMovement();
            a.agent.onGoalReached += () => { if (a.state == 0) { a.state = 1; a.finishTime = Time.time; a.agent.FreezeMovement(); } };
            a.agent.onAgentDied   += () => { if (a.state == 0) { a.state = 2; a.finishTime = Time.time; a.agent.FreezeMovement(); } };
        }

        // Erfolgs-HUD wird jetzt per IMGUI (OnGUI) gezeichnet, damit es bündig unter
        // dem Architektur-Balken der Kamera liegt — das überlappende Canvas-Label aus.
        if (hudLabel != null) hudLabel.gameObject.SetActive(false);

        Time.timeScale = timeScale;
        csvRows.Add("map;kategorie;episode;agent;erfolg;zeitSekunden");
        yield return new WaitForSeconds(1f);   // ML-Agents-Initialisierung abwarten

        // Jede Architektur läuft UNABHÄNGIG durch alle Maps — kein gegenseitiges Warten.
        // Nach Erfolg/Tod/Timeout kommt für diese Bahn sofort die nächste Map.
        foreach (var area in areas)
            StartCoroutine(RunLane(area));

        // Warten, bis alle Bahnen fertig sind.
        yield return new WaitUntil(() =>
        {
            foreach (var area in areas) if (!area.laneDone) return false;
            return true;
        });

        WriteResults();
    }

    // Eine Architektur läuft eigenständig durch alle Held-out-Maps.
    private IEnumerator RunLane(EvalArea area)
    {
        for (int m = 0; m < maps.Length; m++)
        {
            var map = maps[m];
            string category = CategoryOf(map);
            float timeout = TimeoutFor(category);

            // Deterministischer Seed pro Map (gleiche Karte m ergibt für jede Architektur
            // dieselbe Spawn-/Zielwahl — nur eben zeitlich unabhängig statt synchron).
            Random.InitState(randomSeedBase * 1000 + m * 100);
            area.mapGenerator.GenerateMap(map);

            area.state = 0;
            area.agent.RefreshGoal();
            area.agent.RespawnAtStart();
            area.agent.UnfreezeMovement();
            area.attempted = m + 1;
            RefreshHud();

            float start = Time.time;
            yield return new WaitUntil(() => area.state != 0 || Time.time - start > timeout);

            bool success = area.state == 1;
            if (area.state == 0) { area.state = 2; area.agent.FreezeMovement(); }  // Timeout
            if (success) area.successTotal++;
            float t = success ? area.finishTime - start : timeout;
            csvRows.Add($"{map.name};{category};1;{area.label};{(success ? 1 : 0)};{t:F1}");

            RefreshHud();
            yield return new WaitForSeconds(0.25f);
        }
        area.laneDone = true;
        Debug.Log($"[EvalManager] {area.label} fertig: {area.successTotal}/{maps.Length} Maps bestanden.");
    }

    private static string CategoryOf(MapData map)
    {
        string n = map.name;
        if (n.Contains("Giant"))  return "Giant";
        if (n.Contains("Hard"))   return "Hard";
        if (n.Contains("Medium")) return "Medium";
        return "Easy";
    }

    private float TimeoutFor(string category) => category switch
    {
        "Giant"  => secondsGiant,
        "Hard"   => secondsHard,
        "Medium" => secondsMedium,
        _        => secondsEasy,
    };

    // Pro Architektur: bestandene / bisher gestartete Maps (Bahnen laufen unabhängig).
    private void RefreshHud()
    {
        var sb = new StringBuilder();
        sb.AppendLine($"Generalisierungstest — Held-out ({maps.Length} Maps)");
        foreach (var area in areas)
            sb.AppendLine($"{area.label}: {area.successTotal} / {area.attempted}");
        _hudText = sb.ToString();
        if (hudLabel != null) hudLabel.text = _hudText;
    }

    // Erfolgs-HUD bündig UNTER dem Architektur-Balken der Kamera (der bei y=10..110 liegt).
    private void OnGUI()
    {
        GUI.color = new Color(0f, 0f, 0f, 0.6f);
        GUI.DrawTexture(new Rect(10f, 116f, 560f, 132f), Texture2D.whiteTexture);
        GUI.color = Color.white;
        var style = new GUIStyle(GUI.skin.label) { fontSize = 20 };
        style.normal.textColor = Color.white;
        GUI.Label(new Rect(24f, 122f, 536f, 122f), _hudText, style);
    }

    private void WriteResults()
    {
        string dir = Path.Combine(Application.dataPath, "..", "results", "generalization");
        Directory.CreateDirectory(dir);
        string path = Path.Combine(dir, "generalization_results.csv");
        File.WriteAllLines(path, csvRows, Encoding.UTF8);

        var sb = new StringBuilder("[EvalManager] TEST ABGESCHLOSSEN — Erfolge gesamt: ");
        foreach (var area in areas)
            sb.Append($"{area.label}={area.successTotal}/{maps.Length}  ");
        sb.Append($"| CSV: {path}");
        Debug.Log(sb.ToString());
        _hudText = sb.ToString();
        if (hudLabel != null) hudLabel.text = _hudText;

        // Headless-/Batch-Betrieb: Player nach Abschluss beenden (im Editor wirkungslos)
        Application.Quit();
    }
}
