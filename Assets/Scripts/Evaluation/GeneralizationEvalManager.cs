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

        Time.timeScale = timeScale;
        csvRows.Add("map;kategorie;episode;agent;erfolg;zeitSekunden");
        yield return new WaitForSeconds(1f);   // ML-Agents-Initialisierung abwarten

        for (int m = 0; m < maps.Length; m++)
        {
            var map = maps[m];
            string category = CategoryOf(map);
            float timeout = TimeoutFor(category);

            for (int ep = 0; ep < episodesPerMap; ep++)
            {
                int seed = randomSeedBase * 1000 + m * 100 + ep;

                // Alle Areale erhalten dieselbe Map und denselben Seed →
                // identische Spawn-/Zielpositionen über die Architekturen.
                foreach (var area in areas)
                {
                    Random.InitState(seed);
                    area.mapGenerator.GenerateMap(map);
                }
                foreach (var area in areas)
                {
                    area.state = 0;
                    area.agent.RefreshGoal();
                    area.agent.RespawnAtStart();
                    area.agent.UnfreezeMovement();
                }

                float start = Time.time;
                yield return new WaitUntil(() =>
                    AllDone() || Time.time - start > timeout);

                foreach (var area in areas)
                {
                    bool success = area.state == 1;
                    if (area.state == 0) { area.state = 2; area.agent.FreezeMovement(); }  // Timeout
                    if (success) area.successTotal++;
                    float t = success ? area.finishTime - start : timeout;
                    csvRows.Add($"{map.name};{category};{ep + 1};{area.label};{(success ? 1 : 0)};{t:F1}");
                }

                UpdateHud(m, ep);
                yield return new WaitForSeconds(0.25f);
            }
            Debug.Log($"[EvalManager] Map {m + 1}/{maps.Length} ({map.name}) abgeschlossen. " +
                      string.Join(" | ", System.Array.ConvertAll(areas, x => $"{x.label}: {x.successTotal}")));
        }

        WriteResults();
    }

    private bool AllDone()
    {
        foreach (var area in areas)
            if (area.state == 0) return false;
        return true;
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

    private void UpdateHud(int mapIdx, int epIdx)
    {
        if (hudLabel == null) return;
        var sb = new StringBuilder();
        sb.AppendLine($"Generalisierungstest — Map {mapIdx + 1}/{maps.Length}, Episode {epIdx + 1}/{episodesPerMap}");
        foreach (var area in areas)
            sb.AppendLine($"{area.label}: {area.successTotal} Erfolge");
        hudLabel.text = sb.ToString();
    }

    private void WriteResults()
    {
        string dir = Path.Combine(Application.dataPath, "..", "results", "generalization");
        Directory.CreateDirectory(dir);
        string path = Path.Combine(dir, "generalization_results.csv");
        File.WriteAllLines(path, csvRows, Encoding.UTF8);

        var sb = new StringBuilder("[EvalManager] TEST ABGESCHLOSSEN — Erfolge gesamt: ");
        foreach (var area in areas)
            sb.Append($"{area.label}={area.successTotal}/{maps.Length * episodesPerMap}  ");
        sb.Append($"| CSV: {path}");
        Debug.Log(sb.ToString());
        if (hudLabel != null) hudLabel.text = sb.ToString();

        // Headless-/Batch-Betrieb: Player nach Abschluss beenden (im Editor wirkungslos)
        Application.Quit();
    }
}
