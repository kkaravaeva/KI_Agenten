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