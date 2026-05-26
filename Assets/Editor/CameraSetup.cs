using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class CameraSetup
{
    const string EgoCamName   = "EgoCamera";
    const string DroneCamName = "DroneCamera";
    const string SwitcherTag  = "MainCamera";

    [MenuItem("Tools/Kamera/Setup einrichten")]
    static void Setup()
    {
        // ── 1. Ego-Kamera ────────────────────────────────────────────────────
        var agent = FindAgent();
        if (agent == null)
        {
            Debug.LogError("[CameraSetup] Kein LabyrinthAgent in der Szene gefunden.");
            return;
        }

        var egoGo = FindOrCreate(EgoCamName, agent.transform);
        var egoCam = GetOrAddComponent<Camera>(egoGo);
        egoCam.fieldOfView = 80f;
        egoGo.transform.localPosition = new Vector3(0f, 0.4f, 0.2f);
        egoGo.transform.localRotation = Quaternion.identity;
        egoCam.enabled = false;
        EditorUtility.SetDirty(egoGo);

        // ── 2. Drohnen-Kamera ────────────────────────────────────────────────
        var droneGo = FindOrCreateRoot(DroneCamName);
        var droneCam = GetOrAddComponent<Camera>(droneGo);
        droneCam.orthographic = true;
        droneCam.orthographicSize = 20f;
        droneCam.nearClipPlane = 1f;
        droneCam.farClipPlane = 100f;
        droneGo.transform.position = new Vector3(
            agent.transform.position.x,
            30f,
            agent.transform.position.z);
        droneGo.transform.rotation = Quaternion.Euler(90f, 0f, 0f);

        var follow = GetOrAddComponent<DroneFollow>(droneGo);
        follow.target       = agent.transform;
        follow.height       = 30f;
        follow.mapGenerator = agent.GetComponentInParent<MapGenerator>()
                           ?? Object.FindObjectOfType<MapGenerator>();
        droneCam.enabled = true;
        EditorUtility.SetDirty(droneGo);

        // ── 3. CameraSwitcher auf Main Camera ────────────────────────────────
        var mainCamGo = GameObject.FindGameObjectWithTag(SwitcherTag);
        if (mainCamGo == null)
        {
            Debug.LogError("[CameraSetup] Kein GameObject mit Tag 'MainCamera' gefunden.");
            return;
        }

        // ThirdPersonCamera deaktivieren
        var tpc = mainCamGo.GetComponent<ThirdPersonCamera>();
        if (tpc != null)
        {
            var mainCam = mainCamGo.GetComponent<Camera>();
            if (mainCam != null) mainCam.enabled = false;
        }

        var switcher = GetOrAddComponent<CameraSwitcher>(mainCamGo);
        switcher.egoCamera         = egoCam;
        switcher.droneCamera       = droneCam;
        switcher.thirdPersonCamera = mainCamGo.GetComponent<Camera>();
        switcher.startMode         = CameraSwitcher.Mode.Drone;
        EditorUtility.SetDirty(mainCamGo);

        // ── Szene speichern ──────────────────────────────────────────────────
        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());

        Debug.Log("[CameraSetup] Fertig. Tab = Kamera wechseln.");
    }

    [MenuItem("Tools/Kamera/Setup entfernen")]
    static void Remove()
    {
        // Ego-Kamera entfernen
        var agent = FindAgent();
        if (agent != null)
        {
            var egoGo = agent.transform.Find(EgoCamName);
            if (egoGo != null) { Undo.DestroyObjectImmediate(egoGo.gameObject); }
        }

        // Drohnen-Kamera entfernen
        var droneGo = GameObject.Find(DroneCamName);
        if (droneGo != null) Undo.DestroyObjectImmediate(droneGo);

        // CameraSwitcher entfernen, Main Camera wieder aktivieren
        var mainCamGo = GameObject.FindGameObjectWithTag(SwitcherTag);
        if (mainCamGo != null)
        {
            var sw = mainCamGo.GetComponent<CameraSwitcher>();
            if (sw != null) Undo.DestroyObjectImmediate(sw);
            var cam = mainCamGo.GetComponent<Camera>();
            if (cam != null) { cam.enabled = true; EditorUtility.SetDirty(mainCamGo); }
        }

        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
        EditorSceneManager.SaveScene(SceneManager.GetActiveScene());
        Debug.Log("[CameraSetup] Setup entfernt.");
    }

    // ── Hilfsmethoden ─────────────────────────────────────────────────────────

    static LabyrinthAgent FindAgent()
    {
        // Bevorzuge den Agent in der ersten aktiven TrainingArea
        foreach (var area in Object.FindObjectsOfType<Transform>())
        {
            if (area.parent == null && area.name.StartsWith("TrainingArea") && area.gameObject.activeSelf)
            {
                var a = area.GetComponentInChildren<LabyrinthAgent>(false);
                if (a != null) return a;
            }
        }
        return Object.FindObjectOfType<LabyrinthAgent>();
    }

    static GameObject FindOrCreate(string name, Transform parent)
    {
        var existing = parent.Find(name);
        if (existing != null) return existing.gameObject;
        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        Undo.RegisterCreatedObjectUndo(go, $"Create {name}");
        return go;
    }

    static GameObject FindOrCreateRoot(string name)
    {
        var existing = GameObject.Find(name);
        if (existing != null) return existing;
        var go = new GameObject(name);
        Undo.RegisterCreatedObjectUndo(go, $"Create {name}");
        return go;
    }

    static T GetOrAddComponent<T>(GameObject go) where T : Component
    {
        var c = go.GetComponent<T>();
        return c != null ? c : go.AddComponent<T>();
    }
}
