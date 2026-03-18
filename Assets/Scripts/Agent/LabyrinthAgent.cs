using Unity.MLAgents;
using Unity.MLAgents.Actuators;
using Unity.MLAgents.Sensors;
using UnityEngine;

public class LabyrinthAgent : Agent
{
    public override void OnEpisodeBegin()
    {
        // Wird spaeter implementiert: Agent-Position zuruecksetzen, Map laden etc.
    }

    public override void CollectObservations(VectorSensor sensor)
    {
        // Wird spaeter implementiert: Observations an das neuronale Netz uebergeben
    }

    public override void OnActionReceived(ActionBuffers actions)
    {
        // Wird spaeter implementiert: Bewegung, Sprung, Reward-Vergabe
    }

    public override void Heuristic(in ActionBuffers actionsOut)
    {
        // Wird spaeter implementiert: Manuelle Steuerung zum Testen
    }
}