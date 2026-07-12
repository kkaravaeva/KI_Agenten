#if UNITY_EDITOR
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Unity.MLAgents.Policies;

/// <summary>Diagnose: Hierarchie der Trainingsszene (Areale, Agenten, MapGeneratoren) loggen.</summary>
public static class SceneProbe
{
    public static void Probe()
    {
        EditorSceneManager.OpenScene("Assets/Scenes/Training Area.unity", OpenSceneMode.Single);

        var gens = Object.FindObjectsByType<MapGenerator>(FindObjectsInactive.Include, FindObjectsSortMode.None);
        Debug.Log($"[SceneProbe] MapGeneratoren: {gens.Length}");
        foreach (var g in gens)
            Debug.Log($"[SceneProbe] MapGen '{g.name}' root='{g.transform.root.name}' pos={g.transform.position}");

        var agents = Object.FindObjectsByType<LabyrinthAgent>(FindObjectsInactive.Include, FindObjectsSortMode.None);
        Debug.Log($"[SceneProbe] Agenten: {agents.Length}");
        foreach (var group in agents.GroupBy(a => a.transform.root.name).OrderBy(g => g.Key))
        {
            var names = group.Select(a =>
            {
                var bp = a.GetComponent<BehaviorParameters>();
                return $"{a.name}({(bp != null ? bp.BehaviorName : "?")}, mapGen={(a.mapGenerator != null ? a.mapGenerator.transform.root.name + "/" + a.mapGenerator.name : "null")})";
            });
            Debug.Log($"[SceneProbe] Root '{group.Key}': {string.Join(", ", names)}");
        }
    }
}
#endif
