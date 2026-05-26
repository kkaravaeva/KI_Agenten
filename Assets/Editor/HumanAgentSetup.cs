using UnityEditor;
using UnityEngine;

/// One-click tool to give the labyrinth agent a human appearance.
/// Menu: Tools/Agent/Mensch-Modell anwenden
public static class HumanAgentSetup
{
    [MenuItem("Tools/Agent/Mensch-Modell anwenden")]
    static void Apply()
    {
        var agent = Object.FindObjectOfType<LabyrinthAgent>();
        if (agent == null)
        {
            EditorUtility.DisplayDialog("Fehler",
                "Kein LabyrinthAgent in der Szene gefunden.\nBitte die Szene öffnen, die den Agenten enthält.", "OK");
            return;
        }

        if (agent.GetComponent<HumanAgentVisual>() == null)
            agent.gameObject.AddComponent<HumanAgentVisual>();

        EditorUtility.SetDirty(agent.gameObject);

        EditorUtility.DisplayDialog("Fertig",
            "✓ HumanAgentVisual hinzugefügt!\n\n" +
            "Beim nächsten Play-Mode wird das Mensch-Modell aufgebaut:\n" +
            "• Kopf mit Haaren\n" +
            "• Torso (blaues Hemd)\n" +
            "• Arme mit animiertem Schwingen\n" +
            "• Beine mit Schrittanimation\n" +
            "• Schuhe\n\n" +
            "Die Kapsel-Hitbox bleibt unverändert.", "OK");
    }
}
