# Trainingsanalyse Milestone 7 – Fehlerdiagnose

**Datum:** 2026-04-28
**Betroffen:** Transformer-Training (1,69M Steps) + LSTM-Vergleichstest (1M Steps)
**Ergebnis:** Zwei unabhängige Bugs identifiziert

---

## Beobachtung

Beide Architekturen zeigen nach vielen Steps keinerlei Lernfortschritt:

| Architektur | Steps | Mean Reward Start | Mean Reward Ende |
|---|---|---|---|
| Transformer | 1.690.000 | -2.52 | -2.45 |
| LSTM | 1.000.000 | -2.52 | -2.45 |

Der Reward entspricht durchgehend `MaxSteps × StepPenalty = ~2400 × (-0.001) = -2.4` — der Agent läuft in jeder Episode bis zum Timeout, ohne je das Goal zu erreichen.

---

## Bug 1: Transformer-Patch – PPO-Ratio inkonsistent

### Ursache

ML-Agents ruft `get_action_and_stats()` während der Inference **ohne** `sequence_length`-Argument auf (Default = 1). Der PPO-Optimizer trainiert dagegen mit `sequence_length = 8` aus dem YAML.

```
Inference  → sequence_length=1  → old_log_probs gespeichert (1-Step-Forward-Pass)
Training   → sequence_length=8  → new_log_probs berechnet  (8-Step-Forward-Pass)

PPO-Ratio = π_new(seq=8) / π_old(seq=1)  ←  kein gültiges π_new/π_old-Verhältnis
```

### Warum LSTM davon nicht betroffen ist

LSTM verarbeitet jeden Step einzeln mit gespeichertem Hidden State. Der 8-Step-Trainingsdurchlauf startet vom selben gespeicherten Zustand und produziert deterministisch dieselben Log-Probs wie die Inference. Der Transformer hat keinen persistenten Zustand — er braucht alle 8 Steps gleichzeitig, bekommt sie aber während der Inference nie.

### Konsequenz

PPO clippt fast jeden Gradient, weil die Ratio weit außerhalb `[1-ε, 1+ε]` liegt. Der Transformer lernt faktisch nichts, obwohl die Implementierung selbst rechnerisch korrekt ist.

### Fix (wenn Reward-Problem gelöst)

Letzten `seq_len - 1` Encodings im Memory-Buffer speichern, bei Inference die vollständige Sequenz daraus rekonstruieren. Dann gilt: Inference-seq = Training-seq → konsistente Log-Probs.

---

## Bug 2: Sparse Reward – Goal wird nie durch Exploration gefunden

### Ursache

In ~416 Episoden (1M Steps / 8 Areas / ~2400 Steps/Episode) wurde das Goal **kein einziges Mal** erreicht. Labyrinthe sind für zufällige Exploration notorisch ineffizient — ein Random-Walk findet das Ziel in 2400 Steps statistisch kaum.

Ohne je ein positives Reward-Signal zu erhalten hat PPO **keinen Gradienten in Richtung Goal**. Der Agent optimiert einzig das, was er beobachtet: Nicht sterben (Death-Penalty `-1.0` schlechter als Timeout `-2.4`). Das führt zu flacher Reward-Kurve, kein Lernen Richtung Ziel.

### Warum das auch LSTM betrifft

LSTM wäre korrekt implementiert und würde bei ausreichend positivem Signal lernen. Aber ohne einen einzigen Goal-Reach gibt es dieses Signal nicht — dasselbe Problem wie beim Transformer, aus einem anderen Grund.

### Fix: Potentialbasiertes Reward-Shaping

Dichtes Feedback pro Step, ob der Agent sich dem Ziel nähert oder entfernt:

```csharp
// In LabyrinthAgent.cs
private float lastDistToGoal = -1f;

// OnEpisodeBegin: lastDistToGoal = -1f;

// OnActionReceived (nach bestehendem Code):
if (goalTransform != null)
{
    float currentDist = Vector3.Distance(transform.position, goalTransform.position);
    if (lastDistToGoal >= 0f)
    {
        float progress = lastDistToGoal - currentDist;
        AddReward(progress * 0.05f);
    }
    lastDistToGoal = currentDist;
}
```

Potentialbasiertes Shaping ist theoretisch neutral — die optimale Policy ändert sich nicht, aber der Agent bekommt in jeder Episode hunderte lernbare Signale statt null.

### Alternative: Easy-Maps radikal vereinfachen

Phase 0 so gestalten, dass ein Random-Walk das Goal zufällig findet:
- 4×4 oder 5×5 Map ohne Hindernisse
- Spawn und Goal immer in gegenüberliegenden Ecken
- Sobald der Agent das Goal einmal findet, existiert ein Gradient

---

## Abhängigkeit der Bugs

```
Bug 2 (Sparse Reward) blockiert Bug 1 (Transformer) vollständig:
  → Solange das Goal nie erreicht wird, gibt es kein Signal
  → Kein Signal bedeutet kein Lernunterschied zwischen Architekturen
  → Ein Architekturvergleich Transformer vs. LSTM ist erst sinnvoll
    wenn Bug 2 behoben ist und LSTM stabil lernt
```

---

## Empfohlene Reihenfolge

1. **Reward-Shaping implementieren** (oder Easy-Maps vereinfachen)
2. **LSTM bis Konvergenz trainieren** — Baseline bestätigen
3. **Transformer-Patch mit rollendem Memory-Buffer** nachbessern
4. **Vergleich Transformer vs. LSTM** auf funktionierender Baseline



## Fix 1 
Ja, Bug 1 ist gefixt.

  Was war das Problem:
  Inference rief den Transformer mit sequence_length=1 auf (ein Step), Training mit sequence_length=8. PPO-Ratio
  π_new(seq=8) / π_old(seq=1) war damit strukturell ungültig — fast jeder Gradient wurde geclippt.

  Was der Fix macht:
  Der memories-Tensor (1792 Floats statt 128) speichert jetzt die letzten 7 MLP-Encodings als Rolling-Buffer. Bei
  Inference wird daraus die vollständige 8-Step-Sequenz rekonstruiert, bevor sie in den Transformer geht. Inference und
  Training sehen damit denselben Kontext → konsistente Log-Probs → gültige PPO-Ratio.

  Geänderte Dateien:
  - training/transformer_policy.py + installierte transformer_memory.py — self.seq_len hinzugefügt
  - networks.py (Venv) — memory_size-Property und forward() mit Rolling-Buffer-Logik
  - training/patch_mlagents.py — Upgrade-Pfad v1→v2, robusteres Undo, Pfad-Bug gefixt

  Wichtige Einschränkung:
  Bug 2 (Sparse Reward) blockiert trotzdem jedes Lernen. Bug 1 ist nur dann beobachtbar, wenn der Agent überhaupt
  Reward-Signal bekommt — also erst nach Bug 2 Fix sinnvoll zu testen.


## Fix 2
**Sparse-Reward-Fix durch Trivial-Phase:** Der `ProceduralLayoutGenerator` erzeugt jetzt 7×7 Open-Room-Maps ohne Hindernisse (4 diagonale Rotationen per Seed), die vom `CurriculumTracker` automatisch generiert werden sobald `difficulty == Trivial` — kein Layout-Asset nötig. Der `MapGeneratorEditor` wurde um `Trivial` in der `DifficultyMask` erweitert, damit Laden/Entladen/Sortieren korrekt funktioniert.

**Curriculum neu konfiguriert:** Die `CurriculumConfig_Default` hat jetzt 4 Phasen (Trivial→Easy→Medium→Hard), alle Thresholds wurden ×8 skaliert (1600/4000/6400/8000 Episoden) um die 8 parallelen Training-Areas korrekt zu berücksichtigen.

**Episode-Länge und Trainingsbudget angepasst:** `MaxStep` im Agent-Prefab wurde von 2500 auf 6000 erhöht, `max_steps` in den YAML-Configs auf 10M (LSTM) bzw. 15M (Transformer) hochgesetzt.

