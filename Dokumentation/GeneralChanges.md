# General Changes – Änderungsprotokoll

Dieses Dokument protokolliert alle Änderungen, die **nicht** modellspezifische Trainingskonfigurationen (YAMLs) betreffen, sondern gemeinsam genutzte Skripte, Prefabs und Assets. Ziel ist es, Merge-Konflikte für Kollegen nachvollziehbar zu machen.

---

## 2026-05-19 – Reward-Shaping & Sensor-Erweiterung für lstm_v3

**Autor:** AlexB  
**Betroffene Dateien:** `Assets/Scripts/Agent/LabyrinthAgent.cs`  
**Hintergrund:** Analyse des vollständigen lstm_v2-Runs (10M Steps) ergab drei Kernprobleme: (1) Agent lernt Lava nie zu überspringen, weil kein positives Reward-Signal vorhanden war. (2) Agent fällt in Löcher, weil laterale Sensoren fehlen. (3) Hard Maps (Phase 7) Plateau bei 20–27% Success Rate wegen zu kurzer Episode-Länge.

---

### 1. Reward-Felder geändert

#### `lavaDeathPenalty`: `-1f` → `-2f`
Stärkere Differenzierung zwischen Lava-Tod (Sprung-Risiko, aktiv) und Loch-Tod (Navigations-Fehler). Damit ist Lava-Tod doppelt so teuer, was den Anreiz erhöht, Lava aktiv zu umgehen **oder** präzise zu überspringen statt zufällig hineinzulaufen.

#### `lavaAttemptBaseReward`: `0f` → `0.5f`
Bisher gab es **keinerlei** positives Signal für Lava-Sprung-Versuche. `GetLavaAttemptReward()` gab immer 0 zurück. Die Physik-Analyse zeigt, dass der Agent einen 1m breiten Lava-Trigger (Weltkoordinaten: y=0.05–0.45m) mit seiner Sprungkraft (v₀=3.5 m/s → max. Kapsel-Unterseite y=0.725m) physikalisch überwinden kann. Ohne diesen Reward fand der Agent diese Strategie nie. Der Decay-Mechanismus in `GetLavaAttemptReward()` (Attempt 2: base/4, Attempt 3: base/8) bleibt unverändert, um endloses Farming zu verhindern.

#### Neues Feld `lavaCrossingReward = 2.0f`
Belohnung für das **erfolgreiche Überqueren** von Lava (war über Lava, landet wieder auf Boden, Episode nicht durch Tod beendet). Netto-Erwartungswert bei 50% Erfolg: +2.0×0.5 − 2.0×0.5 = 0 → Break-even. Sobald der Agent jedoch einmal erfolgreich ist und das Ziel (+30f) dahinter findet, wird die Strategie stark reinforced.

**Neue Logik in `OnActionReceived()`:**
```csharp
if (wasAboveLava && !currentlyAboveLava && isGrounded && !episodeEndedByTerminal)
{
    AddReward(lavaCrossingReward);
}
```
Diese Bedingung prüft den Zustandsübergang "über Lava → wieder am Boden" als Edge-Trigger, analog zur bereits vorhandenen Eintritts-Erkennung.

---

### 2. Boden-Sensoren erweitert: 3 → 5 Sensoren (14 → 18 Observations)

**Vorher:** 3 Sensoren entlang `transform.forward` (unter Agent, +1 Zelle, +2 Zellen)  
**Nachher:** 5 Sensoren (+2 diagonale Lateral-Sensoren):

```
transform.forward * 0.7f + transform.right * 0.7f  // 1 Zelle rechts-vorne
transform.forward * 0.7f - transform.right * 0.7f  // 1 Zelle links-vorne
```

**Warum:** Der Agent hatte keine Information über Gefahren (Lava, Löcher) seitlich neben dem aktuellen Kurs. Beim Drehen oder bei seitlichem Ausweichen kam der Sensor nicht zum Einsatz. Die diagonalen Sensoren erfassen den nächsten Bereich rechts und links vor dem Agenten, was besonders bei Kurven und engen Passagen hilft.

**Konsequenz für BehaviorParameters:** `Vector Observation > Space Size` muss im Unity Inspector auf **18** gesetzt werden (war 14). Checkpoints aus lstm_v2 oder älteren Runs sind **nicht kompatibel** – neues Training erforderlich.

**Konsequenz für Gizmo-Darstellung:** `OnDrawGizmosSelected()` wurde entsprechend aktualisiert (gleicher checkOffsets-Array).

---

### 3. Curriculum MaxStep pro Phase angepasst

```csharp
// Alt:
phaseMaxSteps = { 600, 600, 600, 600, 600, 1000, 1500, 2000 }

// Neu:
phaseMaxSteps = { 400, 400, 400, 400, 400, 800, 1500, 3000 }
```

