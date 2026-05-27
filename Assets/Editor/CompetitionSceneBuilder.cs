#if UNITY_EDITOR
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;
using Unity.MLAgents.Policies;

/// <summary>
/// Erstellt die Competition-Szene auf Basis von Transformer_Test_V2.unity.
///
/// Menü: Tools / Competition / Build Competition Scene
///
/// Vorgehen:
///   1.  Transformer_Test_V2.unity → Competition.unity kopieren  (Landschaft/Licht/Skybox bleibt)
///   2.  15 von 16 TrainingArea-Instanzen entfernen
///   3.  LSTM-Modell auf den KI-Agenten setzen
///   4.  Kameras auf den Spieler umlenken:
///         – EgoCamera   → wird Kind des Spielers (local pos = Kopfhöhe)
///         – DroneCamera → DroneFollow.target  = Spieler
///         – FrontCamera → FrontFollowCamera.target = Spieler
///         – CameraSwitcher startet im Ego-Modus (Tab = wechseln)
///   5.  Player-GameObject hinzufügen (PlayerController + HumanAgentVisual + Marker)
///   6.  CompetitionManager mit den 5 Hand-crafted Maps verdrahten
///   7.  Canvas / CompetitionUI mit neuem HUD aufbauen
/// </summary>
public static class CompetitionSceneBuilder
{
    const string SOURCE_SCENE = "Assets/Scenes/Transformer_Test_V2.unity";
    const string TARGET_SCENE = "Assets/Scenes/Competition.unity";
    // Ausgewählte Medium-Maps für den Wettkampf (eine pro Runde)
    static readonly string[] MAP_PATHS = new[]
    {
        "Assets/Layouts/Procedural/Layout_P_Medium_047.asset",
        "Assets/Layouts/Procedural/Layout_P_Medium_049.asset",
        "Assets/Layouts/Procedural/Layout_P_Medium_057.asset",
        "Assets/Layouts/Procedural/Layout_P_Medium_138.asset",
    };

    // ═══════════════════════════════════════════════════════════════════════════
    [MenuItem("Tools/Competition/Build Competition Scene")]
    public static void BuildCompetitionScene()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            return;