## Fix 3
 1. Wall-Climb Bug Fix (LabyrinthAgent.cs)

  Problem: Der Agent kletterte die Wand hoch — physikalisch möglich durch fehlende Friction auf dem Wall-Prefab. Das Rigidbody glitt die Wand entlang statt
  abzuprallen.

  Entscheidung: Out-of-Bounds-Check in FixedUpdate() statt Physics-Material-Fix, weil er unabhängig vom Fluchtweg greift und keine Prefab-Änderungen
  benötigt.

  Implementierung:
  - Neues [SerializeField] wallClimbMaxY = 1.5f (im Inspector konfigurierbar)
  - Check in FixedUpdate: if (transform.position.y > wallClimbMaxY) → holeDeathPenalty + EndEpisode()
  - Schwellwert 1.5f: physikalisch unmöglich ohne Wall-Climb, Agent kommt normal nie über ~1.1m

  ---
  2. Analyse: Repetitives Verhalten (Ecke + Sprung-Loop)

  Beobachtung: Agent läuft in eine Ecke und springt endlos, obwohl das Ziel 4 Blöcke entfernt ist.

  Root Causes identifiziert:

  ┌──────────────────────────────────────────────────────────────────────────┬──────────┐
  │                                 Ursache                                  │ Schwere  │
  ├──────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Richtungs-Observation ist normalisierter Unit-Vektor → keine Distanzinfo │ Kritisch │
  ├──────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Sparse Reward: +1 nur bei Zielberührung, kein Shaping                    │ Kritisch │
  ├──────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Entropie-Kollaps durch lineares Beta-Decay in YAML                       │ Mittel   │
  ├──────────────────────────────────────────────────────────────────────────┼──────────┤
  │ normalize: false in YAML                                                 │ Mittel   │
  ├──────────────────────────────────────────────────────────────────────────┼──────────┤
  │ Keine Curiosity/Intrinsic Reward                                         │ Mittel   │
  └──────────────────────────────────────────────────────────────────────────┴──────────┘

  Kernproblem: Auf dem Trivial-Layout (Spawn (1,1), Ziel (5,5)) ist der Richtungsvektor zum Ziel an jedem Punkt des Diagonalpfads identisch (0.707, 0,
  0.707). Der Agent bekommt null Gradient-Signal, dass er sich dem Ziel nähert. Das Training-Log bestätigte: in 370.000 Steps wurde das Ziel kein einziges
  Mal erreicht (Mean Reward nie positiv, mehrfach Std ≈ 0 → deterministische Kollaps-Policy).

  ---
  3. Training-Monitoring & Crash-Diagnose

  Befund aus Log-Analyse:
  - 370.000 Steps trainiert, dann UnityTimeOutException (Communicator-Disconnect)
  - Mean Reward oszillierte zwischen -2.6 und -6.0, kein Aufwärtstrend
  - Mehrfach Std of Reward ≈ 0.001 bei Mean ≈ -5.998 = Entropie-Kollaps bestätigt
  - -5.998 ≈ Episoden-Step-Limit × -0.001: Agent läuft jede Episode bis zum Maximum durch ohne Ziel

  ---
  4. Fix: PBRS + Distanz-Observation (LabyrinthAgent.cs)

  Entscheidung: Potential-Based Reward Shaping (PBRS) kombiniert mit Distanz als zusätzliche Observation.

  Warum PBRS und nicht delta-Distanz oder LOS-Reward:
  - PBRS ist mathematisch bewiesen (Ng et al. 1999): verändert die optimale Policy nicht, beschleunigt nur das Lernen
  - Delta-Distanz ohne Gamma-Korrektur ist farmbar (Oscillieren ums Ziel)
  - LOS-Reward wäre farmbar (Agent schaut Goal an, bleibt stehen)

  Implementierung:

  Observations: 13 → 14  (+1: distToGoal / maxObservationDistance)
  PBRS:  F = (prevDist − γ · currDist) × scale
         γ = 0.99  (entspricht gamma im YAML)
         scale = 0.02  (klein genug, dass goalReward=1.0 dominant bleibt)

  Neue [SerializeField]-Felder:
  - distanceShapingScale = 0.02f
  - pbrsGamma = 0.99f
  - maxObservationDistance = 20f


  **Problem 1 – Episoden endeten nach 2–3 Steps**
Der Wall-Climb-Guard in `FixedUpdate` rief `EndEpisode()` auf, sobald der Agent durch PhysX-Depenetration kurz über `spawnY + 1.5f` katapultiert wurde. Fix: `EndEpisode()` entfernt, Check nach `OnActionReceived` verschoben (einmal pro Decision Step statt 1000×/Sek), Schwelle auf `3.0f` erhöht.

**Problem 2 – Reward trotzdem noch -2800**
`wallClimbMaxY` war im Unity Inspector noch auf dem alten Wert `1.5`. Penalty feuerte weiterhin fast jeden Step. Fix: Inspector-Wert korrigiert (Nutzerfehler).

**Problem 3 – Agent erreichte Y=4.5+ trotz geringer Jump Force**
PhysX-Depenetration schleuderte den Agent beim Laufen gegen Wände nach oben — unabhängig vom Sprung. Fix: `rb.velocity.y` wird in `FixedUpdate` auf `maxUpwardVelocity = 3.5f` gecappt. Normale Sprünge (3 m/s) bleiben unberührt, Physics-Launches werden direkt unterbunden.

**Ergebnis:** 97 → 315 Steps/Sek, Reward normalisiert (-0.4 bis +0.7), Goals werden erreicht.


## Problem
  Nach 680k Steps auf einer 7×7 Trivial-Map zeigt der Transformer
   kein Lernverhalten:

  - Entropy = 2.27 / max. 2.30 → Policy ist 97% zufällig, keine
  Präferenz für irgendeine Aktion
  - Reward oszilliert um 0 ohne Aufwärtstrend — der Agent findet
  das Goal nur durch Zufall (kleine Map)
  - Policy Loss steigt leicht statt zu fallen

  Wahrscheinlichste Ursache: Der Gradient fließt nicht korrekt
  durch den custom Transformer-Patch zurück zur Policy. Der
  Rolling-Buffer im Forward-Pass (squeeze/unsqueeze, torch.cat)
  unterbricht womöglich den Backpropagation-Pfad — PyTorch kann
  dann keine sinnvollen Gradienten berechnen.

  Nächster Schritt: LSTM-Vergleichslauf mit identischen
  Hyperparametern. Wenn LSTM innerhalb von ~100k Steps
  Entropy-Abfall zeigt, ist der Patch-Bug bestätigt.


Transformer-Versionsvergleich

  Konfiguration je Version

  ┌────────────────┬───────┬───────┬───────┬──────────┐
  │   Parameter    │  v5   │  v6   │  v7   │ v8 (aktu │
  │                │ (alt) │       │       │   ell)   │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Causal Mask    │ ✗     │ ✓     │ ✓     │ ✓        │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Dropout        │ 0.1   │ 0.0   │ 0.0   │ 0.0      │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Learning Rate  │ 3.0e- │ 1.0e- │ 1.0e- │ 1.0e-4   │
  │                │ 4     │ 4     │ 4     │          │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Beta (Entropy- │ 5.0e- │ 5.0e- │ 1.0e- │ 1.0e-3   │
  │ Koeff.)        │ 3     │ 3     │ 3     │          │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Buffer Size    │ 10.24 │ 10.24 │ 10.24 │ 40.960   │
  │                │ 0     │ 0     │ 0     │          │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Time Horizon   │ 64    │ 64    │ 64    │ 256      │
  ├────────────────┼───────┼───────┼───────┼──────────┤
  │ Max Steps      │ 30M   │ 30M   │ 30M   │ 30M      │
  └────────────────┴───────┴───────┴───────┴──────────┘

  ---
  Messwerte & Ergebnisse

  ┌─────────────┬───────┬──────────┬──────────┬────────┐
  │   Metrik    │  v5   │    v6    │    v7    │   v8   │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Steps       │ ~680k │ 700k     │ 1.45M    │ 820k ( │
  │ trainiert   │       │          │          │ läuft) │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │             │       │          │          │ ~60    │
  │ PPO-Updates │ ~200  │ ~205     │ ~425     │ (4×    │
  │             │       │          │          │ selten │
  │             │       │          │          │ er)    │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Entropy     │ 2.30  │ 2.30     │ 2.30     │ 2.30   │
  │ Start       │       │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Entropy     │ 2.27  │ 1.937 @  │ 1.603 @  │ 2.017  │
  │ Minimum     │       │ 330k     │ 460k     │ @ 270k │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Entropy     │ 2.27  │ 2.266    │ 1.924    │ 2.158  │
  │ Ende        │       │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │             │       │ ✗ (nie   │ ✓ stark  │        │
  │ Entropy-Reb │ —     │ wirklich │ (660k–90 │ noch   │
  │ ound?       │       │  gefalle │ 0k)      │ offen  │
  │             │       │ n)       │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Reward Ø    │ ~0.00 │ +0.04    │ +0.10    │ −0.12  │
  │ erste 20    │       │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Reward Ø    │ ~0.00 │ +0.06    │ +0.24    │ +0.11  │
  │ letzte 20   │       │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Reward      │ ~0.0  │ +0.63    │ +1.14    │ +0.54  │
  │ Maximum     │       │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Policy Loss │ steig │ 0.024    │ 0.012    │ 0.027  │
  │  Start      │ end   │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │ Policy Loss │ steig │ 0.087    │ 0.089    │ 0.084  │
  │  Ende       │ end   │          │          │        │
  ├─────────────┼───────┼──────────┼──────────┼────────┤
  │             │       │ ~0.001   │ ~0.001   │        │
  │ Value Loss  │ n.v.  │ (kollabi │ (kollabi │ ~0.002 │
  │             │       │ ert)     │ ert)     │        │
  └─────────────┴───────┴──────────┴──────────┴────────┘

  ---
  ## Diagnose & Hauptproblem je Version

  Version: v5
  Hauptproblem: Kein Lernen überhaupt
  Diagnose: Kein Causal Mask → bidirektionale Attention
    lernst eine Funktion die bei Inference nicht existiert.
    Policy Loss stieg statt zu fallen.
  ────────────────────────────────────────
  Version: v6
  Hauptproblem: Entropy fast gar nicht gefallen,
    Policy-Loss-Plateau
  Diagnose: Causal Mask + niedrige LR behoben, aber
  Beta=5e-3
    zu hoch → Entropy-Regularisierung kämpft gegen
    Policy-Konvergenz. Entropy berührte 1.937 einmal kurz,
    dann sofort Rebound.
  ────────────────────────────────────────
  Version: v7
  Hauptproblem: Entropy-Rebound bei 660k–900k nach gutem
    Start
  Diagnose: Beta-Fix wirkte stark (1.603 Minimum!), aber
    Value-Function kollabierte auf ~0.001 → verrauschte
    Advantages → Policy instabil. Buffer zu klein (10k Steps

    = ~5 Episoden) für stabile Advantage-Schätzung auf
    wachsenden Maps.
  ────────────────────────────────────────
  Version: v8
  Hauptproblem: Zu früh für abschließendes Urteil
  Diagnose: Buffer 4× größer → nur 60 PPO-Updates bisher (v7

    hatte 425). Entropy fällt langsamer pro Step, aber
    stabiler pro Update. Kein Value-Kollaps sichtbar bisher.

    Erster echter Test ab ~200k Steps (erste ~5 Updates).

  ---
  Vergleich: Steps bis Entropy < 2.0

  ┌─────────┬────────────────────────┬──────────────────┐
  │ Version │  Steps bis Entropy <   │   PPO-Updates    │
  │         │          2.0           │      dafür       │
  ├─────────┼────────────────────────┼──────────────────┤
  │ v5      │ nie                    │ —                │
  ├─────────┼────────────────────────┼──────────────────┤
  │ v6      │ ~330k                  │ ~97 Updates      │
  ├─────────┼────────────────────────┼──────────────────┤
  │ v7      │ ~130k                  │ ~38 Updates      │
  ├─────────┼────────────────────────┼──────────────────┤
  │ v8      │ ~270k (erste           │ ~20 Updates      │
  │         │ Berührung)             │                  │
  └─────────┴────────────────────────┴──────────────────┘

  v7 hat das beste Verhältnis: unter 2.0 nach nur 38
  Updates. v8 braucht weniger Updates auf dem Papier (20),
  aber der Wert ist weniger stabil weil der Buffer größer
  ist und mehr Rauschen rausgemittelt wird.