**Trivial (Phase 0–4):** 600 → 400. Der Agent meistert Trivial-Maps nach wenigen Episoden. Kürzere Episodes = schnellerer Curriculum-Fortschritt in den frühen Phasen.

**Easy (Phase 5):** 1000 → 800. Gleiche Begründung, angepasst proportional.

**Medium (Phase 6):** 1500 → 1500. Unverändert.

**Hard (Phase 7):** 2000 → 3000. Im lstm_v2-Run war der Agent 5.9M Steps auf Phase 7 bei 20–27% Success Rate ohne Verbesserung. Eine längere Episode gibt ihm mehr Zeit pro Episode, komplexe Hard-Maps zu navigieren und die neu erlernbare Lava-Überquer-Strategie anzuwenden.

---

### Übersicht aller Änderungen

| Feld / Bereich | Alt | Neu | Datei |
|---|---|---|---|
| `lavaDeathPenalty` | `-1f` | `-2f` | LabyrinthAgent.cs |
| `lavaAttemptBaseReward` | `0f` | `0.5f` | LabyrinthAgent.cs |
| `lavaCrossingReward` | *(nicht vorhanden)* | `2.0f` | LabyrinthAgent.cs |
| Lava-Crossing-Logik | *(nicht vorhanden)* | Edge-Trigger in `OnActionReceived` | LabyrinthAgent.cs |
| Boden-Sensoren Anzahl | 3 | 5 | LabyrinthAgent.cs |
| Observations gesamt | 14 | 18 | LabyrinthAgent.cs |
| `phaseMaxSteps` Trivial (0–4) | 600 | 400 | LabyrinthAgent.cs |
| `phaseMaxSteps` Easy (5) | 1000 | 800 | LabyrinthAgent.cs |
| `phaseMaxSteps` Hard (7) | 2000 | 3000 | LabyrinthAgent.cs |
| BehaviorParameters Space Size | 14 | 18 | Unity Inspector (manuell) |

---

## 2026-05-19 – Lava-Sprung Physics-Fix & Reward-Tuning für lstm_v4

**Autor:** AlexB  
**Betroffene Dateien:** `Assets/Scripts/Agent/LabyrinthAgent.cs`, `Assets/Prefabs/Map/Obstacles/Lava_Placeholder.prefab`  
**Hintergrund:** Analyse von lstm_v3 zeigte, dass der Agent physikalisch nicht in der Lage war, über Lava zu springen. Ursache: Der Lava-Trigger erstreckte sich bis y=0.45m (Weltkoordinaten), die Kapsel-Unterseite benötigte 0.12s um diese Höhe zu erreichen — zu lang für die verfügbare horizontale Distanz. Der Agent starb immer bevor er die Trigger-Zone überwinden konnte, weshalb `lavaAttemptBaseReward` und `lavaCrossingReward` nie feuerten.

---

### 1. Lava-Trigger verkleinert

**`Assets/Prefabs/Map/Obstacles/Lava_Placeholder.prefab`**

```
BoxCollider size.y:   4 → 2   (Weltkoordinaten: Trigger-Top 0.45m → 0.35m)
BoxCollider center.y: 2.5 → 1.5
```

Mit dem kleineren Trigger muss die Kapsel-Unterseite nur noch über y=0.35m steigen (statt 0.45m). Kombiniert mit der erhöhten Sprungkraft reduziert sich die nötige Anlaufzeit (t₁) von 0.12s auf ~0.05s — der Agent kann den Trigger jetzt zuverlässig überwinden.

---

### 2. Sprungkraft erhöht

**`LabyrinthAgent.cs`**

```
jumpForce:         4.5 → 6.0
maxUpwardVelocity: 3.5 → 5.0
```

`jumpForce` allein reicht nicht — `maxUpwardVelocity` begrenzt die effektive Anfangsgeschwindigkeit. Beide müssen zusammen erhöht werden. Mit v₀=5.0 m/s: Zeitfenster über Trigger wächst von 0.47s auf 0.87s, horizontale Reichweite im Sprung von 1.41m auf 2.6m.

---

### 3. Reward für Sprung mit Lava-Sicht

**`LabyrinthAgent.cs`** — neues privates Feld `lavaVisibleAhead`, gesetzt in `CollectObservations`, ausgewertet in `OnActionReceived`:

```csharp
// In CollectObservations: Flag setzen wenn Sensor[1..4] Lava erkennt
if (i > 0 && hit.collider.CompareTag("Lava"))
    lavaVisibleAhead = true;

// In OnActionReceived: Reward bei Sprung mit Lava-Sicht
if (jumpAction == 1 && isGrounded && lavaVisibleAhead)
    AddReward(0.25f);
```