        // ── 1. Quellszene duplizieren ──────────────────────────────────────────
        if (string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(SOURCE_SCENE)))
        {
            EditorUtility.DisplayDialog("Fehler",
                "Quellszene nicht gefunden:\n" + SOURCE_SCENE, "OK");
            return;
        }

        if (!string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(TARGET_SCENE)))
            AssetDatabase.DeleteAsset(TARGET_SCENE);

        if (!AssetDatabase.CopyAsset(SOURCE_SCENE, TARGET_SCENE))
        {
            EditorUtility.DisplayDialog("Fehler",
                "Szene konnte nicht kopiert werden:\n" + TARGET_SCENE, "OK");
            return;
        }
        AssetDatabase.Refresh();

        var scene = EditorSceneManager.OpenScene(TARGET_SCENE, OpenSceneMode.Single);

        // ── 2. Überflüssige TrainingAreas entfernen ────────────────────────────
        var allAgents = Object.FindObjectsOfType<LabyrinthAgent>(true);

        if (allAgents.Length == 0)
        {
            Debug.LogError("[CompetitionSceneBuilder] Kein LabyrinthAgent in Quellszene!");
            return;
        }

        var keepAgent = allAgents
            .OrderBy(a => a.transform.position.sqrMagnitude)
            .First();

        var keepRoot = keepAgent.transform.parent != null
            ? keepAgent.transform.parent.gameObject
            : keepAgent.gameObject;

        int removed = 0;
        foreach (var agent in allAgents)
        {
            if (agent == keepAgent) continue;
            var taRoot = agent.transform.parent != null
                ? agent.transform.parent.gameObject
                : agent.gameObject;
            if (taRoot != keepRoot)
            {
                Object.DestroyImmediate(taRoot);
                removed++;
            }
        }
        Debug.Log($"[CompetitionSceneBuilder] {removed} TrainingArea(s) entfernt.");

        // ── 3. MapGenerator konfigurieren ──────────────────────────────────────
        var mapGen = keepRoot.GetComponentInChildren<MapGenerator>();
        if (mapGen == null)
        {
            Debug.LogError("[CompetitionSceneBuilder] Kein MapGenerator im beibehaltenen TrainingArea!");
            return;
        }

        mapGen.autoFrameCamera = false;
        mapGen.trainingMode    = TrainingMode.Standard;

        if (keepAgent.mapGenerator == null)
            keepAgent.mapGenerator = mapGen;

        // ── 4. ML-Agents deaktivieren, ScriptedAIAgent einsetzen ─────────────
        var labAgent = keepAgent.GetComponent<LabyrinthAgent>();
        if (labAgent != null) { labAgent.enabled = false; EditorUtility.SetDirty(labAgent); }

        var bp = keepAgent.GetComponent<BehaviorParameters>();
        if (bp != null)    { bp.enabled = false;    EditorUtility.SetDirty(bp); }

        var scripted = keepAgent.GetComponent<ScriptedAIAgent>()
                       ?? keepAgent.gameObject.AddComponent<ScriptedAIAgent>();
        scripted.mapGenerator = mapGen;
        EditorUtility.SetDirty(scripted);

        // HumanAgentVisual für den KI-Agenten (Optik)
        if (keepAgent.GetComponent<HumanAgentVisual>() == null)
            keepAgent.gameObject.AddComponent<HumanAgentVisual>();

        // ── 5. Spieler hinzufügen ──────────────────────────────────────────────
        var playerGO = MakePhysicsBody("Player");
        playerGO.transform.position = keepAgent.transform.position + new Vector3(0.8f, 0f, 0f);

        var playerCtrl        = playerGO.AddComponent<PlayerController>();
        playerCtrl.mapGenerator = mapGen;
        playerGO.AddComponent<HumanAgentVisual>();
        playerGO.AddComponent<PlayerMarkerVisual>();

        // ── 6. Kameras auf den Spieler umlenken (Ego-Start) ────────────────────
        WireCamerasToPlayer(playerGO, mapGen);

        // ── 7. Maps laden ──────────────────────────────────────────────────────
        var maps = new MapData[MAP_PATHS.Length];
        int loadedMaps = 0;
        for (int i = 0; i < MAP_PATHS.Length; i++)
        {
            maps[i] = AssetDatabase.LoadAssetAtPath<MapData>(MAP_PATHS[i]);
            if (maps[i] != null)
                loadedMaps++;
            else
                Debug.LogWarning("[CompetitionSceneBuilder] Map nicht gefunden: " + MAP_PATHS[i]);
        }

        // ── 8. CompetitionManager ──────────────────────────────────────────────
        var mgrGO = new GameObject("CompetitionManager");
        var mgr   = mgrGO.AddComponent<CompetitionManager>();
        mgr.aiAgent         = scripted;
        mgr.humanPlayer     = playerCtrl;
        mgr.mapGenerator    = mapGen;
        mgr.competitionMaps = maps;

        // ── 9. Canvas + UI ─────────────────────────────────────────────────────
        foreach (var old in Object.FindObjectsOfType<CompetitionUI>())  Object.DestroyImmediate(old.gameObject);
        foreach (var old in Object.FindObjectsOfType<Canvas>())         Object.DestroyImmediate(old.gameObject);
        foreach (var old in Object.FindObjectsOfType<EventSystem>())    Object.DestroyImmediate(old.gameObject);

        var canvasGO = new GameObject("Canvas");
        var canvas   = canvasGO.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 10;
        var scaler = canvasGO.AddComponent<CanvasScaler>();
        scaler.uiScaleMode         = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1920, 1080);
        scaler.matchWidthOrHeight  = 0.5f;
        canvasGO.AddComponent<GraphicRaycaster>();

        // ── HUD-Bar (volle Breite, oben, 116px) ──────────────────────────────────
        //
        //  Jede Sektion ist in ZWEI exakt getrennte Zeilen aufgeteilt:
        //    Oben  (anchorMin.y = 0.52 … anchorMax.y = 1.0):  Name
        //    Unten (anchorMin.y = 0.0  … anchorMax.y = 0.48): Dots
        //  Zwischen beiden Hälften liegt immer ein Leerraum von 4 % der Balkenhöhe
        //  → Überlappen ist architektonisch ausgeschlossen.
        //
        var hudBar = MakePanel(canvasGO.transform, "HUDBar", new Color(0f, 0f, 0f, 0.78f));
        {
            var rt       = hudBar.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0f, 1f);
            rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot     = new Vector2(0.5f, 1f);
            rt.anchoredPosition = Vector2.zero;
            rt.sizeDelta = new Vector2(0f, 116f);
            hudBar.GetComponent<Image>().raycastTarget = false;
        }

        // ── Spieler-Sektion (links, 0–33 %) ──────────────────────────────────
        var playerSection = MakePanel(hudBar.transform, "PlayerSection", Color.clear);
        SetStretch(playerSection, 0f, 0f, 0.33f, 1f, 0, 0, 0, 0);

        // Name: obere Hälfte der Sektion, links ausgerichtet
        var playerNameLbl = MakeStretchLabel(
            playerSection.transform, "PlayerNameLabel", "<b>DU</b>",
            minX: 0f,   minY: 0.50f,   maxX: 0.80f, maxY: 1.0f,
            padL: 18f,  padB: 2f,      padR: 4f,    padT: 8f,
            fontSize: 26f, align: TextAlignmentOptions.BottomLeft);
        playerNameLbl.GetComponent<TextMeshProUGUI>().color = new Color(0.98f, 0.80f, 0.15f);

        // Dots: untere Hälfte der Sektion, links ausgerichtet
        var playerDotsLbl = MakeStretchLabel(
            playerSection.transform, "PlayerDotsLabel", "",
            minX: 0f,   minY: 0f,      maxX: 1.0f,  maxY: 0.48f,
            padL: 14f,  padB: 6f,      padR: 6f,    padT: 2f,
            fontSize: 20f, align: TextAlignmentOptions.MidlineLeft);

        // ── Mitte-Sektion (33–67 %) ───────────────────────────────────────────
        var centerSection = MakePanel(hudBar.transform, "CenterSection", Color.clear);
        SetStretch(centerSection, 0.33f, 0f, 0.67f, 1f, 0, 0, 0, 0);

        // Runde: linke Hälfte, vertikal zentriert
        var roundLbl = MakeStretchLabel(
            centerSection.transform, "RoundLabel", "<size=70%>RUNDE</size>\n<b>– / 5</b>",
            minX: 0f,   minY: 0f,      maxX: 0.50f, maxY: 1.0f,
            padL: 4f,   padB: 4f,      padR: 8f,    padT: 4f,
            fontSize: 22f, align: TextAlignmentOptions.Center);

        // Trennstrich in der Mitte
        var divider = MakePanel(centerSection.transform, "Divider",
            new Color(1f, 1f, 1f, 0.20f));
        SetStretch(divider, 0.5f, 0.10f, 0.5f, 0.90f, -1, 0, 1, 0);

        // Zeit: rechte Hälfte, vertikal zentriert
        var timerLbl = MakeStretchLabel(
            centerSection.transform, "TimerLabel", "<size=70%>ZEIT</size>\n<b>0:00</b>",
            minX: 0.50f, minY: 0f,     maxX: 1.0f,  maxY: 1.0f,
            padL: 8f,    padB: 4f,     padR: 4f,    padT: 4f,
            fontSize: 22f, align: TextAlignmentOptions.Center);

        // ── KI-Sektion (rechts, 67–100 %) ────────────────────────────────────
        var aiSection = MakePanel(hudBar.transform, "AISection", Color.clear);
        SetStretch(aiSection, 0.67f, 0f, 1.0f, 1f, 0, 0, 0, 0);

        // Name: obere Hälfte der Sektion, rechts ausgerichtet
        var aiNameLbl = MakeStretchLabel(
            aiSection.transform, "AINameLabel", "<b>KI</b>",
            minX: 0.20f, minY: 0.50f,  maxX: 1.0f,  maxY: 1.0f,
            padL: 4f,    padB: 2f,     padR: 18f,   padT: 8f,
            fontSize: 26f, align: TextAlignmentOptions.BottomRight);
        aiNameLbl.GetComponent<TextMeshProUGUI>().color = new Color(0.95f, 0.30f, 0.25f);

        // Dots: untere Hälfte der Sektion, rechts ausgerichtet
        var aiDotsLbl = MakeStretchLabel(
            aiSection.transform, "AIDotsLabel", "",
            minX: 0f,    minY: 0f,     maxX: 1.0f,  maxY: 0.48f,
            padL: 6f,    padB: 6f,     padR: 14f,   padT: 2f,
            fontSize: 20f, align: TextAlignmentOptions.MidlineRight);

        // ── Ziel-Flash ─────────────────────────────────────────────────────────
        var flashPanel = MakePanel(canvasGO.transform, "GoalFlashPanel", Color.clear);
        {
            var rt       = flashPanel.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot     = new Vector2(0.5f, 0.5f);
            rt.anchoredPosition = new Vector2(0f, 100f);
            rt.sizeDelta = new Vector2(960f, 110f);
        }
        flashPanel.SetActive(false);

        var flashLbl = MakeLabel(flashPanel.transform, "GoalFlashLabel", "",
            pivot:    new Vector2(0.5f, 0.5f),
            anchor:   new Vector2(0.5f, 0.5f),
            pos:      Vector2.zero,
            size:     new Vector2(960f, 110f),
            fontSize: 58f, align: TextAlignmentOptions.Center);

        // ── Countdown-Panel ────────────────────────────────────────────────────
        var cdPanel = MakePanel(canvasGO.transform, "CountdownPanel",
            new Color(0f, 0f, 0f, 0.70f));
        StretchFull(cdPanel);
        cdPanel.SetActive(false);

        var cdLabel = MakeLabel(cdPanel.transform, "CountdownLabel", "5",
            pivot:    new Vector2(0.5f, 0.5f),
            anchor:   new Vector2(0.5f, 0.5f),
            pos:      Vector2.zero,
            size:     new Vector2(360f, 280f),
            fontSize: 160f);

        // ── Runden-Ergebnis-Panel ──────────────────────────────────────────────
        var rrPanel = MakePanel(canvasGO.transform, "RoundResultPanel",
            new Color(0f, 0f, 0f, 0.85f));
        CenterPanel(rrPanel, new Vector2(860f, 320f));
        rrPanel.SetActive(false);

        var rrHeadline = MakeLabel(rrPanel.transform, "ResultHeadline", "Runden-Ergebnis",
            pivot:    new Vector2(0.5f, 1f),
            anchor:   new Vector2(0.5f, 1f),
            pos:      new Vector2(0f, -60f),
            size:     new Vector2(800f, 95f),
            fontSize: 52f);

        var rrTimes = MakeLabel(rrPanel.transform, "ResultTimesLabel", "Du: 0:42     KI: 0:55",
            pivot:    new Vector2(0.5f, 0.5f),
            anchor:   new Vector2(0.5f, 0.5f),
            pos:      new Vector2(0f, 30f),
            size:     new Vector2(800f, 60f),
            fontSize: 30f);

        var rrScore = MakeLabel(rrPanel.transform, "ScoreAfterLabel", "Stand: 0 : 0",
            pivot:    new Vector2(0.5f, 0f),
            anchor:   new Vector2(0.5f, 0f),
            pos:      new Vector2(0f, 40f),
            size:     new Vector2(800f, 60f),
            fontSize: 30f);

        // ── Game-Over-Panel ────────────────────────────────────────────────────
        var goPanel = MakePanel(canvasGO.transform, "GameOverPanel",
            new Color(0f, 0f, 0f, 0.90f));
        CenterPanel(goPanel, new Vector2(960f, 450f));
        goPanel.SetActive(false);

        var goHeadline = MakeLabel(goPanel.transform, "GameOverHeadline", "Spielende!",
            pivot:    new Vector2(0.5f, 1f),
            anchor:   new Vector2(0.5f, 1f),
            pos:      new Vector2(0f, -80f),
            size:     new Vector2(900f, 105f),
            fontSize: 64f);

        var goScore = MakeLabel(goPanel.transform, "FinalScoreLabel", "Du 0  :  0 KI",
            pivot:    new Vector2(0.5f, 0.5f),
            anchor:   new Vector2(0.5f, 0.5f),
            pos:      new Vector2(0f, 35f),
            size:     new Vector2(720f, 95f),
            fontSize: 54f);

        var restartBtn = MakeButton(goPanel.transform, "RestartButton", "Nochmal spielen",
            pivot:    new Vector2(0.5f, 0f),
            anchor:   new Vector2(0.5f, 0f),
            pos:      new Vector2(0f, 55f),
            size:     new Vector2(340f, 68f));

        // ── EventSystem ────────────────────────────────────────────────────────
        var evsGO = new GameObject("EventSystem");
        evsGO.AddComponent<EventSystem>();
        evsGO.AddComponent<StandaloneInputModule>();

        // ── CompetitionUI verdrahten ───────────────────────────────────────────
        var uiGO   = new GameObject("CompetitionUI");
        var compUI = uiGO.AddComponent<CompetitionUI>();

        compUI.playerNameLabel       = playerNameLbl.GetComponent<TextMeshProUGUI>();
        compUI.playerDotsLabel       = playerDotsLbl.GetComponent<TextMeshProUGUI>();
        compUI.roundLabel            = roundLbl.GetComponent<TextMeshProUGUI>();
        compUI.timerLabel            = timerLbl.GetComponent<TextMeshProUGUI>();
        compUI.aiDotsLabel           = aiDotsLbl.GetComponent<TextMeshProUGUI>();
        compUI.aiNameLabel           = aiNameLbl.GetComponent<TextMeshProUGUI>();
        compUI.goalFlashPanel        = flashPanel;
        compUI.goalFlashLabel        = flashLbl.GetComponent<TextMeshProUGUI>();
        compUI.countdownPanel        = cdPanel;
        compUI.countdownLabel        = cdLabel.GetComponent<TextMeshProUGUI>();
        compUI.roundResultPanel      = rrPanel;
        compUI.resultHeadlineLabel   = rrHeadline.GetComponent<TextMeshProUGUI>();
        compUI.resultTimesLabel      = rrTimes.GetComponent<TextMeshProUGUI>();
        compUI.scoreAfterLabel       = rrScore.GetComponent<TextMeshProUGUI>();
        compUI.gameOverPanel         = goPanel;
        compUI.gameOverHeadlineLabel = goHeadline.GetComponent<TextMeshProUGUI>();
        compUI.finalScoreLabel       = goScore.GetComponent<TextMeshProUGUI>();
        compUI.restartButton         = restartBtn.GetComponent<Button>();

        // ── Dirty + Speichern ──────────────────────────────────────────────────
        EditorUtility.SetDirty(keepAgent);
        EditorUtility.SetDirty(mapGen);
        EditorUtility.SetDirty(playerCtrl);
        EditorUtility.SetDirty(mgr);
        EditorUtility.SetDirty(compUI);
        EditorSceneManager.MarkSceneDirty(scene);

        EditorSceneManager.SaveScene(scene, TARGET_SCENE);
        AssetDatabase.Refresh();

        Debug.Log("[CompetitionSceneBuilder] ✓ Szene gespeichert: " + TARGET_SCENE);
        EditorUtility.DisplayDialog(
            "Competition-Szene erstellt!",
            "✓  " + TARGET_SCENE + "\n\n" +
            $"• {removed} überflüssige TrainingArea(s) entfernt\n" +
            $"• {loadedMaps}/{MAP_PATHS.Length} Maps geladen (Medium 47/49/50/57/138)\n" +
            "• KI: ScriptedAIAgent (naturalistisch, ~80%-trainiert-Optik)\n" +
            "• Kamera-Startmodus: Ego (Tab wechselt Drohne/Ego/Front)\n" +
            "• HUD: Stretch-Anchors – Name oben / Punkte unten, kein Überlappen\n\n" +
            "→  Play drücken und spielen!",
            "OK");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Kamera-Setup: alle 3 Kameramodi auf den Spieler umlenken, Ego-Start
    // ─────────────────────────────────────────────────────────────────────────
    static void WireCamerasToPlayer(GameObject playerGO, MapGenerator mapGen)
    {
        var switcher = Object.FindObjectOfType<CameraSwitcher>(true);
        if (switcher == null)
        {
            Debug.LogWarning("[CompetitionSceneBuilder] CameraSwitcher nicht gefunden.");
            return;
        }
        switcher.enabled = true;

        // DroneCamera
        if (switcher.droneCamera != null)
        {
            var df = switcher.droneCamera.GetComponent<DroneFollow>()
                     ?? switcher.droneCamera.gameObject.AddComponent<DroneFollow>();
            df.target       = playerGO.transform;
            df.mapGenerator = mapGen;
            EditorUtility.SetDirty(df);
        }

        // FrontCamera
        if (switcher.frontCamera != null)
        {
            var fc = switcher.frontCamera.GetComponent<FrontFollowCamera>()
                     ?? switcher.frontCamera.gameObject.AddComponent<FrontFollowCamera>();
            fc.target = playerGO.transform;
            EditorUtility.SetDirty(fc);
        }

        // EgoCamera: als Kind des Spielers anhängen → bewegt sich mit dem Spieler
        if (switcher.egoCamera != null)
        {
            var egoCam = switcher.egoCamera.gameObject;
            egoCam.transform.SetParent(playerGO.transform, worldPositionStays: false);
            egoCam.transform.localPosition = new Vector3(0f, 0.42f, 0f);
            egoCam.transform.localRotation = Quaternion.identity;

            var guard = egoCam.GetComponent<EgoClipGuard>()
                        ?? egoCam.AddComponent<EgoClipGuard>();
            EditorUtility.SetDirty(guard);
            EditorUtility.SetDirty(egoCam.transform);
        }

        // Startmodus: Ego (Point-of-View des Spielers)
        switcher.startMode = CameraSwitcher.Mode.Ego;
        EditorUtility.SetDirty(switcher);   // Komponente markieren, nicht nur das GameObject
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Physikalischer Charakter-Körper
    // ─────────────────────────────────────────────────────────────────────────
    static GameObject MakePhysicsBody(string name)
    {
        var go  = new GameObject(name);
        var col = go.AddComponent<CapsuleCollider>();
        col.height = 1f;
        col.radius = 0.25f;
        var rb = go.AddComponent<Rigidbody>();
        rb.mass        = 1f;
        rb.drag        = 0.5f;
        rb.angularDrag = 0.05f;
        rb.constraints = RigidbodyConstraints.FreezeRotation;

        var cap = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        cap.name = "Capsule";
        Object.DestroyImmediate(cap.GetComponent<CapsuleCollider>());
        cap.transform.SetParent(go.transform, false);
        cap.transform.localScale = new Vector3(0.5f, 0.5f, 0.5f);
        return go;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UI-Hilfsmethoden
    // ─────────────────────────────────────────────────────────────────────────

    static GameObject MakePanel(Transform parent, string name, Color color)
    {
        var go  = new GameObject(name);
        go.transform.SetParent(parent, false);
        var img = go.AddComponent<Image>();
        img.color = color;
        return go;
    }

    static void StretchFull(GameObject go)
    {
        var rt = go.GetComponent<RectTransform>();
        if (rt == null) return;
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
    }

    static void CenterPanel(GameObject go, Vector2 size)
    {
        var rt = go.GetComponent<RectTransform>();
        if (rt == null) return;
        rt.anchorMin        = new Vector2(0.5f, 0.5f);
        rt.anchorMax        = new Vector2(0.5f, 0.5f);
        rt.pivot            = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = Vector2.zero;
        rt.sizeDelta        = size;
    }

    static GameObject MakeLabel(
        Transform parent, string name, string text,
        Vector2 pivot, Vector2 anchor,
        Vector2 pos,   Vector2 size,
        float fontSize = 30f,
        TextAlignmentOptions align = TextAlignmentOptions.Center)
    {
        var go  = new GameObject(name);
        go.transform.SetParent(parent, false);
        var tmp            = go.AddComponent<TextMeshProUGUI>();
        tmp.text           = text;
        tmp.fontSize       = fontSize;
        tmp.alignment      = align;
        tmp.color          = Color.white;
        tmp.enableWordWrapping = false;
        tmp.overflowMode   = TextOverflowModes.Overflow;
        var rt             = go.GetComponent<RectTransform>();
        rt.pivot           = pivot;
        rt.anchorMin       = anchor;
        rt.anchorMax       = anchor;
        rt.anchoredPosition = pos;
        rt.sizeDelta       = size;
        return go;
    }

    /// <summary>
    /// Erstellt ein TMP-Label mit Stretch-Anchors (kein fester Pivot/Pos/Size).
    /// Jeder Parameter ist in normalisierten Koordinaten der Eltern-Rect (0–1),
    /// plus optionale Pixel-Offsets (padL/padB/padR/padT).
    /// → Überlappen zwischen benachbarten Elementen ist architektonisch ausgeschlossen.
    /// </summary>
    static GameObject MakeStretchLabel(
        Transform parent, string name, string text,
        float minX, float minY, float maxX, float maxY,
        float padL = 0f, float padB = 0f, float padR = 0f, float padT = 0f,
        float fontSize = 24f,
        TextAlignmentOptions align = TextAlignmentOptions.Center)
    {
        var go  = new GameObject(name);
        go.transform.SetParent(parent, false);
        var tmp            = go.AddComponent<TextMeshProUGUI>();
        tmp.text           = text;
        tmp.fontSize       = fontSize;
        tmp.alignment      = align;
        tmp.color          = Color.white;
        tmp.enableWordWrapping = false;
        tmp.overflowMode   = TextOverflowModes.Truncate;   // kein Overflow über die Zelle
        var rt             = go.GetComponent<RectTransform>();
        rt.anchorMin       = new Vector2(minX, minY);
        rt.anchorMax       = new Vector2(maxX, maxY);
        rt.offsetMin       = new Vector2( padL,  padB);    // left, bottom inset
        rt.offsetMax       = new Vector2(-padR, -padT);    // right, top inset (negative!)
        return go;
    }

    /// <summary>
    /// Setzt ein Panel auf Stretch-Anchors mit Pixel-Offsets.
    /// padL/padB = offsetMin, padR/padT = subtracted from offsetMax.
    /// </summary>
    static void SetStretch(
        GameObject go,
        float minX, float minY, float maxX, float maxY,
        float padL = 0f, float padB = 0f, float padR = 0f, float padT = 0f)
    {
        var rt = go.GetComponent<RectTransform>();
        if (rt == null) return;
        rt.anchorMin = new Vector2(minX, minY);
        rt.anchorMax = new Vector2(maxX, maxY);
        rt.offsetMin = new Vector2( padL,  padB);
        rt.offsetMax = new Vector2(-padR, -padT);
    }

    static GameObject MakeButton(
        Transform parent, string name, string label,
        Vector2 pivot, Vector2 anchor, Vector2 pos, Vector2 size)
    {
        var go  = new GameObject(name);
        go.transform.SetParent(parent, false);
        var img   = go.AddComponent<Image>();
        img.color = new Color(0.18f, 0.55f, 0.20f);
        go.AddComponent<Button>();
        var rt             = go.GetComponent<RectTransform>();
        rt.pivot           = pivot;
        rt.anchorMin       = anchor;
        rt.anchorMax       = anchor;
        rt.anchoredPosition = pos;
        rt.sizeDelta       = size;

        var textGO = new GameObject("Text");
        textGO.transform.SetParent(go.transform, false);
        var tmp        = textGO.AddComponent<TextMeshProUGUI>();
        tmp.text       = label;
        tmp.fontSize   = 28f;
        tmp.alignment  = TextAlignmentOptions.Center;
        tmp.color      = Color.white;
        tmp.enableWordWrapping = false;
        var trt        = textGO.GetComponent<RectTransform>();
        trt.anchorMin  = Vector2.zero;
        trt.anchorMax  = Vector2.one;
        trt.offsetMin  = new Vector2(8f, 4f);
        trt.offsetMax  = new Vector2(-8f, -4f);
        return go;
    }
}
#endif