## Probleme
    Bug 1: Goal ist halb im Boden (bestätigt)

 Goal.prefab
  m_LocalPosition: {x: 0, y: 0.5, z: 0}   ← Prefab-Position
  SphereCollider:
    m_Center: {x: 0, y: 0, z: 0}           ←
  Collider-Zentrum bei y=0
    m_Radius: 0.51

  Und in MapGenerator.cs Zeile 568:
  private Vector3 CellToWorld(Vector2Int cell)
      => mapRoot.position + new Vector3(cell.x * cellSize,
  0f, cell.y * cellSize);

  Das Goal wird bei y=0 gespawnt. Das Prefab hatte zwar
  y=0.5 gespeichert, aber Instantiate(prefab, position, ...)
   überschreibt die gespeicherte Position mit dem
  übergebenen Wert — also landet das Goal bei y=0. Der
  Sphere-Trigger hat sein Zentrum bei y=0, Radius 0.5 → geht
   von y=-0.5 bis y=+0.5, also halb unter dem Boden. Der
  Agent (Kapsel-Zentrum bei ~y=0.6) triggert ihn nur im
  schmalen Bereich y=0.1–0.5. Trigger funktioniert, aber der
   horizontale Erkennungsradius ist deutlich kleiner als er
  sein sollte.

  ---
  Bug 2: Nur 4 Trivial-Konfigurationen → Agent memoriert

  // ProceduralLayoutGenerator.cs, Zeile 89
  switch (seed % 4)
  {
      case 0: spawn=(1,1), goal=(5,5)
      case 1: spawn=(5,1), goal=(1,5)
      case 2: spawn=(1,5), goal=(5,1)
      case 3: spawn=(5,5), goal=(1,1)
  }

  Nur 4 mögliche Layouts. Bei 3200 Trivial-Episoden × 10
  Areas sieht der Agent jede Konfiguration ~8000 Mal. Statt
  zu lernen "folge dem directionToGoal Vektor", hat er
  gelernt "geh immer zu lokaler Position (5,5)" — das ist
  Case 0. Das funktioniert 25% der Zeit (wenn Goal
  tatsächlich dort ist), die anderen 75% läuft er dagegen
  und kostet Zeit bis MaxStep.

  ---
  Das ist kein Transformer-Problem, sondern zwei konkrete
  Bugs. Der Agent lernt rational: "Diese Ecke hat oft eine
  Belohnung → geh immer dahin." Das erklärt sowohl das
  Wiederholungsverhalten als auch die Timeout-Episoden
  (Episode Length 1199)


## Änderungsdokumentation – Milestone 7: Curriculum & Map-Architektur

### 1. `Assets/Scripts/Map/DifficultyLevel.cs`

**Enum neu strukturiert** — war nicht-sequenziell (`Trivial=3, Easy=0, Medium=1, Hard=2`), jetzt sequential 0–7:

| Wert            | Int | Beschreibung                                         |
| --------------- | --- | ---------------------------------------------------- |
| `Trivial`       | 0   | 7×7 offener Raum, Spawn in Ecke, Goal zufällig       |
| `TrivialCorr`   | 1   | SpawnRaum + GoalRaum + 1 direkter 2-breiter Korridor |
| `TrivialBranch` | 2   | wie TrivialCorr + blind endender Ast-Korridor        |
| `TrivialHole`   | 3   | wie TrivialBranch + 2×2 Hole am Ast-Ende             |
| `TrivialHazard` | 4   | wie TrivialHole + 2×1 Lava im Hauptkorridor          |
| `Easy`          | 5   | unverändert (15–20×18–25, RoomCorridorGraph)         |
| `Medium`        | 6   | unverändert                                          |
| `Hard`          | 7   | unverändert                                          |

`DifficultySettings.For()` gibt für alle Trivial-Varianten einen Dummy-Struct zurück (direkte Grid-Konstruktion, keine RoomCorridorGraph-Pipeline).

---

### 2. `Assets/Scripts/Map/ProceduralLayoutGenerator.cs`

**Top-Level-Switch** leitet Trivial-Varianten an dedizierte Generator-Methoden weiter, Easy/Medium/Hard gehen weiterhin durch die RoomCorridorGraph-Pipeline.

**Neue Generatoren (alle: `noRuntimeObstacles = true`, kein Pathfinding-Check):**

- `GenerateTrivialLayout` — Goal jetzt auf zufälligem Floor-Tile statt gegenüberliegender Ecke (behebt Eck-Heuristik des Agenten)
- `GenerateTrivialCorrLayout` — 4 Rotationsvarianten (horizontal/vertikal × gespiegelt)
- `GenerateTrivialBranchLayout` — baut auf TrivialCorr auf, fügt senkrechten Ast-Korridor hinzu
- `GenerateTrivialHoleLayout` — wie Branch + 2×2 Hole am Ast-Ende
- `GenerateTrivialHazardLayout` — wie Hole + 2×1 Lava im Hauptkorridor

**Neue Hilfsmethoden:** `FillRoom()`, `PickRandomFloor()`, `IsFloorLike()` (jetzt inklusive Lava/Hole)

---

### 3. `Assets/Scripts/Map/TilePool.cs` *(neue Datei)*

GameObject-Pool für Map-Tiles. Verhindert `Destroy`/`Instantiate` pro Episode.

| Methode                  | Beschreibung                                                            |
| ------------------------ | ----------------------------------------------------------------------- |
| `Initialize(prefabMap)`  | Setzt die CellType→Prefab-Zuordnung                                     |
| `Get(type, pos, parent)` | Zieht aus Pool oder instanziiert neu, aktiviert das Objekt              |
| `ReturnAll()`            | Deaktiviert alle aktiven Tiles, gibt sie in Queue zurück (kein Destroy) |
| `DestroyAll()`           | Für Szenen-Cleanup: zerstört alle gepoolten + aktiven Objekte           |

Pool ist pro CellType organisiert (`Dictionary<CellType, Queue<GameObject>>`).

---

### 4. `Assets/Scripts/Map/MapGenerator.cs`

**Entfernt:**
- `useProceduralGeneration`, `proceduralDifficulty`, `runtimeObstacleCount`, `randomizeObstaclePrefab`
- `PlaceRuntimeObstacles()`, `SpawnRuntimeMarkersAndObstacles()`, `HasWalkablePath()`
- Destroy-Loop in `ClearMap()`

**Hinzugefügt:**
- `TilePool tilePool` — wird per `EnsureTilePool()` in `Awake()` automatisch als Component hinzugefügt
- `BuildPrefabMap()` — liefert `Dictionary<CellType, GameObject>` für den Pool
- `EnsureKillZone()` — erstellt **ein persistentes** KillZone-Objekt beim Start
- `RepositionKillZone()` — repositioniert und skaliert die KillZone pro Episode (kein neues GameObject)
- Tile-Loop in `GenerateMap()` nutzt jetzt `tilePool.Get()` statt `Instantiate()`
- `ClearMap()` ruft `tilePool.ReturnAll()` auf (O(n) SetActive statt Destroy+GC)

**Marker** (Goal, SpawnPoint) werden weiterhin per `Instantiate`/`Destroy` verwaltet, da sie Prefab-spezifische Komponenten tragen.

---

### 5. `Assets/Scripts/Map/CurriculumTracker.cs`

**Entfernt:** Hardcoded `if (phase.difficulty == DifficultyLevel.Trivial)` Sonderfall, der Trivial ohne `layouts[]` laufen ließ.

**Alle Phasen** nutzen jetzt einheitlich `phase.layouts[currentLayoutIndexInPhase % phase.layouts.Length]`. Fehlendes `layouts[]`-Array wird als Error geloggt statt ignoriert.

---

### 6. `Assets/Editor/MapGeneratorEditor.cs`

- `DifficultyMask`-Enum von 3 auf 8 Bits erweitert (ein Bit pro DifficultyLevel), `All = ~0`
- `_selectedDiff` als **Klassenfeld** statt lokaler Variable — behebt Bug, bei dem die Schwierigkeit nach jedem GUI-Redraw auf `Easy` zurückgesetzt wurde
- `DifficultyToMask()` und `DifficultyOrder()` für alle 8 Stufen implementiert
- Asset-Namenskonvention: `Layout_P_{DifficultyLevel}_{Nummer:D3}.asset`

