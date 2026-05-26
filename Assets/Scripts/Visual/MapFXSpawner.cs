using UnityEngine;

/// Listens to MapGenerator.OnMapGenerated and attaches visual FX to lava/goal tiles.
/// Add this component to the same GameObject as MapGenerator.
[RequireComponent(typeof(MapGenerator))]
public class MapFXSpawner : MonoBehaviour
{
    MapGenerator _mapGen;

    void Awake()
    {
        _mapGen = GetComponent<MapGenerator>();
        _mapGen.OnMapGenerated += OnMapGenerated;
    }

    void OnDestroy()
    {
        if (_mapGen != null) _mapGen.OnMapGenerated -= OnMapGenerated;
    }

    void OnMapGenerated()
    {
        AttachGoalBeacon();
        NotifyAgentAudio();
    }

    void NotifyAgentAudio()
    {
        bool hasLava = false;
        var mapRoot = _mapGen.transform.Find("MapRoot");
        if (mapRoot != null)
            for (int i = 0; i < mapRoot.childCount; i++)
                if (mapRoot.GetChild(i).name.StartsWith("Lava_")) { hasLava = true; break; }

        var agentAudio = FindObjectOfType<AgentAudio>();
        if (agentAudio != null) agentAudio.NotifyLavaPresent(hasLava);
    }

    void AttachGoalBeacon()
    {
        // Goal is spawned as "RuntimeGoal_x_y" by MapGenerator
        var goalTransform = _mapGen.GetGoalTransform();
        if (goalTransform == null) return;

        var go = goalTransform.gameObject;
        // Beacon on the visual object (or its first child if compound)
        var target = go.GetComponentInChildren<Renderer>() != null
            ? go.GetComponentInChildren<Renderer>().gameObject
            : go;

        if (!target.TryGetComponent<GoalBeacon>(out _))
            target.AddComponent<GoalBeacon>();
    }
}