Frühes Signal noch vor dem eigentlichen Lava-Überqueren. Belohnt die Intention (Sprung richtung sichtbarer Lava), nicht nur das Ergebnis.

---

### 4. Reward-Tuning

```
lavaAttemptBaseReward: 0.5 → 0.3
```
Reduziert, da `lavaJumpIntent`-Reward (+0.25 beim Absprung) jetzt die frühe Verstärkung übernimmt. Fokus liegt auf `lavaCrossingReward = 2.0f` (erfolgreiches Überqueren).

---

### 5. Curriculum Easy-Phase verlängert

```
phaseMaxSteps[5] (Easy): 800 → 1200
```
Der Agent braucht mehr Episoden auf Easy-Maps (erste Lava-Maps) um die Lava-Sprung-Strategie zu festigen, bevor er auf Medium hochgestuft wird.

---

### Übersicht aller Änderungen

| Feld / Bereich | Alt | Neu | Datei |
|---|---|---|---|
| Lava BoxCollider size.y | 4 | 2 | Lava_Placeholder.prefab |
| Lava BoxCollider center.y | 2.5 | 1.5 | Lava_Placeholder.prefab |
| `jumpForce` | 4.5 | 6.0 | LabyrinthAgent.cs |
| `maxUpwardVelocity` | 3.5 | 5.0 | LabyrinthAgent.cs |
| `lavaAttemptBaseReward` | 0.5 | 0.3 | LabyrinthAgent.cs |
| `lavaVisibleAhead` Flag + Reward | nicht vorhanden | +0.25f bei Sprung mit Lava-Sicht | LabyrinthAgent.cs |
| `phaseMaxSteps[5]` (Easy) | 800 | 1200 | LabyrinthAgent.cs |

---

## 2026-05-19 – Death-Reason-Logging & Curriculum Loop ab Phase 4

**Autor:** AlexB  
**Betroffene Dateien:** `Assets/Scripts/Agent/LabyrinthAgent.cs`, `Assets/Scripts/Map/CurriculumConfig.cs`, `Assets/Scripts/Map/CurriculumTracker.cs`, `Assets/CurriculumConfig_Default.asset`

---

### 1. Death-Reason-Logging pro Episode

**`LabyrinthAgent.cs`** — neue private Enum und Tracking-Variable:

```csharp
private enum DeathReason { None, Lava, Hole, Timeout }
private DeathReason lastDeathReason = DeathReason.None;
```

Neue TensorBoard-Metriken (geloggt in `OnEpisodeBegin`):
- `Custom/DeathByLava` — 1.0 wenn Lava-Tod, sonst 0
- `Custom/DeathByHole` — 1.0 wenn Loch-Tod, sonst 0
- `Custom/DeathByTimeout` — 1.0 wenn Timeout, sonst 0

Gesetzt in `OnTriggerEnter` (Lava/KillZone) und `OnActionReceived` (Timeout-Branch).

---

### 2. Curriculum Loop ab Phase 4

**`CurriculumConfig.cs`** — neues Feld:
```csharp
[Min(0)] public int loopStartPhaseIndex = 0;
```
Steuert sowohl die **Startphase** beim Initialisieren als auch die **Loop-Rückkehrphase** nach der letzten Phase.

**`CurriculumTracker.cs`** — `Initialize()` und `CheckPhaseAdvance()` nutzen `loopStartPhaseIndex`:
- Init: `currentPhaseIndex = Mathf.Clamp(cfg.loopStartPhaseIndex, 0, phases.Length - 1)`
- Loop: statt `% phases.Length` → `currentPhaseIndex = loopStartPhaseIndex` wenn letzte Phase erreicht

**`CurriculumConfig_Default.asset`**:
```
loopPhases: 0 → 1
loopStartPhaseIndex: 4  (neu)
```
Agent startet jetzt direkt bei Phase 4 (Difficulty=4, erste Lava-Maps) und loopt nach Phase 7 wieder zu Phase 4 zurück.

---

### Übersicht

| Bereich | Änderung | Datei |
|---|---|---|
| Death-Reason Enum + Variable | neu: Lava / Hole / Timeout | LabyrinthAgent.cs |
| TensorBoard: DeathByLava/Hole/Timeout | neu (pro Episode) | LabyrinthAgent.cs |
| `loopStartPhaseIndex` Feld | neu, default 0 | CurriculumConfig.cs |
| Init + Loop-Logik mit loopStartPhaseIndex | geändert | CurriculumTracker.cs |
| loopPhases: false→true, loopStartPhaseIndex: 4 | geändert | CurriculumConfig_Default.asset |