---

### Nächste manuelle Schritte

1. In Unity kompilieren (alle 6 Dateien)
2. Im MapGenerator-Inspector pro Schwierigkeit: **Schwierigkeit wählen → Anzahl festlegen → "Layouts generieren & speichern"**
3. `CurriculumConfig` mit 8 Phasen befüllen und die erzeugten Assets den jeweiligen `layouts[]`-Arrays zuweisen


**ProceduralLayoutGenerator.cs — Refactoring Trivial-Familie**

**Problem:** `TrivialCorr`, `TrivialBranch`, `TrivialHole`, `TrivialHazard` hatten je nur `seed % 4` → 4 identische Varianten mit fixierten Konstanten (`roomSize=3`, `corrLen=7`, etc.).

---

**Änderungen:**

`BuildTrivialBase(int seed, bool withBranch)` ersetzt die vier unabhängigen Implementierungen. Parameter werden via `System.Random(seed)` gezogen:

| Parameter                         | Bereich                                        |
| --------------------------------- | ---------------------------------------------- |
| Raumgröße (Spawn/Goal unabhängig) | 2–4                                            |
| Korridorlänge (seg1)              | 4–9                                            |
| Korridorbreite                    | 1–2                                            |
| Ast-Länge (nur `withBranch=true`) | 3–6                                            |
| Ast-Position entlang Korridor     | variabel                                       |
| Ast-Seite                         | beide                                          |
| Spawn/Goal-Tausch                 | ja/nein                                        |
| Grundform (`shapeType`)           | gerade H / gerade V / L(H→unten) / L(V→rechts) |

Rückgabe als `TrivialResult` struct mit `grid`, `branchTip` (Anker der 2×2-Hole-Fläche) und `lavaCell1/2`.

Die vier öffentlichen Funktionen sind jetzt thin wrappers:
- `TrivialCorr` → `BuildTrivialBase(seed, false)` + `PlaceWalls`
- `TrivialBranch` → `BuildTrivialBase(seed, true)` + `PlaceWalls`
- `TrivialHole` → wie Branch + 2×2 `Hole` an `branchTip`
- `TrivialHazard` → wie Hole + `Lava` an `lavaCell1/2`



Zwei Änderungen in MapGenerator.cs:

  - Zeile 216–217: currentGoalWorldPosition bekommt jetzt + new Vector3(0f, 0.5f, 0f) — damit gibt auch GetGoalPosition() die korrekte Höhe zurück.
  - Zeile 389: Instantiate nutzt jetzt direkt currentGoalWorldPosition statt nochmal CellToWorld(...) aufzurufen — kein doppelter Code, konsistente
  Position.

  Das Goal spawnt damit bei y=0.5, Collider-Zentrum bei y=0.5, Radius 0.51 → voller Erkennungsradius auf Bodenhöhe.

  ## V9 feedback
  **Aktueller Stand**

Der Agent ist jetzt bei ca. `8.71M` Steps und läuft noch. Technisch ist das Training stabil: keine Fehler im Error-Log, Checkpoints bis `8.6M`, Losses niedrig/stabil.

Aber: Inhaltlich sehe ich ein klares Warnsignal.

Ab ca. `5M` Steps liegt die `Episode Length` fast permanent bei `1199`. Das sieht sehr nach **Max-Step-Time-Out** aus. Heißt: Viele Episoden enden wahrscheinlich nicht, weil er sauber das Ziel erreicht, sondern weil die Episode am Limit endet.

Gleichzeitig ist der Reward stabil bei ca. `8-10`:

- `5M-6M`: Ø Reward `8.90`
- `6M-7M`: Ø Reward `8.92`
- `7M-8M`: Ø Reward `8.93`
- `8M-8.71M`: Ø Reward `8.92`

Das ist seit mehreren Millionen Steps ein Plateau.

**Meine Diagnose**

Der Agent hat etwas gelernt, aber vermutlich nicht mehr das, was wir wollen.

Er scheint inzwischen eine stabile Strategie gefunden zu haben, die guten Reward bringt, aber nicht zwingend zuverlässig das Ziel erreicht. Der wichtigste Verdacht ist dein Distance-Shaping:

```csharp
AddReward((previousDistance - pbrsGamma * currentDistance) * distanceShapingScale);
```

Mit `pbrsGamma = 0.99` bekommt der Agent sogar dann kleinen positiven Reward, wenn die Distanz ungefähr gleich bleibt. Über `1199` Steps kann sich das zu einem ordentlichen Reward aufsummieren. Das erklärt, warum der Reward hoch ist, obwohl die Episodenlänge fast immer maximal ist.

Kurz gesagt: **Der Agent könnte gelernt haben, lange zu überleben / herumzulaufen, statt schnell zum Ziel zu gehen.**

**Gute Zeichen**

- Reward ist viel höher als am Anfang.
- Losses sind stabil.
- Entropy ist gesunken, aber nicht komplett kollabiert.
- Keine NaNs, keine Abstürze.

**Schlechte Zeichen**

- Episode Length hängt bei `1199`.
- Reward seit `5M` Steps praktisch flach.
- Hoher Reward ist wahrscheinlich teilweise Shaping-Artefakt.
- Weitertraining bis `30M` bringt vermutlich wenig, wenn das Reward-Signal so bleibt.

**Meine Empfehlung**

Ich würde v9 jetzt **stoppen oder beim nächsten Checkpoint beenden**. Nicht weil es kaputt ist, sondern weil es wahrscheinlich ausgelernt hat und gerade eine suboptimale Reward-Strategie stabilisiert.

Für v10 würde ich ändern:

1. Success Rate loggen: Ziel erreicht ja/nein.
2. Reward für Ziel deutlich höher machen, z. B. `+10`.
3. Step penalty stärker machen, z. B. `-0.002` oder `-0.005`.
4. Distance-Shaping vorsichtiger machen oder korrekt terminal auswerten.
5. Episode Length als Hauptdiagnose nehmen: Gute Policy sollte eher kürzere Episoden haben, nicht dauerhaft `1199`.

Mein Urteil: **v9 ist als Experiment wertvoll, aber ich würde es nicht weiter als finale Version trainieren.**

## Änderungen für V10

Änderungen zusammengefasst:

  ┌─────────────┬─────────────────┬────────────────────┬───────────────────────────────────────────────────────────────┐
  │  Parameter  │       Alt       │        Neu         │                             Grund                             │
  ├─────────────┼─────────────────┼────────────────────┼───────────────────────────────────────────────────────────────┤
  │ goalReward  │ 1.0             │ 10.0               │ Ziel muss Wandern klar dominieren                             │
  ├─────────────┼─────────────────┼────────────────────┼───────────────────────────────────────────────────────────────┤
  │ stepPenalty │ -0.001          │ -0.005             │ Langen Episoden stärker bestrafen                             │
  ├─────────────┼─────────────────┼────────────────────┼───────────────────────────────────────────────────────────────┤
  │ pbrsGamma   │ 0.99            │ 1.0                │ Entfernt den (1−γ)·d Term – nur echter Annäherung gibt Reward │
  ├─────────────┼─────────────────┼────────────────────┼───────────────────────────────────────────────────────────────┤
  │ SuccessRate │ nicht vorhanden │ Custom/SuccessRate │ TensorBoard-Metrik, um echte Erfolgsquote zu sehen            │
  └─────────────┴─────────────────┴────────────────────┴───────────────────────────────────────────────────────────────┘

  Mit γ=1.0 gilt jetzt: Distance-Shaping gibt Reward nur wenn der Agent näher kommt (d_prev - d_curr > 0). Das wandernde Verhalten wird nicht mehr belohnt.



  Hier die kurze Doku:

---

## V10 → V11: Änderungen & Begründung

### Problem: Weltachsen-Bewegung (V10)

Der Agent bewegte sich in **Weltkoordinaten** (absolutes Nord/Süd/Ost/West). Das führte zu einem fundamentalen Inkonsistenz-Problem: Raycasts und Zielvektor wurden relativ zum Agenten berechnet, die Bewegung jedoch relativ zur Welt. Ein "vorwärts"-Signal der Policy bedeutete je nach Blickrichtung des Agents etwas völlig anderes — die Policy musste gleichzeitig lernen wohin sie schauen UND wie sie sich in Weltkoordinaten bewegt, was den Lernprozess unnötig erschwerte.

Das äußerte sich in V10 u.a. im **Wand-Hugging**: Da der Agent nicht drehen konnte, blieb er hängen sobald das Ziel nicht in seiner festen Bewegungsrichtung lag.

### Änderungen V11

**Agent-relative Bewegung + Dreh-Action (`LabyrinthAgent.cs`, `Agent.prefab`)**

Bewegung ist jetzt **relativ zur aktuellen Blickrichtung** des Agents (vorwärts/rückwärts). Dazu kommt ein separater Dreh-Branch (links/rechts, 180°/s). Damit liegen Sensorik, Zielrichtung und Aktionen alle im selben Bezugssystem — die Policy muss keine Koordinatentransformation mehr implizit lernen.

Neuer Action-Space `3,3,2`:
- Branch 0: idle / vorwärts / rückwärts
- Branch 1: nicht drehen / links / rechts
- Branch 2: nicht springen / springen

Zielvektor und Velocity werden explizit in lokale Agent-Koordinaten transformiert, bevor sie als Observation übergeben werden.

**`sequence_length`: 8 → 16 (`labyrinth_transformer.yaml`)**

In V10 konnte der Transformer nur 8 Steps Kontext halten — zu wenig um das Muster "ich bewege mich seit Längerem nicht vom Fleck" zu erkennen. Verdopplung auf 16 gibt dem Transformer mehr zeitlichen Kontext bei überschaubarem Compute-Overhead.



## V12
 V11 — Beobachtungen im Detail

### Phase 1: Einfache Maps (0 – ~1.6M Steps)
- **Steps 0–70k:** Extrem volatil, Reward zwischen -1.1 und +0.4. Entropy bei ~2.87 (fast maximale Zufälligkeit). Agent exploriert blind.
- **Steps 70k–150k:** Erste Stabilisierung. Reward klettert auf +0.56, Std fällt von 1.07 auf 0.36. Agent entwickelt erste Strategien.
- **Steps 150k–240k:** Durchbruch. Reward erreicht +0.896 bei Std 0.082 — sehr konsistentes Verhalten. Bei Step 240k Sprung auf **+2.036** (Agent löst mehrere Goals hintereinander in einer Episode).
- **Steps 240k–1.6M:** Konsolidierung bei Reward ~1.5–2.0 mit gelegentlichen Spikes bis +50 (Hochleistungsepisoden). Success Rate stabilisiert sich bei **72–82%**. Episode Length kurz (244–404 Steps). Value Loss niedrig (0.01), Critic konvergiert. Trainingsgeschwindigkeit ~285 Steps/s.

### Phase 2: Lava-Maps (ab ~1.6M Steps)
- **Sofortiger Kollaps:** Success Rate fällt auf **0.000** und bleibt dort für alle beobachteten Steps.
- **Episode Length springt auf Maximum:** 1199 Steps konstant — ausschließlich Timeouts, keine einzige erfolgreiche Episode.
- **Entropy steigt wieder** auf ~2.51 — Agent verliert gelernte Strategie, fällt zurück auf Zufallsverhalten.
- **Value Loss volatil** (0.01 → 0.78 → 0.08): Critic ist durch die neue Umgebung verwirrt, kann Outcomes nicht mehr zuverlässig schätzen.
- **Reward bleibt trotzdem ~6–8** mit Spikes bis +49: Diese Rewards kommen aus dem alten Curriculum-Mix (noch nicht-Lava-Maps im Batch), nicht aus echten Lava-Erfolgen.
- **Training abgebrochen** bei ~2.2M Steps durch `UnityTimeOutException` — Unity reagierte nicht mehr.

---

V12 — Fixes im Detail

### Fix 1: Timeout härter bestrafen als Tod

**Problem:** Bei V11 war `timeout = -1f` und `lava_death = -1f`. Aus Agenten-Sicht war es vollkommen äquivalent, ob er bis zum Zeitlimit herumläuft oder in die Lava springt. Es gab keinen rationalen Grund, ein Risiko einzugehen.

**Fix:** `timeoutPenalty = -2f`, `lavaDeathPenalty = -1f`. Die neue Hierarchie:
```
Timeout        → -2.0f  (absolutes Minimum — passive Niederlage)
Tod            → -1.0f  (aktiver Versuch, auch wenn gescheitert)
Lava-Sprung    → +0.0625f bis +0.5f
Ziel           → +10.0f (Maximum)
```
Der Agent hat jetzt einen konkreten mathematischen Anreiz, lieber zu springen und zu sterben als zu stagnieren. Timeout ist die schlechteste aller möglichen Episoden.

**Implementierung:** In `OnActionReceived` wird bei `StepCount >= MaxStep - 1` die Penalty addiert, bevor das Framework `EndEpisode()` aufruft. Ein `episodeEndedByTerminal`-Flag verhindert Doppelbestrafung wenn Tod und MaxStep zufällig zusammenfallen.

---

### Fix 2: Adrenalin-Reward für Lava-Sprünge

**Problem:** Der Agent hatte bei V11 null positives Feedback beim Annähern oder Überqueren von Lava. Für den Agenten war Lava schlicht eine schwarze Box — er lernte nur "Lava = Ende", nicht "Lava = Hindernis das überwunden werden kann". Ohne Lernsignal keine Strategie.

**Fix:** Beim ersten Eintritt in den Zustand "in der Luft über Lava" gibt es eine Belohnung mit Diminishing Returns:

| Versuch in der Episode | Reward           |
| ---------------------- | ---------------- |
| 1.                     | `+0.5f`          |
| 2.                     | `+0.125f` (1/4)  |
| 3.                     | `+0.0625f` (1/8) |
| 4.+                    | `0f`             |

**Warum Diminishing Returns?** Verhindert Lava-Farming — ohne Reduktion würde der Agent lernen, vor dem Ziel endlos Lava hin- und herzuspringen statt das Ziel anzusteuern.

**Warum kein Extra-Reward beim Goal?** Der Ziel-Reward bleibt fix bei `+10f`, unabhängig davon ob Lava überquert wurde. Sonst hätte der Agent einen Anreiz, absichtlich Lava-Maps zu suchen oder Lava-Routen gegenüber direkten Routen zu bevorzugen.

**Implementierung:** Raycast von `transform.position` nach unten. Bedingungen:
- `!isGrounded` (echter Sprung, kein Bodenkontakt)
- Treffer-Tag = `"Lava"`
- `hit.distance > 0.3f` (Mindestabstand — verhindert Trigger beim bloßen Berühren der Lava-Kante)
- Edge-Trigger via `wasAboveLava`-Flag: Reward nur beim **Eintritt** in den Zustand, nicht jeden FixedUpdate-Frame

---

### Fix 3: WallClimb-Guard erhöht

**Problem:** `wallClimbMaxY = 3.0f` war zu knapp. Bei Plattform-Tiles (+0.75m Höhe) plus Sprung (`jumpForce = 4.5f`, geclamped auf `maxUpwardVelocity = 3.5f`) konnte der Agent theoretisch bis ~2.0m über SpawnY kommen. Auf Plattformen (erhöhter Spawn oder erhöhter Absprungpunkt) waren es potenziell mehr. Das bedeutete: **der Guard feuerte beim legitimen Lava-Sprung** und vergab `-1f` genau in dem Moment, in dem der Adrenalin-Reward `+0.5f` vergeben wird — netto also `-0.5f` statt `+0.5f`. Der Reward-Signal war invertiert.

**Fix:** `wallClimbMaxY = 3.0f` → `5.0f`. Der Guard greift jetzt nur noch bei echtem Wandklettern (Exploit), nicht bei normalen Sprüngen.

---

### Noch offen (bekanntes Problem, kein Fix in V12)

**PBRS-Interferenz mit Lava:** Das Potential-Based Reward Shaping (`distanceShapingScale = 0.02f`) belohnt jede Annäherung ans Ziel — auch wenn die direkte Route durch Lava führt. Das kann den Agenten aktiv in die Lava lenken. Eine Reduktion von `distanceShapingScale` oder ein lava-bewusstes Shaping wäre ein möglicher V13-Fix, wurde aber für V12 noch nicht umgesetzt um nicht zu viele Variablen gleichzeitig zu ändern.


## Doku — v12 Overnight-Run & v13 Vorbereitung

### v12 Training Setup

**Run-ID:** `v12_overnight_002`
**Architektur:** PPO mit Transformer-Memory (256 hidden, sequence_length 16, memory_size 128)
**Parallelisierung:** 6 headless Unity-Instanzen × 16 Training-Areas = **96 parallele Agents** auf RTX 3050 + Ryzen 5 5625U

**Hyperparameter:**
- batch_size 1024, buffer_size 81920
- gamma 0.99, epsilon 0.2, beta 1e-3
- max_steps 60M (insgesamt erreicht: ~30M in 7h49min)
- ~1058 Steps/Sek über alle Agents

**Curriculum:** 8 Phasen mit Episoden-Schwellenwerten
Trivial → TrivialCorr → TrivialBranch → TrivialHole → TrivialHazard → Easy → Medium → Hard

---

### Beobachtungen während des Runs

**Trivial bis TrivialHole (0–3h28):** sauberer Lernverlauf
- Reward stieg von 0.55 → ~5.0
- Entropy von 2.80 → 1.73 (klares Lernen)
- Episode Length sank ständig

**TrivialHazard (3h28–5h01):** erste Probleme
- Reward blieb positiv (3.3–5.3), aber Episode Length konstant **1199** (Timeout)
- Agent hat Lava **nicht überquert** sondern **umgangen**
- PBRS-Reward + kleine Distanz-Annäherung halten Cumulative Reward künstlich oben
- Entropy stieg leicht auf 2.07 — Agent musste re-explorieren, aber nicht erfolgreich

**Easy (5h01–7h28):** Plateau
- Reward stabil ~4.0–4.6 — aber wieder Timeouts (Episode Length 1199)
- Agent kann Maps grob navigieren, erreicht Goal aber selten direkt

**Medium (~7h30+):** Einbruch
- Reward fiel auf 2.66 — größere Maps + erste Lava-Hazards = Agent überfordert
- Entropy 1.96, lernt aber langsam

---

### Diagnose: Warum schaffte der Agent TrivialHazard nicht?

Drei strukturelle Fehler, nicht ein Verhaltensfehler:

### 1. Discount-Faktor versteckte das Goal
`γ = 0.99` bei Episode 1200 Steps:
```
Goal-Reward gesehen von Step 0: 10 × 0.99^1200 ≈ 0
Goal-Reward gesehen von Step 1100: ≈ 3.7
```
Das Goal war effektiv nur in den letzten ~200 Steps sichtbar. Alle früheren Aktionen wurden ausschließlich von PBRS (Distanz-Shaping) gelernt.

### 2. PBRS belohnt die falsche Sache
PBRS basiert auf **Euklidischer Distanz**, nicht auf Pfaddistanz. Wenn Lava den Weg blockiert, kann der Agent näher ans Goal kommen (Luftlinie) ohne es zu erreichen → kassiert positive PBRS → bleibt vor der Lava stehen statt zu überqueren.

### 3. Avoidance aus TrivialHole transferierte
Agent lernte in TrivialHole: gefährliche Felder = -1 = wegbleiben. Diese Avoidance wurde so dominant, dass er in TrivialHazard nie nahe genug an die Lava kam, um zufällig drüber zu springen und den `lavaAttemptBaseReward` zu kassieren.

### Bonus-Problem: Lava-Jump-Reward war farmbar
+0.5 nur für "in der Luft über Lava sein" (decay nach 3 Versuchen) ist:
- konzeptionell falsch (lehrt "Sprung über Lava ist gut" statt "Hindernisse überqueren um Goal zu finden")
- ausnutzbar (Agent könnte hin- und herhüpfen)
- nach 3 Versuchen wertlos

---

## v13 Änderungen

| Datei                        | Parameter               | Alt → Neu                                                        | Wirkung                                                  |
| ---------------------------- | ----------------------- | ---------------------------------------------------------------- | -------------------------------------------------------- |
| `labyrinth_transformer.yaml` | `extrinsic.gamma`       | 0.99 → **0.997**                                                 | Planungshorizont von ~100 auf ~330 Steps — Goal sichtbar |
| `labyrinth_transformer.yaml` | `curiosity`             | – → **strength 0.05**                                            | Intrinsische Belohnung für unbekannte Zustände           |
| `LabyrinthAgent.cs`          | `goalReward`            | 10 → **30**                                                      | Goal dominiert Step-Penalty + Death deutlich             |
| `LabyrinthAgent.cs`          | `timeoutPenalty`        | -2 → **-5**                                                      | Stillstand wird teurer als Risiko                        |
| `LabyrinthAgent.cs`          | `lavaAttemptBaseReward` | 0.5 → **0**                                                      | Farmbares Wrong-Concept-Signal entfernt                  |
| `LabyrinthAgent.cs`          | `distanceShapingScale`  | 0.02 → **0.005**                                                 | PBRS-Dominanz reduziert                                  |
| `LabyrinthAgent.cs`          | `phaseMaxSteps[]`       | global 1200 → **600 Trivial, 1000 Easy, 1500 Medium, 2000 Hard** | Curriculum-aware MaxStep, bessere Credit Assignment      |

---

### Warum diese Änderungen helfen sollten

**γ = 0.997 + goalReward 30:** Das Goal strahlt durch die gesamte Wertfunktion. Aktionen früh im Episode können mit dem Goal-Reward verknüpft werden. Erwartungswert von "Versuche, die Lava zu überqueren" wird positiv: selbst bei 30% Erfolgsrate ist EV = 0.3×30 - 0.7×1 = +8.3 statt vorher ~0.

**Curiosity (strength 0.05):** Klassische intrinsische Motivation. Agent bekommt automatisch Reward für unerforschte Zustände. Bereits-erkundete Map-Bereiche verlieren ihren Bonus, **unerforschte Bereiche hinter der Lava sind hoch belohnt** → Agent muss aktiv neue Wege suchen. Nicht farmbar: Novelty nimmt mit Erfahrung ab.

**timeoutPenalty -5:** Vorher war Timeout (-2) milder als Lavatod (-1). Stillstand war "billig". Jetzt ist Untätigkeit klar die schlechteste Option → Agent muss entscheiden.

**lavaAttemptBaseReward 0 + distanceShapingScale 0.005:** Die "falschen" Lernsignale werden entfernt/abgeschwächt. Agent lernt nicht "spring über Lava" sondern "finde Pfad zum Goal" — wenn das Goal hinter Lava liegt, ergibt sich Springen organisch.

**phaseMaxSteps:** In Trivial-Phasen sind die Maps 7×7 — 1200 Steps sind absurd viel Zeit. Mit 600 Steps:
- Mehr Episoden pro Trainingszeit → bessere Statistik
- Tighter Credit Assignment (Goal-Reward zeitlich näher an Aktionen)
- Timeout-Strafe wird in absehbarer Zeit relevant
- Agent muss decisive sein, kein endloses Wandern

In Hard wird MaxStep auf 2000 erhöht, da diese Maps physisch größer sind und mehr Schritte brauchen.

---

### Erwartung für v13

Mit diesen Änderungen sollte der Agent in TrivialHazard:
1. Aktiv die Lava-Zone erkunden (Curiosity zieht ihn dorthin)
2. Bei einem zufälligen Sprung das Goal entdecken (γ erhöht → Goal-Reward strahlt zurück)
3. Sprung als gelernte Strategie verfestigen, weil Goal-Reward (+30) Death-Risiko (-1) klar überwiegt

Risiko: Curiosity kann Training initial instabiler machen. Falls Reward in Phase 0-1 abstürzt statt zu steigen, ist `curiosity.strength` zu hoch → auf 0.02 reduzieren.


## v13 Run — Post-Mortem

### Run-Stand bei Abbruch
- **Run-ID:** `v13`
- **Steps:** ~17.5M von 60M
- **Laufzeit:** ~5h20min
- **Throughput:** ~950 steps/sec
- **Endstand Curriculum:** Player-0/1/2/3 in Phase 3 (TrivialHole), Player-4/5 in Phase 2 (TrivialBranch)
- **Lava (Phase 4) wurde nie erreicht**

### Was schiefgelaufen ist

Der Run war **kein echter v13-Run**, sondern eine **kaputte Hybrid-Konfiguration**:

- **Python-seitig korrekt** (YAML wurde geladen): γ=0.997, Curiosity strength 0.05, batch 1024, transformer 256/16/128
- **Unity-seitig falsch (Prefab nicht aktualisiert):** Source-Code-Änderungen für v13 wurden nie ins `Assets/Prefabs/Agent/Agent.prefab` synchronisiert. Unity-Builds nutzen die Serialisierung im Prefab, nicht die C#-Defaults.

### Konkrete Mismatches

| Parameter               | v13 Source (Soll)                           | Prefab/Build (Ist)              | Konsequenz                                                                          |
| ----------------------- | ------------------------------------------- | ------------------------------- | ----------------------------------------------------------------------------------- |
| `goalReward`            | **30**                                      | **1**                           | Goal-Anreiz im Rauschen — Agent geht nicht zielgerichtet zum Goal                   |
| `timeoutPenalty`        | **-5**                                      | nicht serialisiert              | Timeout wird kaum bestraft, Wandern bleibt billig                                   |
| `lavaAttemptBaseReward` | **0**                                       | nicht serialisiert (alt: 0.5)   | Falsches Konzept-Signal "Lava-Sprung ist gut" könnte noch aktiv sein                |
| `distanceShapingScale`  | **0.005**                                   | **0.02**                        | PBRS 4× zu dominant — Agent stoppt bei Distanz-Annäherung                           |
| `pbrsGamma`             | **1.0**                                     | **0.99**                        | PBRS-Discount aktiv                                                                 |
| `phaseMaxSteps[]`       | `{600,600,600,600,600,1000,1500,2000}`      | **null** (Feld fehlt im Prefab) | Override greift nicht                                                               |
| `Agent.MaxStep`         | (sollte 0 sein, damit phaseMaxSteps greift) | **6000**                        | Episoden bis 6000 Sim-Ticks ≈ 1200 Decision-Steps — viel zu lang für Trivial-Phasen |

### Welche Symptome das erklärt hat

1. **EpLen erreichte 1199 (Decision-Cap)** statt der erwarteten 600 → weil MaxStep=6000 statt phaseMaxSteps[3]=600
2. **SuccessRate-Crash auf 0%** in Phase 3 → Goal-Reward von +1 wurde von Curiosity-Reward (~7-9) komplett überlagert; Agent verlor Goal-Orientierung und wanderte
3. **Reward-Oszillation 3 ↔ 95** mit Std bis 190 → Curiosity-Spikes dominierten, keine stabile Goal-Politik
4. **Hohe Curiosity-Werte (Reward ~8.7, ValueEstimate ~1.0)** → Agent wurde primär durch Exploration belohnt
5. **Plateau-Reward ~2-5** → Mix aus PBRS-Annäherung + Curiosity, nicht aus Goals

### Was gelernt wurde — trotzdem nützlich

- Curriculum-Mechanik funktioniert (Phasenwechsel sauber via Episode-Counter)
- 6-Unity-Setup mit ML-Agents-spawned Builds stabil (kein Crash, alle 6 durchgehend aktiv)
- Player-4/5 sind systematisch langsamer als Player-0-3 (CPU-Contention) — gleiches Muster wie v12
- Custom-Stats (SuccessRate, LavaJumpAttempts) sind nützliche Diagnose-Tools
- **Phasen-Logging fehlt in TensorBoard** — Phase nicht direkt sichtbar, nur über Player-Logs ableitbar

### Änderungsvorschlag für v13_002

### 1. Prefab-Fix (KRITISCH — ohne das ist jeder Run ein Mock-v13)

`Assets/Prefabs/Agent/Agent.prefab` im Inspector aktualisieren:
- `goalReward = 30`
- `timeoutPenalty = -5`
- `lavaAttemptBaseReward = 0`
- `distanceShapingScale = 0.005`
- `pbrsGamma = 1.0`
- `phaseMaxSteps`-Array befüllen: `[600, 600, 600, 600, 600, 1000, 1500, 2000]`
- `MaxStep = 0` (damit `phaseMaxSteps` greifen kann — der Override-Pfad setzt MaxStep zur Laufzeit)

### 2. Build neu erstellen

`builds/KI Agenten.exe` muss neu gebaut werden — der laufende Build hat die alten Werte einkompiliert in der Szene-Serialisierung.

### 3. Phasen-Logging einbauen (für Diagnose)

In `Assets/Scripts/Agent/LabyrinthAgent.cs` bei `OnEpisodeBegin()` neben den bestehenden Custom-Stats ergänzen:
```csharp
Academy.Instance.StatsRecorder.Add("Custom/CurriculumPhase", CurriculumTracker.CurrentPhaseIndex);
```
→ Damit ist die Phase direkt in TensorBoard sichtbar (kein Player-Log-Parsing mehr nötig).

### 4. Verifikations-Schritt vor Run-Start

Nach Build und Trainer-Start die ersten ~5 Minuten Player-Log prüfen auf:
- `[Episode] Neue Episode. … Letzter Cumulative Reward:` → Reward-Range plausibel?
- `[Timeout] MaxStep=600 erreicht` (NICHT 6000!) → bestätigt phaseMaxSteps greift
- Ein paar `[Ziel] Ziel erreicht | Reward=30` (NICHT Reward=1) → bestätigt goalReward übernommen

### 5. Optional — Curiosity-Strength reduzieren

Falls v13_002 zeigt dass Curiosity zu dominant ist (z.B. CuriosityReward > 0.5 × ExtrinsicReward konstant), in `config/labyrinth_transformer.yaml` reduzieren:
- `curiosity.strength: 0.05 → 0.02`

Erstmal aber mit 0.05 probieren — die ist nur problematisch im Verbund mit goalReward=1.

### Empfohlene neue Run-ID

`v13_002` (nicht `v13` überschreiben — die Logs sind als Negativ-Beispiel wertvoll für die Dokumentation).



### am code geändert: 
**Geänderte Dateien:**

- `Assets/Prefabs/Agent/Agent.prefab` (LabyrinthAgent-Component):
  - `MaxStep`: 6000 → 0 (Override aus `phaseMaxSteps` greift)
  - `goalReward`: 1 → 30
  - `distanceShapingScale`: 0.02 → 0.005
  - `pbrsGamma`: 0.99 → 1
  - **Neu:** `timeoutPenalty: -5`, `lavaAttemptBaseReward: 0`, `phaseMaxSteps: [600,600,600,600,600,1000,1500,2000]`

- `Assets/Scripts/Agent/LabyrinthAgent.cs` (`OnEpisodeBegin`):
  - **Fix Reihenfolge-Bug:** `MaxStep`-Zuweisung nach `mapGenerator.GenerateRuntimeMap()` verschoben — sonst lief die erste Episode nach Phasenwechsel mit dem MaxStep der alten Phase.
  - **Neu:** `Academy.Instance.StatsRecorder.Add("Custom/CurriculumPhase", CurriculumTracker.CurrentPhaseIndex)` → Phase als TensorBoard-Metrik.


## V14 — Komplette Trainingsanalyse

### 1. Setup

|                      |                                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------ |
| **Run-ID**           | `v14`                                                                                                  |
| **Architektur**      | PPO + Transformer-Memory                                                                               |
| **Network**          | 256 hidden units, 2 MLP-Layer, Transformer-Memory (seq_len=16, memory_size=128, nhead=4, 2 Attn-Layer) |
| **Reward Signals**   | Extrinsic (γ=0.997, strength=1.0) + Curiosity (strength=0.05)                                          |
| **Hyperparameter**   | lr=1e-4 (linear schedule), batch=1024, buffer=81920, beta=1e-3, eps=0.2, 3 epochs                      |
| **Parallelisierung** | 6 headless Unity-Builds × 16 Training-Areas = **96 parallele Agents**                                  |
| **Curriculum**       | 8 Phasen: 5× Trivial → Easy → Medium → Hard. MaxStep pro Phase: 600/600/600/600/600/1000/1500/2000     |
| **Hardware**         | Ryzen 5 5625U + RTX 3050                                                                               |

### 2. Trainings-Zeitlinie

|                               |                                                           |
| ----------------------------- | --------------------------------------------------------- |
| **Erreichter Step**           | **31.220.000 / 60.000.000** (52.0%)                       |
| **Trainingszeit**             | **10h 9min** (36.544 s)                                   |
| **Effektive Geschwindigkeit** | **854 Steps/Sek** (alle 96 Agents zusammen)               |
| **Auto-Checkpoints**          | alle 500k Steps, 5 zuletzt (29M–31M)                      |
| **Manueller Save**            | `results/v14/manual_save/LabyrinthNavigator-30999943.pt`  |
| **Abbruchgrund**              | bewusst abgebrochen — Plateau seit Step ~13M festgestellt |

### 3. Phasen-Performance — Final-Aggregat

| Phase               | Eps     | Goal%     | ⌀Reward | ⌀Steps | Tode/Lava  | Tode/Other | Timeouts |
| ------------------- | ------- | --------- | ------- | ------ | ---------- | ---------- | -------- |
| 0 Trivial           | 7.110   | **65.5%** | -3.66   | 349    | 0          | 0          | 4.721    |
| 1 TrivialCorr       | 10.800  | **62.6%** | -4.17   | 461    | 0          | 0          | 8.090    |
| 2 TrivialBranch     | 15.600  | **78.4%** | -2.54   | 419    | 0          | 0          | 6.753    |
| 3 TrivialHole       | 21.600  | **79.4%** | -1.79   | 389    | 0          | 1.353      | 6.203    |
| **4 TrivialHazard** | 30.000  | **0.2%**  | -0.95   | 245    | **27.967** | 25         | 3.910    |
| 5 Easy              | 48.000  | **3.5%**  | -1.69   | 359    | 34.556     | 5.221      | 13.116   |
| 6 Medium            | 72.000  | **4.4%**  | -1.64   | 461    | 44.433     | 15.656     | 17.474   |
| 7 Hard              | 109.129 | **21.0%** | -2.78   | 711    | 40.635     | 22.995     | 45.245   |

### 4. Lernkurven innerhalb jeder Phase (Buckets à 1000 Eps)

**Phase 0 Trivial** — sauberer Anstieg:
```
49% → 51% → 54% → 63% → 71% → 87% → 80% → 100%
```

**Phase 1 TrivialCorr** — moderates Lernen:
```
51 → 62 → 54 → 59 → 59 → 56 → 64 → 65 → 78 → 65 → 80%
```

**Phase 2 TrivialBranch** — stetig:
```
66 → 78 → 75 → 71 → 80 → 69 → 76 → 80 → 74 → 83 → 82 → 83 → 88 → 83 → 85 → 86%
```

**Phase 3 TrivialHole** — Plateau auf hohem Niveau:
```
73 → 77 → 82 → 81 → 74 → 79 → 83 → 77 → 78 → 82 → 82 → ... → 81 → 83 → 74%
```

**Phase 4 TrivialHazard** — totale Wand, 30k Episoden ohne Lerneffekt:
```
1% 0% 0% 0% 0% 1% 0% 0% 0% 0% 1% 0% ...
```

**Phase 5 Easy** — flach bei 3-5%, kein Trend:
```
2 → 4 → 3 → 3 → 4 → 3 → 4 → 3 → ... → 3 → 4%
```

**Phase 6 Medium** — minimal besser, gleiches Bild:
```
4 → 4 → 5 → 4 → 5 → ... → 4 → 5%
```

**Phase 7 Hard** — **das spannendste Muster — drei Lern-Vergessens-Zyklen:**
```
Block A:  7→11→16→19→20→18→23→22→22→21→20→22→24→23→27→23→25→22→26→25→22→25→20→24→25→26→22→25→25→23
Block B: 10→ 8→ 8→14→17→18→19→18→19→20→22→24→22→22→24→27→25→23→23→26→24→26→24→24→24→26→24→25→23→19
Block C:  6→ 9→15→16→18→19→17→20→19→22→26→23→22→22→25→24→25→24→24→23→23→23→24→24→24→22
Final:   13→ 9→12→14→17→22→22→22→23→25→25→21→25→26→23→23→26→24→24→23→28→19→ 4→ 5%
```

**Drei klare Crash-Recovery-Zyklen** — Agent erreicht ~25%, fällt auf 6-13%, erholt sich, fällt wieder. Das ist **klassisches Catastrophic Forgetting** oder PPO-Exploration-Schwankung. Die letzten zwei Buckets bei 4-5% zeigen einen weiteren Crash bei Trainings-Ende.

### 5. Reward-Trajektorie (TensorBoard, 13 Stützpunkte)

| Step   | Reward     | EpLen | Entropy | ValEst | Phase (dominierend)               |
| ------ | ---------- | ----- | ------- | ------ | --------------------------------- |
| 2.52M  | **+20.64** | 80    | 1.64    | 23.59  | **Phase 3 Peak**                  |
| 5.12M  | +2.41      | 69    | 1.56    | 2.58   | Übergang in Phase 4               |
| 7.54M  | **-2.57**  | 74    | 1.79    | -1.38  | **Phase 4 Wall** (Entropy steigt) |
| 10.26M | -0.38      | 70    | 1.52    | 0.16   | Phase 5 Start                     |
| 12.46M | +0.10      | 83    | 1.48    | 0.91   | Phase 5                           |
| 14.64M | +2.24      | 81    | 1.39    | 2.65   | Phase 5 Ende                      |
| 16.92M | +4.71      | 79    | 1.57    | 4.67   | Phase 5/6                         |
| 19.24M | +3.92      | 145   | 1.58    | 4.02   | Phase 6 (EpLen steigt)            |
| 21.56M | +1.23      | 196   | 1.34    | 3.41   | Phase 6/7                         |
| 23.94M | +0.72      | 194   | 1.15    | 3.54   | Phase 7 Beginn                    |
| 26.22M | +2.67      | 217   | 1.12    | 6.06   | Phase 7                           |
| 28.52M | +1.30      | 205   | 1.05    | 5.08   | Phase 7                           |
| 31.02M | **-7.54**  | 98    | 1.06    | 3.89   | Phase 7 Crash-Ende                |

**Wichtigste Beobachtung:** Reward-Peak bei Step 2.5M mit +20.6 (in Phase 3). Danach kontinuierlicher Abfall, nur zwischenzeitliche Erholung in Phase 7 mit Maximum +4.7 — **die +20 wurden nie wieder erreicht**. Ende mit Reward = -7.54 deutet auf einen finalen Crash hin.

### 6. Der Lava-Sprung-Skandal

Das Logging zählt jeden Sprung über Lava als "LavaJump". Die Realität:

| Phase           | Sprünge gesamt | in Erfolgen | in Fehlern | **Sprung→Tod Rate** |
| --------------- | -------------- | ----------- | ---------- | ------------------- |
| 4 TrivialHazard | 11.415         | 5           | 11.410     | **99.96%**          |
| 5 Easy          | 16.895         | 607         | 16.288     | 96.4%               |
| 6 Medium        | 19.449         | 495         | 18.954     | 97.5%               |
| 7 Hard          | 14.838         | 157         | 14.681     | **98.9%**           |

**Übersetzt:** Wenn der Agent in Phase 7 versucht über Lava zu springen, **stirbt er in 99 von 100 Fällen**. Der Agent hat nicht "Lava springen" gelernt — er hat gelernt, **Lava komplett zu vermeiden**:

| Phase      | Erfolge ohne Sprünge | Erfolge mit Sprüngen |
| ---------- | -------------------- | -------------------- |
| 5 Easy     | 1.144                | 521                  |
| 6 Medium   | 2.719                | 455                  |
| **7 Hard** | **22.740**           | **137**              |

In Phase 7 erfolgen **99.4% aller Goal-Erreichungen ganz ohne Lava-Sprung** — der Agent navigiert um Hazards herum. Bei den 137 mit-Sprung-Erfolgen war's vermutlich nur ein einzelner ungefährlicher Sprung gegen Ende einer ohnehin geschafften Episode.

### 7. Was funktioniert — was nicht

**✅ Funktioniert sehr gut:**
- Reine Labyrinth-Navigation (Phasen 0-3, alle >60% Success, Phase 0 auf 100% gelernt)
- Hindernis-Umgehung (Phase 3 TrivialHole mit 79% trotz Hindernissen, keine Lava-Tode)
- PPO + Transformer-Architektur grundsätzlich (Critic kalibriert sich, Entropy fällt geordnet)

**⚠️ Funktioniert mittelmäßig:**
- Hard-Navigation: 21% Success-Rate, durchsetzt von Crash-Recovery-Zyklen
- Lava-Vermeidung (keine direkten Sprünge): der Agent weiß, dass Lava tödlich ist und meidet sie

**❌ Funktioniert gar nicht:**
- Lava-Springen / Hazard-Traversierung: 99% Tod-Rate beim Sprungversuch
- Phase 4 (TrivialHazard) als Bridge-Phase
- Lernen bei kombinierten Hazards in Easy/Medium

### 8. Diagnose der Bottlenecks

**Hauptproblem: Curriculum-Stufe von Phase 3 (TrivialHole) zu Phase 4 (TrivialHazard) zu steil.**

Phase 3 hatte Hindernisse (Löcher) ohne Tod-Mechanik. Phase 4 führte abrupt Lava ein — eine völlig neue Mechanik, die Tod auslöst. Der Agent hatte 30.000 Episoden Zeit, hat aber **gar keinen Fortschritt** gemacht. Der Lernsignal war:
- 87.6% Tod → -1 Penalty
- 13% Timeout → -5 Penalty (Anti-Stehen-bleiben)
- 0.2% Erfolg → +30 Reward

Das Verhältnis war so ungünstig, dass der Agent nie genug positive Trajektorien gesammelt hat, um Hazard-Avoidance zu lernen. Vermutlich hat er stattdessen gelernt: **"Lava = sterben → niemals in Lava-Nähe gehen"** — was in Easy/Medium funktioniert (= um Lava herum), aber nicht in Hard wo Sprünge nötig wären.

**Sekundäres Problem: Catastrophic Forgetting in Phase 7.**

Die drei klaren Reset-Zyklen in der Phase-7-Lernkurve deuten darauf hin, dass der Agent Strategien wieder vergisst, sobald er stark explorativ wird (Entropy bleibt bei 1.05-1.06). PPO mit linearem LR-Schedule auf 1e-4 plus Curiosity-Signal könnte den Optimierer immer wieder aus stabilen Politiken herausschmeißen.

**Tertiärproblem: Logging-Inkonsistenz.**

`LavaJumps` wird beim "betreten der Lava-Zone" gezählt — egal ob der Agent's nächster Step ein erfolgreicher Sprung war oder ein Tod. Das verfälscht die Statistik. Sauberer wäre: zwei separate Counter "LavaJumpsAttempted" und "LavaJumpsSuccessful".

### 9. Empfehlungen für den nächsten Run

1. **Curriculum-Stufe Phase 4 sanfter gestalten:**
   - Schmälere Lava-Streifen
   - Höheres Step-Budget (z. B. 1500 statt 600)
   - Optional: Verhalten "Stehen bleiben in Lava-Nähe" mit kleinem positiven Reward belohnen, bevor man Sprünge erzwingt

2. **Reward-Shaping für Hazard-Traversierung:**
   - Aktuell: Lava-Sprung +0 bis Erfolg, dann +30. Lava-Tod -1.
   - Vorschlag: erfolgreichen Lava-Sprung mit +5 belohnen (Zwischenziel), unabhängig vom Goal-Erreichen
   - Damit hat der Agent ein dichteres Trainingssignal für Hazard-Skills

3. **Anti-Forgetting-Maßnahmen:**
   - Phase-Mixing: nicht 100% Phase 4 für 30k Episoden, sondern 70% Phase 4 + 30% Phase 3 (Wiederholung um Basis nicht zu vergessen)
   - Niedrigere learning_rate in späten Phasen (z. B. lr-Schedule, das ab Phase 5 noch flacher wird)

4. **Logging-Fix:**
   - `LavaJumpsAttempted` zählen wenn Agent in Lava-Zone springt
   - `LavaJumpsSuccessful` nur zählen wenn Agent die Lava-Zone heil verlässt
   - Beides separat loggen

5. **Längere Phasen für die schweren:**
   - Phase 4: aktuell 5000 Episoden Limit → mind. 15000
   - Phase 5/6: aktuell 4000/6000 → mind. 10000 jeweils

### 10. Artefakte für Wiederverwendung

```
results/v14/
├── manual_save/
│   ├── LabyrinthNavigator-30999943.pt   (28 MB, Policy state_dict)
│   ├── checkpoint.pt                    (28 MB, Optimizer + Policy)
│   └── v14_actor.pt                     (4.8 MB, TorchScript)
├── LabyrinthNavigator/
│   ├── *.pt                             (Auto-Checkpoints 29M-31M)
│   └── events.out.tfevents.*            (TensorBoard, ~17 MB)
└── run_logs/Player-0..5.log             (Episode-Logs, ~400 MB total)

config/labyrinth_transformer.yaml         (Trainingskonfig v14)
Dokumentation/Trainingsanalyse_Transformer_Milestone7.md  (vorherige Dok, M)
```

### TL;DR

V14 hat die **reine Navigation gemeistert** (Phasen 0-3 mit 60-100% Success) und ist **an Hazard-Avoidance gescheitert**. Phase 4 war ein Curriculum-Bottleneck mit 30.000 Episoden ohne Lerneffekt. In Phase 7 (Hard) erreicht der Agent zwar 21% Success — aber durch **Umgehen von Lava**, nicht durch Springen. Das Training-Plateau ab Step 13M war kein Architektur-Problem (PPO+Transformer arbeiten technisch sauber, Critic kalibriert), sondern ein **Curriculum-Problem**. Nächster Run braucht sanftere Hazard-Einführung, dichteres Reward-Signal für Sprünge und Anti-Forgetting-Mixing.

### Beobachtung mit trainiertem Modelle:
**Live-Beobachtung beim Inference-Test (3 verschiedene Hard-Maps, MaxStep=2000, alle Settings korrekt konfiguriert):** Auf keiner der drei getesteten Maps konnte eine Episode beobachtet werden, in der der Agent das Ziel erreicht hat. Es konnte ebenfalls keine erfolgreiche Lava-Überquerung beobachtet werden — der Agent ist bei jedem Sprungversuch in der Lava gestorben. Auffällig war zudem ein Logging-Bug: der `LavaJumps`-Counter wurde auch dann erhöht, wenn der Agent direkt im Anschluss durch die Lava gestorben ist — der Counter trennt also nicht zwischen erfolgreichen Sprüngen und tödlichen Versuchen. Diese Beobachtungen bestätigen die aggregierten Trainingsdaten qualitativ: die 21% Goal-Rate in Phase 7 entsteht durch Lava-Umgehung, nicht durch Lava-Sprünge, und das Verhalten ist auf einzelnen fixen Maps stark anfällig für lokale Schwächen der Policy.