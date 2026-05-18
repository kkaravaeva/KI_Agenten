# Übersicht:
| Version / Schritt            | Hauptproblem                                 | Änderung / Fix                                    | Ergebnis / Effekt                                   |
| ---------------------------- | -------------------------------------------- | ------------------------------------------------- | --------------------------------------------------- |
| Initial (Transformer + LSTM) | Kein Lernen, Reward konstant ~-2.45          | Analyse der PPO-Ratio + Sparse-Reward-Problematik | Zwei unabhängige Bugs identifiziert                 |
| Bug 1 Analyse                | Transformer trainiert seq=8, inferiert seq=1 | Rolling-Sequence-Konzept geplant                  | Ursache für ungültige PPO-Ratio gefunden            |
| Bug 2 Analyse                | Goal wird nie erreicht                       | PBRS vorgeschlagen + Easy-Maps                    | Reward-Signal als Hauptblocker identifiziert        |
| Fix 1                        | PPO-Ratio inkonsistent                       | Rolling-Buffer für letzte 7 Encodings             | Inference- und Trainingskontext identisch           |
| Fix 2                        | Sparse Reward                                | Trivial-Maps + Curriculum + höhere MaxSteps       | Agent bekommt erstmals erreichbare Goals            |
| Fix 3                        | Wall-Climb Exploit                           | Out-of-Bounds-Guard + Velocity-Clamp              | Rewards normalisieren sich, mehr Goals              |
| v5                           | Kein Lernen                                  | Ursprünglicher Transformer                        | Entropy bleibt ~2.27                                |
| v6                           | Zu hohe Entropy-Regularisierung              | Causal Mask + LR runter                           | Erste leichte Entropy-Abfälle                       |
| v7                           | Value-Kollaps                                | Beta reduziert auf 1e-3                           | Stark bessere Konvergenz                            |
| v8                           | Zu kleine Advantage-Statistik                | Buffer 4× größer                                  | Stabilere PPO-Updates                               |
| Goal-Fix                     | Goal halb im Boden                           | Goal-Y auf 0.5 korrigiert                         | Trigger-Radius korrekt                              |
| Trivial-Refactor             | Nur 4 Layouts → Memorization                 | Seed-basierte Variationen                         | Mehr Generalisierung                                |
| TilePool-System              | Destroy/Instantiate teuer                    | Pooling eingeführt                                | Weniger GC + stabilere Runtime                      |
| Curriculum-Rework            | Harte Difficulty-Sprünge                     | 8 Difficulty-Stufen                               | Feineres Curriculum                                 |
| Trivial-Familie Refactor     | Zu wenige Varianten                          | Parametrisierte Generatoren                       | Deutlich mehr Layoutdiversität                      |
| v9                           | Reward-Exploiting / Wandern                  | Analyse des PBRS-Verhaltens                       | Plateau bei Reward ~9 erkannt                       |
| v10                          | Timeout-Strategie profitabel                 | goalReward=10, stepPenalty=-0.005, pbrsGamma=1    | Wandern nicht mehr lohnend                          |
| v11                          | Weltachsen-Bewegung                          | Agent-relative Bewegung + Turn-Action             | Sensorik und Aktionen konsistent                    |
| v11                          | Zu wenig zeitlicher Kontext                  | sequence_length 8→16                              | Mehr Memory-Kontext                                 |
| v12                          | Lava komplett ungelöst                       | timeoutPenalty=-2, Lava-Adrenalin-Reward          | Agent versucht erstmals Sprünge                     |
| v12                          | WallClimb kollidiert mit Lava-Sprüngen       | wallClimbMaxY 3→5                                 | Legitime Sprünge nicht mehr bestraft                |
| v13                          | Goal zu weit „wegdiscountet“                 | gamma 0.99→0.997                                  | Langfristige Rewards sichtbarer                     |
| v13                          | Zu wenig Exploration                         | Curiosity eingeführt                              | Intrinsische Exploration                            |
| v13                          | PBRS zu dominant                             | distanceShapingScale 0.02→0.005                   | Weniger Distanz-Ausnutzung                          |
| v13                          | Episoden viel zu lang                        | phaseMaxSteps je Difficulty                       | Besseres Credit Assignment                          |
| v13 Post-Mortem              | Prefab-Werte nicht übernommen                | Prefab-Fix + Build-Rebuild nötig                  | Training lief mit Hybrid-Konfig                     |
| v13_002 Fix                  | MaxStep Override kaputt                      | MaxStep=0 + phaseMaxSteps aktiv                   | Richtige Episodenlimits                             |
| v13_002 Fix                  | Keine Phasen-Transparenz                     | CurriculumPhase-Logging                           | Phase direkt in TensorBoard sichtbar                |
| v14                          | Große Gesamtanalyse                          | Vollständige Ursachenanalyse                      | Curriculum statt Architektur als Bottleneck erkannt |
| v14 Ergebnis                 | Navigation gelernt                           | 60–100% Success in frühen Phasen                  | PPO+Transformer grundsätzlich funktional            |
| v14 Problem                  | Lava-Sprünge scheitern                       | Analyse zeigt 99% Todesrate                       | Agent umgeht Lava statt zu springen                 |
| v14 Diagnose                 | Catastrophic Forgetting                      | Crash-Recovery-Zyklen identifiziert               | Hard-Phase instabil                                 |
| V15 Analyse A1               | Reward-Vakuum beim Sprung                    | Erfolgreiche Landung soll Reward geben            | Sprung bekommt erstmals direktes Signal             |
| V15 Analyse A2               | PBRS belohnt Lava-Umgehung                   | PBRS über Lava deaktivieren                       | Kein „Steh-vor-Lava“-Exploit                        |
| V15 Analyse B1               | Phase 4 zu harter Skill-Bruch                | Lava in mehrere Subphasen splitten                | Sanftere Skill-Einführung                           |
| V15 Analyse B2               | Curriculum nur episodenbasiert               | Advance via Success-EMA geplant                   | Kein Überspringen ungelöster Phasen                 |
| V15 Analyse B3               | Forgetting                                   | Phase-Mixing vorgeschlagen                        | Alte Skills bleiben erhalten                        |
| V15 Analyse C1               | Sensorik zu kurz                             | Mehr Forward-/Side-Raycasts                       | Bessere Sprungplanung                               |
| V15 Analyse C2/C3            | Euklidische Distanz falsch                   | Pfaddistanz statt Luftlinie                       | PBRS semantisch korrekt                             |
| V15 Analyse D1               | MovePosition + AddForce inkonsistent         | Velocity-basierte Physik geplant                  | Natürlichere Sprünge                                |
| V15 Analyse E                | Hyperparameter-Spannungen                    | LR-/Curiosity-Anpassungen geplant                 | Stabilere Hard-Phasen                               |
| V15 Analyse F                | Transformer-Kontext zu klein                 | Größere/korrektere Memory-Ideen                   | Langfristige Strategie besser lernbar               |
| V15 Analyse H                | Logging unpräzise                            | Separate LavaJump-Metriken                        | Sauberere Diagnostik                                |
| V15 Priorität 1              | Lava-Skill ungelöst                          | Landing-Reward + PBRS-Pause + billiger Tod        | Hauptansatz für Phase-4-Lösung                      |
| V15 Priorität 2              | Forgetting                                   | Phase-Mixing + Success-Gating                     | Stabilere Langzeit-Policies                         |
| V15 Priorität 3              | Beobachtungen zu schwach                     | Mehr Sensoren + PathDistance                      | Agent versteht Hazards besser                       |
| V15 Priorität 4              | Reward-Drift                                 | Reward-Komponenten separat loggen                 | Bessere Ursachenanalyse                             |
| V15 Priorität 5              | Diagnose-Lücken                              | TerminalReason + PhaseStats                       | Präzisere Trainingsanalyse                          |
| V15 Priorität 6              | Physik-Probleme                              | Velocity-Movement + stärkere Sprünge              | Robustere Traversierung                             |
| V15 Priorität 7              | Build-Risiko                                 | Verifikationsskript vor Run                       | Keine Hybrid-Konfigurationen mehr                   |




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
| **Hardware**         | Ryzen 5 5625U + RTX 30                                                                            |

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

## V15

### Verbesserung von v14 -> v15:
### V14 — Komplette Ursachen-Analyse

Strukturiert in **Ursachen-Kategorien** (A–J), absteigend nach geschätzter Erklärungskraft für die Beobachtungen. Anschließend eine **priorisierte Fix-Liste**.

---

### A. Reward-Architektur: Strukturell fehlendes Lernsignal für Sprünge

#### A1. **Reward-Vakuum beim Lava-Sprung** ⭐ **wahrscheinlich Haupt­ursache**

V13/V14 hat `lavaAttemptBaseReward = 0` gesetzt, weil V12s `+0.5` als „farmbar / falsches Konzept-Signal" identifiziert wurde. Im V14 gilt nun:

| Ereignis                           | Sofort-Reward                         |
| ---------------------------------- | ------------------------------------- |
| Sprung in Luft über Lava           | **0**                                 |
| Lava berühren (Tod)                | **−1**                                |
| Sprung schaffen + auf Floor landen | **0**                                 |
| Goal nach Sprung erreichen         | +30 (mit γ-Discount stark abgewertet) |

Damit ist die **gesamte Sprung-Trajektorie aus Sicht des Agenten dominiert von −1**. Selbst wenn 1 % der Sprünge erfolgreich wären und +30 brächten, ist EV bei γ=0.997 und ~80 Steps zwischen Sprung und Goal: `0.01 × 30 × 0.997^80 − 0.99 × 1 = 0.01 × 23.4 − 0.99 = −0.76` → **negativer Erwartungswert pro Sprungversuch**. Der Agent lernt rational: nicht springen.

#### A2. **PBRS belohnt Lava-Umgehung positiv**

`distanceShapingScale = 0.005` × `(prevDist − currDist)` (`pbrsGamma=1.0`).
Euklidische Distanz schrumpft auch, wenn der Agent **um Lava herumläuft** — sobald irgendein Pfad das Ziel räumlich näherbringt, kassiert er positives Shaping. Phase 7 (Hard) belegt das empirisch: 99,4 % der Goal-Reaches **ohne Sprung**. Der Agent hat eine optimale Strategie unter dem gegebenen Reward gefunden — Lava ist aus Reward-Sicht nie nötig.

#### A3. **Sterben ist nicht teuer genug relativ zum erwarteten Goal-Wert**

```text
lavaDeathPenalty = −1
timeoutPenalty   = −5
goalReward       = +30  (~ +6 nach γ-Discount aus Step 0 einer 1500-Step-Episode bei γ=0.997)
```

Tod kostet nur 1/30 des Goals — das **klingt** wie ein guter Risiko-Anreiz. Aber:

* Bei 1 % Sprungerfolgsrate: EV(springen) = 0.01·6 − 0.99·1 = **−0.93**
* EV(nicht springen, Goal über Umweg in 50 % der Fälle erreichen) = 0.5·5 − 0.5·5 = **+0** (PBRS bleibt positiv über Umweg)

Mit so niedriger initialer Erfolgsrate ist die Death-Penalty **zu hoch relativ zur Sprung-Lernkurve**. Die Penalty müsste entweder kleiner sein, oder Erfolgssignale müssten zwischendrin existieren.

#### A4. **Curiosity-Modul-Interferenz**

`curiosity.strength=0.05` mit eigener γ=0.99. Curiosity gibt **intrinsischen Reward für seltene States** — Lava-Zonen wurden in Phase 4 schnell „erkundet" durch Tod-Anflug, also bekommt der Agent dort kaum noch Novelty-Bonus. Stattdessen erhält er Curiosity-Reward für Erkundung weit weg von Lava → **verstärkt Avoidance**.

#### A5. **Wall-Climb-Penalty als versteckter Sprung-Bestrafer**

`wallClimbPenalty = −1` bei `transform.position.y > spawnY + 5.0f`. Bei Lava-Sprüngen kann der Agent kurzzeitig hoch katapultiert werden (PhysX-Depenetration an Lava-Cube-Kollidern). Mit `maxUpwardVelocity = 3.5` und `jumpForce = 4.5` sollte er <5m bleiben — aber **das ist nicht garantiert**, weil Lava-Cubes als Trigger fungieren und PhysX kann unter Edge-Cases trotzdem Impulse erzeugen. Verifizieren!

---

### B. Curriculum-Design

#### B1. **Phase 4 ist eine Mauer, kein Zwischenschritt** ⭐ wahrscheinlich Haupt­ursache

| Phase           | Mechanik                                    | Lerneffekt erwartet     |
| --------------- | ------------------------------------------- | ----------------------- |
| 3 TrivialHole   | Hole-Avoidance (passiv: nicht reinfallen)   | Avoidance ✓             |
| 4 TrivialHazard | **+ Lava-Sprung (aktiv: drüber springen!)** | komplett neue Skill     |
| 5 Easy          | Komplexe Maps, gelegentlich Lava            | Skill-Transfer erwartet |

Phase 4 verlangt eine **neue Skill-Klasse** (zeitkritische Aktion mit Risiko), nicht eine Erweiterung. Das Curriculum behandelt sie als „Hole + 1 Lava-Tile", aber konzeptionell ist es ein Bruch.

#### B2. **CurriculumTracker advanced auf Episodenzahl, nicht auf Erfolg**

```csharp
bool advance = phase.thresholdType == ThresholdType.Episodes
    ? episodeCountInPhase >= phase.threshold : ...;
```

Phase 4 wechselt nach 5000 Episoden in Phase 5 — auch bei 0.2 % Success. Der Agent betritt Phase 5/6/7 mit der **gelernten Anti-Lava-Policy**. Die Skill-Lücke wird über alle nachfolgenden Phasen weitergeschleppt.

#### B3. **Kein Phase-Mixing → Vergessen unvermeidbar**

Die 3 Crash-Recovery-Zyklen in Phase 7 sind kein Zufall: PPO trainiert reinen Hard-Content, vergisst Hindernis-Avoidance aus Phase 3, lernt neu, vergisst Navigation aus Phase 0/1, lernt neu. Klassisches Catastrophic Forgetting ohne Replay-Mechanismus.

#### B4. **Phase 4 Lava-Tile-Geometrie ist hart**

In `BuildTrivialBase` ist die Lava 1×1 (corrWidth=1) oder **2×1** (corrWidth=2) quer im Hauptkorridor. Beim 2-breiten Lava-Streifen + `jumpForce=4.5` und `maxUpwardVelocity=3.5` (`gravity=−9.81`):

Sprungzeit zu Peak: ~0.36s → Höhe ~0.63m. Reichweite bei `moveSpeed=3`: ~2.16m horizontal vor Boden­kontakt. Lava ist 2 Tiles × cellSize=1 = **2m breit + Agent-Kapsel-Durchmesser** (0.5m). Effektive zu überspringende Distanz: ~2.5m, verfügbare Reichweite ~2.16m. **Physikalisch grenzwertig.** Der Agent kann theoretisch springen, aber nur unter perfekten Bedingungen (Anlauf, Vollgeschwindigkeit, exakter Timing).

#### B5. **TrivialHazard hat keine Pfadvarianz**

Lava liegt immer im Hauptkorridor zwischen Spawn- und Goal-Raum. Es gibt keinen Umweg → Agent muss springen ODER timeouten. Das **wäre** gut, aber wenn die Sprung-Erfolgsquote ~0 ist, bedeutet das nur: jede Episode endet in Tod oder Timeout. Kein Lernsignal.

#### B6. **Easy/Medium/Hard haben strukturell anderen Lava-Kontext**

Easy/Medium/Hard nutzt `RoomCorridorGraph` + `ObstacleClusterPlacer` + `PlatformPlacer`. **Lava in diesen Phasen ist mit Platforms kombiniert** (siehe `PlatformPlacer.PlacePlatforms`). Lava in Hard ist nicht „springen", sondern „auf Plattform". Die Phase-4-Skill „Sprung mit Anlauf" transferiert nicht.

#### B7. **Trivial-Phasen sind trotz Refactoring eingeschränkt**

`seed % 200` in TrivialBranch/Hole/Hazard. Pro 1000 Eps × 4 Variations (durch interne RNG-Splits) × 96 Agents = Agent sieht jede Variante 100+ Mal. Statt zu generalisieren, kann er overfitten auf spezielle Spawn-Position-Sequenzen.

---

### C. Beobachtungen (Sensorik): Sprung-Planung blind

#### C1. **Boden-Sensor nur in 3 Punkten, alle entlang `forward`**

```csharp
Vector3[] checkOffsets = { Vector3.zero, forward*1, forward*2 };
```

Der Agent sieht:

* Was direkt unter ihm ist
* Was 1 Zelle vor ihm ist
* Was 2 Zellen vor ihm ist

Aber **nicht** ob Lava breit oder schmal ist, ob es einen Umweg gibt, was 3 Zellen vor ihm liegt (Landefläche). **Sprung-Planung erfordert mind. 4–5 Zellen Vorausschau** plus seitliche Sensoren (Lava neben dem Pfad).

#### C2. **`directionToGoal` ist normalisiert → versteckt Distanz**

Der Vektor zeigt durch Lava hindurch zum Goal. PBRS + Richtungs-Observation sagen beide: „direkt durch Lava". Der Agent stirbt → seine internen Repräsentationen bekommen widersprüchliche Signale.

#### C3. **`distToGoal` ist euklidisch, nicht Pfad­distanz**

Wenn der Agent eine Lava umgeht, wird die euklidische Distanz oft kleiner als die Pfaddistanz wäre. PBRS rewardt Annäherung an unerreichbare Ziele.

#### C4. **Velocity-Observation kann unnormalisiert sein**

```csharp
Vector3 normalizedVelocity = transform.InverseTransformDirection(rb.velocity) / moveSpeed;
```

`moveSpeed=3`, aber `maxUpwardVelocity=3.5` → Y-Komponente kann >1 sein. Plus horizontale Velocity bei `MovePosition`-induced kann andere Werte annehmen. **Observation-Normalisierungs-Bruch** während des Sprungs.

#### C5. **Kein „Air time"-Indikator**

Der Agent kann nicht direkt beobachten, wie lange er schon in der Luft ist. Sprung-Trajektorien werden für PPO im Memory rekonstruiert, aber 16 Steps Sequenz @ 50ms = 0.8s deckt einen Sprung gerade so ab — keine Reserve.

---

### D. Aktionen / Physik

#### D1. **`MovePosition` + `AddForce` mischen Kinematic-ähnliche und dynamische Bewegung**

```csharp
rb.MovePosition(transform.position + direction * moveSpeed * dt);  // Position-Setting
rb.AddForce(Vector3.up * jumpForce, Impulse);                        // Echte Physik
```

Während ein Sprung im Gange ist, **überschreibt MovePosition jeden Frame die horizontale Position direkt** und ignoriert die durch AddForce gegebene Velocity. Das macht Lava-Sprünge **deterministisch in der Reichweite** (immer `moveSpeed * airTime`) statt parabolisch — was ggf. der Sprung-Reichweite hilft, aber unnatürlich/inkonsistent ist und PPO erschwert (state-action-mapping unstetig).

#### D2. **Sprung-Action ist nur Boolean**

```csharp
if (jumpAction == 1 && isGrounded) AddForce(Vector3.up * jumpForce, Impulse);
```

Keine variable Sprunghöhe / -richtung. Ein „starker Sprung" ist nicht möglich. Für 2-Tile-Lava muss der Agent perfekt zentriert in Bewegung sein. Kein margin of error.

#### D3. **`isGrounded` wird zwischen Aktionen falsch zurückgesetzt**

```csharp
if (jumpAction == 1 && isGrounded) { ... isGrounded = false; }
```

Direkt nach Sprung-Auslösung wird `isGrounded` auf `false` gesetzt. Der nächste FixedUpdate-Tick führt aber `GroundCheck()` aus, der auf Kollision mit Floor prüft. Wenn der Sprung kaum vom Boden abhebt (kleine Velocity), kann `isGrounded` in der nächsten Frame wieder true sein → Doppelsprung-Versuche fehlschlagen / inkonsistent.

#### D4. **`turnSpeed = 180°/s` × `fixedDeltaTime = 50ms` = 9°/Step**

In 16 Steps (Memory-Sequenz) = 144° Drehung möglich. Während eines Sprungs (~12 Steps Air time) kann der Agent **die Hälfte einer Umdrehung** machen. Sprung-Landung-Orientierung ist hochvariabel — schwer für PPO zu lernen.

---

### E. Hyperparameter / Training-Konfig

#### E1. **γ=0.997 hilft, aber Episode-Länge in Hard überfordert es**

```text
30 × 0.997^2000 ≈ 30 × 0.00248 ≈ 0.074
```

Auch mit verbessertem γ ist Goal-Reward aus Step 0 in einer 2000-Step-Hard-Episode praktisch unsichtbar. Der **Critic lernt's** (durch Bootstrapping), aber das Lernen ist langsam.

#### E2. **Linearer LR-Schedule auf 60M Steps**

Bei 31M Steps ist `lr ≈ 1e-4 × (1 − 31/60) = 4.83e-5`. Das ist OK für Konvergenz, aber **für Catastrophic-Forgetting-Recovery in Hard zu hoch**. Wenn der Agent in Hard zwischen guten und schlechten Policies oszilliert, würde eine **stärker abfallende LR oder Plateau-Detection** Stabilisierung erlauben.

#### E3. **β=1e-3 → Entropy fällt auf 1.05**

3 Discrete Branches mit (3,3,2) — maximale Entropy ist `ln(3)+ln(3)+ln(2) = 2.49`. Endwert 1.05 = 42 % davon. **Nicht kollabiert**, aber niedrig genug, dass Re-Exploration nach Forgetting schwer wird.

#### E4. **Buffer 81920 / Time Horizon 256 = 320 trajectories**

Bei 16 Areas × 6 Builds × kurzen Episoden in Trivial sind 320 Trajektorien stark gemischt. In Hard mit 700-Step-Episoden = ~470 Steps Mittelung. Buffer ist OK, könnte aber bei großen Maps zu klein für stabile Advantage-Schätzung sein.

#### E5. **Curiosity hat `gamma=0.99` ≠ extrinsic `0.997`**

Inkonsistente Discounts in zwei Reward-Streams machen Value-Estimation komplizierter. Curiosity wird über kürzeren Horizont gewichtet → bevorzugt **lokale Exploration** (Lava-nahe Bereiche **nicht** mehr, weil bereits erkundet) statt **globaler Exploration** (Goal hinter Lava).

#### E6. **3 Epochs × 1024 Batch × ~80 Mini-Batches/Update**

PPO über 3 Epochs ist Standard, aber **mit Curiosity-Reward-Drift** kann 3 Epochs reichen, um Policy zu weit zu bewegen → Trust-Region-Verletzung → Performance-Crash. Erklärt die Reset-Zyklen in Phase 7.

---

### F. Transformer-Memory-Spezifika

#### F1. **`memory_size=128 → output_size=64`**

ML-Agents teilt memory_size durch 2 für LSTM-Kompatibilität. Effektiver Output-Vektor ist 64-dim. Das ist klein für 8 Phasen × komplexe Map-Variationen.

#### F2. **`sequence_length=16` × 50ms = 0.8s Kontextfenster**

Reicht für einen Sprung (kurz), reicht **nicht** für eine ganze TrivialHazard-Episode (~245 Steps = 12s). Der Transformer kann keine längerfristigen Pattern­erkennungs-Strategien lernen.

#### F3. **Rolling-Buffer-Fix aus v8 ist möglicherweise nicht 100 % korrekt**

Die Doku erwähnt einen Patch in `transformer_policy.py` / `networks.py` / `patch_mlagents.py`. Wenn der Rolling-Buffer die letzten 7 Encodings statt der letzten 15 speichert oder die Reihenfolge invertiert ist, hat der Transformer subtle Inkonsistenz zwischen Inference und Training. **Konkret prüfen.**

#### F4. **Causal Mask + Padding für frühe Steps**

In den ersten 15 Steps jeder Episode hat der Transformer nur partielle Sequenz. Padding-Strategie nicht in der Doku spezifiziert — falls Zero-Padding und Mask fehlt, wird das Lernen verlangsamt.

---

### G. Inferenz vs. Training

#### G1. **Live-Test: 0/3 Maps geschafft, immer Lava-Tod**

Live-Test ohne Curriculum bedeutet typischerweise **Standalone-Map**. Mögliche Probleme:

* Memory state startet leer (Transformer braucht ~16 Steps Warmup)
* Stochastisch vs. deterministisch — ML-Agents Inferenz nutzt mit `BehaviorParameters.BehaviorType.InferenceOnly` typischerweise deterministische Aktionen (argmax statt sample). Wenn der Agent in Training Erfolg durch Stochastik hatte, scheitert er deterministisch.
* TimeScale auf 1 statt 20 → andere FixedUpdate-Frequenz möglich

#### G2. **Test auf Hard-Maps → Lava-Skill nie gelernt**

Konsistent mit den 99 % Tod-Raten in Phase 7. Die Inferenz bestätigt: der Agent hat keine Lava-Sprung-Policy. Punkt.

---

### H. Logging & Metrik-Verfälschung

#### H1. **`LavaJumps`-Counter zählt Eintritte, nicht Erfolge**

```csharp
if (currentlyAboveLava && !wasAboveLava) lavaJumpAttempts++;
```

`wasAboveLava` wird auf Edge-Trigger gesetzt — beim Eintritt in „in der Luft + Raycast nach unten trifft Lava". Beim Tod (`OnTriggerEnter("Lava")`) wird der Counter nicht aktualisiert. Statistik:

* 11.415 Sprünge in Phase 4, 11.410 führten zum Tod = 99.96 %.
* Aber: Was passiert, wenn der Agent über Lava springt, runter kommt, aber **knapp daneben** im Lava-Trigger landet? Das ist 1 Edge-Trigger + 1 Tod = beides gezählt.

Der Counter überschätzt die „Versuche", weil **alle Lava-Annäherungen** mitgezählt werden, auch fehlgeschlagene.

#### H2. **Custom-Stats sind Episode-Ende-Snapshots, kein Histogram**

`Academy.Instance.StatsRecorder.Add` wird in `OnEpisodeBegin` (sic!) aufgerufen — schreibt also die Stats der **vergangenen** Episode beim Start der nächsten. Bei Build-Crash kann die letzte Episode-Stat verloren gehen. Mehr Datenverlust als nötig.

#### H3. **Kein Reward-Komponenten-Logging**

Wie viel von `lastEpisodeCumulativeReward` kommt von:

* Goal? Death? Timeout? StepPenalty? PBRS? Curiosity? LavaAttempt? Wall-Climb?

Nicht aufgeschlüsselt → schwer zu diagnostizieren, ob PBRS-Avoidance oder Goal-Search dominiert.

---

### I. Build / Prefab-Konsistenz (Wiederholung von v13!)

#### I1. **War der V14-Build wirklich V14?**

V13's Post-Mortem zeigt: `Agent.prefab` Inspector-Werte überschreiben Source-Defaults. Ohne **echte Verifikation** kann V14 wieder eine Hybrid-Konfig sein:

* `goalReward = 30` im Inspector? Verifiziert
* `phaseMaxSteps = [600,...]` korrekt? Verifiziert
* `MaxStep = 0` (sonst override greift nicht)?
* `testOverrideMaxSteps = 0`?
* `distanceShapingScale = 0.005`?
* Build-Datum nach letzter Prefab-Änderung?

Die V14-Trainingsdaten zeigen Phase-EpLen `~245` in Phase 4 — mit `phaseMaxSteps[4]=600` plausibel. Phase 7 EpLen `~711` mit `phaseMaxSteps[7]=2000` plausibel. **Sieht korrekt aus**, aber explizit verifizieren.

#### I2. **96 parallele Agents, 6 Builds — Phase-Drift**

Jeder Build hat einen eigenen statischen `CurriculumTracker`. Wenn Build 1 schneller läuft als Build 5, ist Build 1 in Phase 6, während Build 5 noch in Phase 3 ist. PPO lernt aus dem **gemischten Replay-Buffer** = simultane Trajektorien aus Phase 3 + 6.

**Das könnte ein verstecktes Plus sein**: implizites Phase-Mixing! Aber: unkontrolliert. Die Verteilung von Phase-Anteilen ist ein Zufallsprodukt der CPU-Scheduling. Erklärung für Reward-Volatilität in Phase 7?

#### I3. **Custom/CurriculumPhase wird nur eine Phase loggen**

`Academy.Instance.StatsRecorder.Add("Custom/CurriculumPhase", phase)` mittelt über alle Agents im Stat-Window. Wenn Build 1 in Phase 6 und Build 5 in Phase 3 → gemittelter Wert ist 4.5. Phase-Logging ist also irreführend.

---

### J. Sekundäres / Hypothesen niedrigerer Priorität

#### J1. **`maxObservationDistance = 20` aber Hard-Maps können größer sein**

Bei Distanzen >20m wird die Obs auf 1 geclamped → Sättigung. Agent sieht „weit weg = immer weit weg" ohne Gradient.

#### J2. **`pbrsGamma = 1.0` macht PBRS technisch nicht potentialbasiert**

Theoretisch braucht PBRS γ_shaping = γ_env, damit der Beweis (Ng et al. 1999) gilt: optimale Policy unverändert. Mit `pbrsGamma = 1.0` und env-γ=0.997 ist die Theorie verletzt — die optimale Policy *kann* sich verändern, typischerweise zugunsten von „bleibe nahe am Ziel ohne es zu erreichen". Schwacher Effekt, aber nicht null.

#### J3. **`timeoutPenalty = -5` wird zusätzlich zum step-Penalty bezahlt**

```csharp
AddReward(stepPenalty); ... if (StepCount >= MaxStep-1) AddReward(timeoutPenalty);
```

Phase 4 (`MaxStep=600`): Timeout-Reward ≈ −5 + 600·(−0.005) = −8. Phase 7 (`MaxStep=2000`): ≈ −5 + 2000·(−0.005) − 10·PBRS-Bonus = −13 bis −15. Death ist −1 (plus step-Penalty bis dahin). **Tod ist 5–10× billiger als Timeout in späten Phasen** → Agent hat einen Anreiz, **schneller zu sterben**.

#### J4. **`CurriculumTracker.episodeCountInPhase` und `stepCountInPhase` sind static und nicht thread-safe**

In Unity sind alle Agents im Main Thread, aber innerhalb eines Builds ruft jeder der 16 Agents `GetNextLayout()` und `NotifyStep()` auf. Race conditions sind unwahrscheinlich (alle in MainThread serialisiert), aber **bei 16 parallelen Episoden-Endes im selben Frame kann der Counter um 16 springen** statt 1, und der Phase-Wechsel passiert beim ersten Agent, die anderen 15 starten noch mit alter Phase aber neuem MaxStep. → Subtle Off-by-Ones.

#### J5. **Reset der `wasAboveLava`-Flag passiert nur in `OnEpisodeBegin`**

Bei Tod über Lava (OnTriggerEnter → EndEpisode → OnEpisodeBegin) wird die Flag korrekt resettet. Aber: zwischen Sprung-Ende und nächstem Edge-Trigger gibt es keine Wartezeit → bei Doppel-Sprungversuchen in einer Episode kann der Counter zu schnell hochgehen.

#### J6. **Die ProceduralLayoutGenerator-Trivial-Familie hat keine zusätzliche Variation für Lava-Streifen-Breite**

```csharp
int midX = cx0 + seg1Len / 2 - 1;
r.lavaCell1 = (midX, corrY);
r.lavaCell2 = corrWidth >= 2 ? (midX, corrY + 1) : r.lavaCell1;
```

→ **Lava ist immer 1 Tile breit in Sprung-Richtung** (nur entlang `corrWidth` ist sie 1–2 Tiles breit, das ist senkrecht zum Anlauf). Das **vereinfacht** den Sprung. Sollte für den Agenten machbar sein… aber er macht's nicht. Stark deutend auf Lernsignal-Mangel.

---

### Priorisierte Fix-Liste

Geordnet nach **(Erwarteter Impact) × (1 / Umsetzungsaufwand)**.

---

### 🔴 Stufe 1: Diese 4 Fixes sind die Hypothese, dass Phase 4 lösbar wird

#### Fix 1.1 — **Konditionaler Lava-Sprung-Reward bei erfolgreicher Landung**

Ersetze den vorhandenen `lavaAttemptBaseReward`-Mechanismus durch einen **Edge-Trigger auf Landung**:

```text
WHEN wasAboveLava == true AND isGrounded == true 
  AND ground-tag == "Floor"
THEN AddReward(+5)
     lavaCrossingsCompleted++
```

Das ist nicht farmbar (Agent muss *übers Lava drüber* sein), gibt klares Lernsignal, und ist nur einmal pro Lava-Stelle pro Episode vergeben (Edge-Trigger).

#### Fix 1.2 — **PBRS pausiert über Lava-Zone**

Wenn der Agent über Lava ist (`DetectAboveLava() == true`) oder Lava direkt vor ihm ist (Bodensensor 1 Zelle voraus = Lava-Tag) → setze `distanceShapingScale = 0` für diesen Step. Verhindert, dass PBRS dem Agenten sagt „du bist nahe genug, bleib stehen" während Lava blockiert.

#### Fix 1.3 — **Phase 4 verlängern + abgestuft einführen**

Aufteilen in 3 Sub-Phasen vor Easy:

* **4a TrivialLavaSurround**: Lava als visuelle Bedrohung in Sackgassen (am Branch-Ende statt Hole). Agent muss Lava sehen, kann aber drumrum.
* **4b TrivialLavaCrossable**: 1-Tile-Lava im Hauptkorridor, breiter Anlauf. `threshold = 15000` Episoden statt 5000.
* **4c TrivialLavaWide**: 2-Tile-Lava, knapper Anlauf.

Alternativ: Phase 4 auf 15000 erhöhen, aber nur mit Fix 1.1+1.2 sinnvoll.

#### Fix 1.4 — **Death-Penalty auf −0.3 reduzieren, Tod muss billig sein während Skill-Lernen**

`lavaDeathPenalty: -1 → -0.3` (oder sogar −0.1) temporär für Phase 4, dann zurück auf −1 in Hard. Das senkt die Hürde für explorative Sprünge. Sterben wird zu „kostenloser Reset", Versuche kostengünstig.

---

### 🟠 Stufe 2: Anti-Catastrophic-Forgetting

#### Fix 2.1 — **Phase-Mixing in CurriculumTracker**

```csharp
public static MapData GetNextLayout()
{
    // 70% aktuelle Phase, 20% direkter Vorgänger, 10% zufällig aus allen früheren
    int draw = rng.Next(100);
    int targetPhase = draw < 70 ? currentPhaseIndex
                   : draw < 90 ? Mathf.Max(0, currentPhaseIndex - 1)
                   : rng.Next(currentPhaseIndex + 1);
    return config.phases[targetPhase].layouts[...];
}
```

Verhindert Vergessen aus Phase 3 in Phase 7. Erwartung: Drei-Zyklen-Crash in Hard verschwindet.

#### Fix 2.2 — **CurriculumTracker advanced auf SuccessRate-EMA, nicht Episodenzahl**

```csharp
if (recentSuccessRate > 0.7 && episodeCountInPhase > 1000) advance();
```

Verhindert Skip von Phase 4 mit 0 % Success. Kombiniert mit Fix 1.1, sonst hängt der Agent ewig in Phase 4.

#### Fix 2.3 — **Learning Rate plateaut früher**

```yaml
learning_rate_schedule: constant
# ODER: cosine mit min_lr=1e-5 ab 30M Steps
```

Niedriges LR in späten Phasen reduziert Policy-Updates → weniger Forgetting.

---

### 🟡 Stufe 3: Observation / Sensor

#### Fix 3.1 — **Bodensensor um 4 Strahlen erweitern**

```csharp
checkOffsets = {
  zero, forward*1, forward*2, forward*3,
  forward*1 + right*0.5, forward*1 - right*0.5
};
```

→ Agent sieht Lava-Breite und Landefläche.

#### Fix 3.2 — **Pfad-Distanz statt euklidische Distanz**

`distToGoal` aus A*-Berechnung auf Grid (oder einfacher: Manhattan-Distance mit Lava als Wand). Einmalige Berechnung in `GenerateMap` cachen.

#### Fix 3.3 — **`Custom/PathDistanceToGoal` als Observation und für PBRS**

PBRS auf Pfad-Distanz löst gleichzeitig 2 Probleme: Lava-Umgehung wird nicht mehr fälschlicherweise belohnt, und der Agent hat ein „intelligentes" Annäherungssignal.

---

### 🟡 Stufe 4: Reward-Refinement

#### Fix 4.1 — **Curiosity strength reduzieren oder phasen-spezifisch ausschalten**

`curiosity.strength: 0.05 → 0.02` (oder `0` ab Phase 5). Curiosity hat in Phase 4 nicht geholfen (laut Doku V13), in Hard verstärkt sie Forgetting.

#### Fix 4.2 — **Reward-Komponenten einzeln loggen**

```csharp
Academy.Instance.StatsRecorder.Add("Reward/Goal", goalRewardThisEpisode);
Academy.Instance.StatsRecorder.Add("Reward/PBRS", pbrsThisEpisode);
Academy.Instance.StatsRecorder.Add("Reward/Curiosity", ...);
```

Erlaubt Post-Hoc-Analyse, ob PBRS dominiert.

#### Fix 4.3 — **`pbrsGamma = 0.997`**

Wiederherstellung der theoretischen Korrektheit. Wahrscheinlich kleiner Effekt, aber risikoarm.

#### Fix 4.4 — **Step-Penalty leicht reduzieren in langen Phasen**

In Phase 7 mit MaxStep=2000: kumulativ −10 nur durch Step-Penalty. `stepPenalty = -0.002` in Hard macht Goal-Reward dominanter.

---

### 🟢 Stufe 5: Logging / Diagnose

#### Fix 5.1 — **`LavaJumpsAttempted` vs `LavaJumpsSuccessful` getrennt**

```csharp
// im DetectAboveLava-Edge: lavaJumpAttempts++
// in Landings-Check: lavaJumpsSuccessful++
// im OnTriggerEnter("Lava"): lavaJumpsFailed++
```

#### Fix 5.2 — **SuccessRate pro Phase loggen**

Statt `Custom/SuccessRate` (gemittelt) → `Custom/SuccessRate_P0`, `..._P1`, ..., `..._P7`.

#### Fix 5.3 — **TerminalReason als kategoriale Stat**

`Custom/TerminalReason` mit Werten:

* `0 = Goal`
* `1 = Lava`
* `2 = Hole`
* `3 = Timeout`

Mit Histogram pro Phase.

---

### 🟢 Stufe 6: Physik / Aktionen

#### Fix 6.1 — **`MovePosition` durch Velocity ersetzen**

```csharp
rb.velocity = new Vector3(direction.x * moveSpeed,
                          rb.velocity.y,
                          direction.z * moveSpeed);
```

Vollständig physikalische Bewegung. Risiko: Regression in funktionierenden frühen Phasen.

#### Fix 6.2 — **Air-Control reduzieren**

In der Luft `moveSpeed *= 0.5f`.

#### Fix 6.3 — **Sprung-Force-Boost in Phase 4+**

Temporär `jumpForce = 6.0` in Phase 4, später wieder reduzieren.

---

### 🟢 Stufe 7: Build & Verifikation

#### Fix 7.1 — **Pre-Run-Verifikations-Skript**

Prüft:

* Build-Datum > Prefab-Last-Modified
* Inspector-Werte konsistent
* `MaxStep == 0`
* `testOverrideMaxSteps == 0`
* `phaseMaxSteps == [...]`

#### Fix 7.2 — **6 Builds → 1 Build × 16 Areas testen**

Eliminiert Phase-Drift als Variable.

---

### TL;DR der Analyse

**Drei strukturelle Hauptursachen** erklären vermutlich den Großteil der Symptome:

1. **Reward-Vakuum**
   Sprung-Erfolg gibt kein direktes Signal. `lavaAttemptBaseReward=0` war ein Overcorrect aus V12.
   → **Fix 1.1**

2. **PBRS-Interferenz**
   Euklidisches Shaping belohnt Lava-Umgehung.
   → **Fix 1.2 + 3.2**

3. **Curriculum-Cliff**
   Phase 4 ist ein Skill-Bruch ohne Erfolgsgating.
   → **Fix 1.3 + 2.2**

Das Catastrophic Forgetting in Hard wirkt eher wie ein Folgeeffekt dieser strukturellen Probleme als wie die eigentliche Root Cause.


## Noch offen -> UPDATE: GESCHLOSSEN:

manuell im Inspector tun musst

  1. CurriculumConfig.asset: 3 neue Phasen einfügen (TrivialLavaSurround, TrivialLavaCrossable, TrivialLavaWide) zwischen Phase 3
  (TrivialHole) und der aktuellen Phase 4 (TrivialHazard). enablePhaseMixing = true, useSuccessRateAdvance = true falls gewünscht.
  2. Layouts generieren: Über MapGenerator-Inspector Button "▶ Layouts generieren & speichern" für jede neue Difficulty 10–20 Stück.
  3. phaseMaxSteps im LabyrinthAgent an die finale Phasen-Reihenfolge anpassen. Default ist 11 Einträge — 4 Lava-Sub-Phasen ggf. auf
  15000 setzen (Fix 1.3-Variante).
  4. phaseJumpForces[Phase4+] auf z.B. 6.0 für den Lava-Boost (Fix 6.3).
  5. phaseStepPenalties[Hard] auf z.B. -0.002 (Fix 4.4).
  6. lavaDeathPenalty im Inspector ggf. auf -0.1 setzen, zurück auf -1 ab Hard.

  UPDATE:
  Status je Punkt:

  1. CurriculumConfig_Default.asset: umgesetzt
     Reihenfolge ist TrivialHole → TrivialLavaSurround → TrivialLavaCrossable → TrivialLavaWide → TrivialHazard.
     enablePhaseMixing = true, useSuccessRateAdvance = true.
  2. Layouts generiert: umgesetzt
     Vorhanden sind je 100 Layouts:
     TrivialLavaSurround, TrivialLavaCrossable, TrivialLavaWide.
  3. phaseMaxSteps: umgesetzt im Prefab
     11 Einträge, Phasen 4-7 auf 15000.
  4. phaseJumpForces[Phase4+]: umgesetzt im Prefab
     Phasen 4-10 stehen auf 6.
  5. phaseStepPenalties[Hard]: umgesetzt im Prefab
     Phase 10 steht auf -0.002.
  6. lavaDeathPenalty: jetzt sauber per Code umgesetzt
     Neues phaseLavaDeathPenalties-Array in LabyrinthAgent.cs: Phasen 4-7 -0.1, Hard Phase 10 -1. Damit passiert das Zurückstellen ab Hard automatisch.



## getätigte Änderungen:
| Fix     | Datei                                                                         | Änderung                                                                                       | Warum                                                         |
| ------- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 1.1     | `LabyrinthAgent.cs`                                                           | Edge-Trigger: `wasAboveLava` + `isGrounded` + `lastGroundTag=="Floor"` → +5                    | Lernsignal für tatsächliches Überqueren, nicht farmbar        |
| 1.2     | `LabyrinthAgent.cs`                                                           | `pausePbrsOverLava`: scale=0 wenn über Lava oder Lava voraus                                   | Verhindert, dass PBRS "bleib stehen" sagt während Lava blockt |
| 1.3     | `DifficultyLevel.cs`, `ProceduralLayoutGenerator.cs`, `MapGeneratorEditor.cs` | 3 neue Enum-Werte + Generatoren (LavaSurround/Crossable/Wide), `corridorStep` in TrivialResult | Gestaffelter Lava-Einstieg statt direkt 2-Tile-Sprung         |
| 1.4     | `LabyrinthAgent.cs`                                                           | `lavaDeathPenalty`: -1 → -0.3                                                                  | Explorative Sprünge günstiger, Tod als billiger Reset         |
| 2.1     | `CurriculumConfig.cs`, `CurriculumTracker.cs`                                 | `enablePhaseMixing`, 70/20/10-Sampling                                                         | Anti-Catastrophic-Forgetting                                  |
| 2.2     | `CurriculumConfig.cs`, `CurriculumTracker.cs`                                 | `ThresholdType.SuccessRate`, EMA, `minEpisodesBeforeAdvance`                                   | Kein Phase-Skip bei 0% Success                                |
| 2.3     | `labyrinth_transformer.yaml`, `_export.yaml`                                  | `learning_rate_schedule: linear → constant`                                                    | Weniger Policy-Drift in späten Phasen                         |
| 3.1     | `LabyrinthAgent.cs`                                                           | Bodensensor 3 → 6 Strahlen (fwd 1/2/3 + half-left/right)                                       | Agent sieht Lava-Breite + Landefläche                         |
| 3.2+3.3 | `MapGenerator.cs`, `LabyrinthAgent.cs`                                        | BFS-Pfad-Distanz, Lava/Hole=Wand, neue Observation, PBRS auf Pfad-Distanz                      | Umgehung wird nicht fälschlich belohnt                        |
| 4.1     | `labyrinth_transformer.yaml`, `_export.yaml`                                  | `curiosity.strength: 0.05 → 0.02`                                                              | Curiosity hat in Phase 4 nicht geholfen                       |
| 4.2     | `LabyrinthAgent.cs`                                                           | `Reward/{Goal,PBRS,Step,Death,Timeout,LavaJump,LavaCross,WallClimb}` Stats                     | Post-Hoc-Analyse welche Komponente dominiert                  |
| 4.3     | `LabyrinthAgent.cs`                                                           | `pbrsGamma: 1.0 → 0.997`                                                                       | Theoretische PBRS-Korrektheit                                 |
| 4.4     | `LabyrinthAgent.cs`                                                           | `phaseStepPenalties[]`-Array (Phase-Override)                                                  | Goal-Reward dominanter in langen Phasen                       |
| 5.1     | `LabyrinthAgent.cs`                                                           | `LavaJumps/{Attempted,Successful,Failed}` getrennt                                             | Diagnose ob Sprünge gelingen oder scheitern                   |
| 5.2     | `CurriculumTracker.cs`                                                        | `Custom/SuccessRate_P{n}` + `SuccessRateEMA_P{n}` pro Phase                                    | Phasenscharfe Erfolgskurve                                    |
| 5.3     | `LabyrinthAgent.cs`                                                           | `Custom/TerminalReason` (0=Goal/1=Lava/2=Hole/3=Timeout)                                       | Todesursache als kategoriale Stat                             |
| 6.1     | `LabyrinthAgent.cs`                                                           | `useVelocityMovement` Flag (default `false`)                                                   | Physik-Bewegung optional, Regression vermieden                |
| 6.2     | `LabyrinthAgent.cs`                                                           | `airControlFactor` (default 0.5)                                                               | Realistische Luftkontrolle                                    |
| 6.3     | `LabyrinthAgent.cs`                                                           | `phaseJumpForces[]`-Array                                                                      | Höhere Sprungkraft in Lava-Phasen möglich                     |
| 20      | `LabyrinthAgent.cs`                                                           | `phaseMaxSteps` 8 → 11 Einträge                                                                | Passt zu neuen Sub-Phasen                                     |

**Übersprungen:** 7.1 (Pre-Run-Skript), 7.2 (Build×Areas — Inspector).


### Ich habe genug Daten und Code-Stellen verifiziert. Hier ist die volle Analyse.

---

### V15 Post-Mortem: Was lief schief

#### Phasen-Timeline V15 (faktisch)

| Phase | Phase Name              | Erreicht bei Step | Dauer                          | Status             |
| ----- | ----------------------- | ----------------- | ------------------------------ | ------------------ |
| 0     | TrivialBase             | 0                 | 760k                           | ✓ gelöst           |
| 1     | TrivialCorr             | 760k              | 2.18M                          | ✓ gelöst           |
| 2     | TrivialBranch           | 2.94M             | 1.08M                          | ✓ gelöst           |
| 3     | TrivialHole             | 4.02M             | 780k                           | ✓ gelöst           |
| 4     | **LavaSurround** (neu)  | 4.80M             | 1.24M                          | ✓ gelöst (drumrum) |
| 5     | **LavaCrossable** (neu) | 6.04M             | **stagniert seit 2.46M Steps** | 🔴 hängt           |

Vs. V14 wo Phase 4 (TrivialHazard, sofort 2-Tile Lava) nach 5000 Episoden bei 0.2% durchgewunken wurde — V15 hängt **korrekterweise** in Phase 5, weil SuccessRate-Advance (Fix 2.2) den Skip verhindert. Aber: Stagnation ist die gleiche, nur jetzt klar lokalisiert.

#### Reward-Trajektorie (Stützpunkte aus TensorBoard)

| Step | Phase           | Reward   | EpLen    | Entropy  | Goal | Step  | PBRS | LavaAtt | Curiosity |
| ---- | --------------- | -------- | -------- | -------- | ---- | ----- | ---- | ------- | --------- |
| 0.5M | P0              | +19.6    | 76       | 2.68     | 22.5 | -0.4  | 0.00 | 0       | 0.11      |
| 3.0M | P2              | +9.6     | 87       | 1.61     | 14.8 | -0.4  | 0.00 | 0       | 0.07      |
| 5.0M | **P4 LavaSur**  | +11.7    | 74       | **0.88** | 12.1 | -0.4  | 0.00 | 0       | 0.05      |
| 6.0M | **P5 Übergang** | +9.9     | **237**  | 1.84↑    | 11.4 | -1.2  | 0.00 | **0**   | 0.14↑     |
| 7.0M | P5 LavaCross    | +2.2     | 911      | 1.30     | 8.1  | -4.4  | 0.00 | **0**   | 0.57↑     |
| 8.5M | P5 LavaCross    | **-8.0** | **1993** | 0.98     | 6.0  | -10.0 | 0.00 | **0**   | **1.51**  |

#### Drei kausale Hauptbefunde

### 🔴 Befund 1: **PBRS ist über das gesamte Training tot** (Fix 3.2+3.3 hat einen Designfehler)

`Reward/PBRS = 0.0008` in Phase 0, 0.003 in Phase 3, **0.000** in Phase 5. Selbst in den Navigations-Phasen, wo es funktionieren sollte, ist es essentiell null.

Code-Trace (`MapGenerator.cs:425-430`):

```csharp
public float GetNormalizedPathDistance(Vector3 worldPos) {
    int d = GetPathDistanceCells(worldPos);
    if (d < 0 || maxPathDistance <= 0) return 1f;   // ← Fallback: Maximum
    return Mathf.Clamp01((float)d / (float)maxPathDistance);
}
```

Und (`MapGenerator.cs:478-479`):

```csharp
if (!IsPathable(currentMapData.GetCell(nx, ny))) continue;
```

Lava/Hole zählen als Wand.

**Konsequenz in LavaCrossable:** Wenn die einzige Verbindung Spawn↔Goal durch Lava geht, ist die BFS-Distanz vom Spawn aus **−1 (unerreichbar)** → normalisiert immer `1f` → `shapingDelta = (1 − 0.997·1) · scale = 0.003·scale` konstant unabhängig von der Position → **kein Gradient, kein Annäherungssignal**.

In V14 lieferte die euklidische Distanz wenigstens ein Signal „lauf in Richtung Goal“. In V15 ist dieses Signal weg, **und der Agent kann sich nur noch an Curiosity orientieren** — und genau das beobachten wir (Curiosity Reward 0.05 → 1.51).

Vergleich:

* **V14**: PBRS belohnte Lava-Umgehung (zu viel Signal, falsche Richtung)
* **V15**: PBRS gibt NICHTS (zu wenig Signal, keine Richtung)

Beides ist falsch — V14 hatte zumindest einen funktionierenden Lernkanal.

### 🔴 Befund 2: **Sprung-Action ist vor Phase 5 strukturell tot** (Entropy-Collapse vor Lava)

`LavaJumps/Attempted = 0` über alle 8.5M Steps. Der Agent versucht in Phase 5 (LavaCrossable mit 1-Tile Lava + breitem Anlauf, physikalisch leicht lösbar) keinen einzigen Sprung.

Ursache-Kette:

1. In Phasen 0–3 (4.8M Steps = 56% der Trainingszeit) wird die Sprung-Action nie benötigt → Entropy fällt auf **0.88** bei Step 5M
2. Phase 4 LavaSurround belohnt **Drumrum-Laufen** ohne Sprung → reinforciert „nicht springen“ weitere 1.24M Steps
3. In Phase 5 angekommen: Sprung-Action-Wahrscheinlichkeit ist nahe 0
4. Fix 1.4 (Death-Penalty -0.3) und Fix 1.1 (Cross-Reward +5) **können nicht greifen**, weil der Agent die Action nicht sampelt
5. Fix 6.3 (`phaseJumpForces=6`) ist irrelevant — kein Sprung-Aufruf, keine Wirkung
6. Phase-Mixing (Fix 2.1) zieht 30% aus Phasen 0–4, in denen Springen **bestraft** würde → verstärkt das Problem statt es zu mildern

Das ist **kein Catastrophic Forgetting** im klassischen Sinne (der Agent vergisst nichts) — die Sprung-Action wurde **nie gelernt**, weil sie in 56% der Trainingsmasse strafbar war.

**Entropy-Trend zeigt PPO-Reaktion:** Bei Step 5.0M → 6.0M springt Entropy von 0.88 → 1.84. PPO merkt die Krise und exploriert wieder. Aber die zusätzliche Entropy verteilt sich auf **Bewegungsaktionen**, nicht auf den Sprung-Branch — die Sprung-Branch-Logit ist offenbar so weit ins Negative gedriftet, dass selbst hohes β sie nicht zurückholt.

### 🔴 Befund 3: **`phaseMaxSteps[5] = 15000` ist viel zu hoch und verstärkt die Step-Penalty-Schleife**

In V14 war Phase 4 MaxStep = 600. In V15 ist Phase 5 = **15000**.

Folge:

* Episode Length steigt von 74 → 237 → 911 → **1993**
* `Reward/Step = -10` bei Step 8.5M (= 2000 × -0.005) ist die **dominante** Reward-Komponente
* Goal-Reward 6.0 (selten getroffen via P0-Mixing) wird komplett überstrahlt
* Mean Reward -8.0 = -10 (Step) + 6 (Goal × Mixing-Rate) − 4 (Timeout) ungefähr

**Der Agent hat keinen Ausweg:** weder PBRS-Gradient noch Sprung-Action verfügbar, dafür 15k Steps pro Episode für Step-Penalty.

---

### Sekundäre Beiträge

| #   | Fix                                 | Bewertung      | Begründung                                              |
| --- | ----------------------------------- | -------------- | ------------------------------------------------------- |
| 1.2 | `pausePbrsOverLava`                 | neutral        | Wirkt nicht weil PBRS sowieso 0                         |
| 2.1 | Phase-Mixing 70/20/10               | 🟡 schädlich   | Mischt Phasen ohne Lava → reinforciert „kein Sprung“    |
| 2.2 | SuccessRate-Advance                 | ✓ funktioniert | Hat Phase-5-Skip verhindert — Problem jetzt lokalisiert |
| 2.3 | Constant LR                         | 🟡 fragwürdig  | Konstanter Update-Druck bei 1e-4 trotz Entropy-Collapse |
| 4.1 | Curiosity 0.05→0.02                 | neutral        | Wird trotzdem dominant weil andere Rewards weg          |
| 4.4 | phaseStepPenalties (nur P10=-0.002) | wirkungslos    | Hilft nicht in P5 wo die Krise ist                      |
| 6.3 | phaseJumpForces=6                   | wirkungslos    | Sprung-Action wird nie gesampelt                        |

---

### Vergleich V14 → V15 (Was wurde wirklich besser/schlechter?)

| Metrik              | V14 @ 8.5M            | V15 @ 8.5M          | Bewertung                   |
| ------------------- | --------------------- | ------------------- | --------------------------- |
| Phase               | ~4 (Hazard)           | 5 (LavaCross)       | V15 weiter durch Sub-Phasen |
| EpLen               | ~245 (P4)             | 1993                | V15 25× länger pro Episode  |
| Mean Reward         | ~-1.5                 | -8.0                | V15 deutlich schlechter     |
| LavaJumps versucht? | 11k+ (99% Tod)        | **0**               | V14 hat wenigstens versucht |
| PBRS funktional?    | ja (falsch gerichtet) | nein (tot)          | V15 strukturell schlechter  |
| Curriculum-Skip?    | ja, P4 mit 0.2%       | nein, P5 hängt fest | V15 ehrlicher               |
| Diagnose-Stats?     | minimal               | sehr gut            | V15 Fortschritt             |

**Die harte Zusammenfassung:** V15 hat den Curriculum-Cliff sauber isoliert, aber die Lernsignale sind schwächer geworden. V14 hatte falsche Exploration. V15 hat gar keine.

---

### Empfehlungen für V16

In aufsteigender Eingriffsstärke:

#### 1. **PBRS-Fallback** (**must-have**)

Wenn `pathDistanceField[pos] = -1`, fallback auf euklidische Distanz:

```csharp
if (d < 0)
    return Mathf.Clamp01(EuclideanDistanceNormalized(worldPos));
```

Damit bekommt LavaCrossable wieder einen Richtungsgradienten.

#### 2. **Sprung-Action explizit trainieren**

Vor Phase 5 braucht Springen eigenes Lernen:

* kleiner Reward (`+0.001`) pro Sprung
* Action-Entropy-Bonus nur für Jump-Branch
* oder Pre-Phase mit Mini-Hindernissen

#### 3. **`phaseMaxSteps[5..7]` von 15000 → 2000–3000**

Mehr Episoden, weniger Step-Penalty-Dominanz.

#### 4. **Phase-Mixing lava-spezifisch machen**

Nicht zurück auf P0–P3 mischen:

* 70% aktuelle Phase
* 30% andere **Lava-Phasen**

Mixing soll Lava-Kompetenz erhalten, nicht Navigation.

#### 5. **β in Lava-Phasen erhöhen**

`1e-3 → 5e-3`

Hält Entropy länger oben und gibt dem Jump-Branch Re-Explorationschance.

---

### Quick-Win-Test

Nur:

* Fix 1 (PBRS-Fallback)
* Fix 3 (MaxSteps runter)

500k Test-Run.

Wenn danach erste Lava-Sprünge auftauchen, war der fehlende Gradient die Root Cause. Wenn nicht, ist die tote Sprung-Action das Primärproblem.

Die Datei ist übernommen. 

Und ja — alle `##` → `###`, alle `#` → `##` ergibt:

---

## V16-Plan — Lava-Skill-Lösung & Curriculum-Restrukturierung

**Datum:** 2026-05-17
**Stand:** V15 stagniert in Phase 5 (TrivialLavaCrossable) seit 2.46M Steps. `LavaJumps/Attempted = 0` über 8.5M Steps. Mean Reward driftet auf −8.0.
**Ziel V16:** Funktionierender PBRS-Gradient bei Lava-Layouts + lebendiger Sprung-Action-Branch + sinnvolles Episode-Budget.

---

### Übersicht — Was sich gegenüber V15 ändert

| Bereich           | V15 (Ist)                                                 | V16 (Soll)                                                              | Erwartete Wirkung                             |
| ----------------- | --------------------------------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------- |
| BFS / Pfaddistanz | `IsPathable` ignoriert Lava, BFS-Distanz `−1` → norm `1f` | Jump-aware-BFS: 1-Tile-Lava als Kante mit Sprung-Cost 3                 | PBRS-Gradient existiert auch in LavaCrossable |
| PBRS-Skalierung   | `distanceShapingScale=0.005`, `pbrsGamma=1` (Prefab)      | `distanceShapingScale=0.05`, `pbrsGamma=0.997` (Code+Prefab konsistent) | PBRS-Episode-Summe ≈ 0.05                     |
| PBRS-Pause        | `pausePbrsOverLava=true`                                  | Pause nur **über** Lava                                                 | Sprung-Annäherung bekommt Gradienten          |
| Sprung-Physik     | airControl=0.5                                            | airControl=1.0 / höhere Jump-Force                                      | 1-Tile-Lava zuverlässig                       |
| MaxStep P4–P7     | 15000                                                     | 1500                                                                    | 10× mehr Episoden                             |
| Step-Penalty      | `−0.001`                                                  | `−0.002` P0–P3, `−0.001` P4–P7                                          | Weniger Bestrafung fürs Probieren             |
| Timeout           | `−5`                                                      | `−10`                                                                   | Timeout unattraktiver                         |
| Phase-Mixing      | global                                                    | lava-spezifisch                                                         | Erhält Lava-Skill                             |
| Curriculum        | P0→P10                                                    | JumpWarmup vor Lava                                                     | Sprung-Logit kollabiert nicht                 |
| Beta              | konstant                                                  | Spike                                                                   | Re-Exploration                                |
| EMA               | `lastSampledPhaseIndex`                                   | + `currentPhaseIndex`                                                   | Saubere Phasen-Metrik                         |

**Ausgelassen in V16:** Action-Branch-Erweiterung, BC-Pretrain.

---

### 1. Befunde aus V15 (Recap mit Code-Belegen)

#### 1.1 PBRS strukturell tot — drei zusammenwirkende Bugs

**Bug A: `MapGenerator`-BFS widerspricht `SemanticPathfinder`.**

`MapGenerator.cs:489`

```csharp
private static bool IsPathable(CellType t)
{
    return t == CellType.Floor || t == CellType.SpawnPoint
        || t == CellType.Goal  || t == CellType.Obstacle
        || t == CellType.Platform;
}
```

`SemanticPathfinder.cs:96`

```csharp
if (cluster.depth == 1) return true;
if (cluster.hasPlatform) return true;
```

→ PBRS behandelt Lava als Wand, Layoutgenerator nicht.

**Bug B:** `pbrsGamma` Prefab ≠ Code.

**Bug C:** `distanceShapingScale=0.005` → PBRS ~40× schwächer als Step-Penalty.

**Bug D:** `pausePbrsOverLava=true` löscht den relevanten Gradienten.

#### 1.2 Sprung-Branch deterministisch kollabiert

* BranchSizes `[3,3,2]`
* `airControlFactor=0.5`
* ~5M Steps ohne Reward für Sprung
* Reichweite ≈ `0.71 unit`
* Lava benötigt ≥ `1.0 unit`

→ Physikalisch knapp nicht schaffbar.

#### 1.3 `phaseMaxSteps[4..7]=15000`

→ Timeout-Episoden bis −20 Reward möglich.

#### 1.4 Strukturelle Probleme

* Z1: Mixing sabotiert Sprunglernen
* Z2: EMA nutzt falsche Phase
* Z3: Reward-Asymmetrie

---

### 2. V16 Priorität P0 — Pflicht-Fixes

#### Fix A: Jump-aware-BFS

**Datei:** `MapGenerator.cs`

```csharp
CellType nextCell = currentMapData.GetCell(nx, ny);

if (IsFloorLike(nextCell)) edgeCost = 1;
else if (IsCrossableLava(nextCell, nx, ny)) edgeCost = 3;
else continue;
```

#### Fix B: PBRS-Konsistenz

```yaml
distanceShapingScale: 0.05
pbrsGamma: 0.997
```

#### Fix C: PBRS nur über Lava pausieren

```csharp
bool pauseShaping = pausePbrsOverLava && aboveLava;
```

#### Fix D: Sprung-Physik

Option D1:

```yaml
airControlFactor: 1.0
```

Option D2:

```yaml
maxUpwardVelocity: 5.0
phaseJumpForces[4..7]: 5
```

#### Fix E: `phaseMaxSteps`

```yaml
600
600
600
600
800
1500
1500
1500
1500
1500
2000
2500
```

---

### 3. V16 Priorität P1 — Sprung wiederbeleben

#### Fix F: JumpWarmup-Phase

Neue Phase:

`TrivialJumpWarmup = 11`

Layout:

* 7×7
* Spawn ↔ Goal
* 1 Tile Gap
* Sprung zwingend

#### Fix G: Lava-Mixing

P5:

```yaml
mixingPool = [4,5]
```

P6:

```yaml
mixingPool = [4,5,6]
```

usw.

#### Fix H: Beta-Schedule

```yaml
beta: 5e-3
beta_schedule: linear
```

#### Fix I: Optionaler Jump-Bonus

```csharp
if (phaseIdx >= 4 && phaseIdx <= 8)
{
    AddReward(0.0005f);
}
```

---

### 4. V16 Priorität P2 — Curriculum & Diagnose

#### Fix J

```yaml
timeoutPenalty: -10
```

#### Fix K

```yaml
phaseStepPenalties:
- -0.002
- -0.002
- -0.002
- -0.002
- -0.0005
...
```

#### Fix L

EMA nur für aktive Phase:

```csharp
if (phase == currentPhaseIndex)
{
   successRateEMA[phase] = ...
}
```

#### Fix M

Neue Stats:

* `Custom/JumpsTotal`
* `Custom/JumpsNearLava`
* `Custom/PathDistInit`
* `Custom/PathDistFinal`

---

### 5. Curriculum-Restrukturierung

#### 5.1 Neue Reihenfolge

| Idx | Phase         | Threshold | MaxStep |
| --- | ------------- | --------- | ------- |
| 0   | TrivialBase   | 1200      | 600     |
| 1   | TrivialCorr   | 1800      | 600     |
| 2   | TrivialBranch | 2600      | 600     |
| 3   | TrivialHole   | 3600      | 600     |
| 4   | JumpWarmup    | 3000      | 800     |
| 5   | LavaSurround  | 4000      | 1500    |
| 6   | LavaCrossable | 4300      | 1500    |
| 7   | LavaWide      | 4600      | 1500    |
| 8   | Hazard        | 5000      | 1500    |
| 9   | Easy          | 8000      | 1500    |
| 10  | Medium        | 12000     | 2000    |
| 11  | Hard          | 20000     | 2500    |

#### 5.2 JumpWarmup

Option 1: `Gap`

Option 2: Bridge-Hack

Empfehlung: **Gap**.

#### 5.3 Unverändert

* `useSuccessRateAdvance=1`
* `threshold=0.7`
* `EMAAlpha=0.02`

---

### 6. Implementierungs-Reihenfolge

#### Schritt 1

1. Dijkstra
2. PBRS-Pause
3. EMA
4. MixingPool
5. Stats

#### Schritt 2

6. `Gap`
7. Prefab
8. Pathfinder

#### Schritt 3

9. `TrivialJumpWarmup`
10. Layouts

#### Schritt 4

11. Prefab-Update

#### Schritt 5

12. Curriculum-Asset

#### Schritt 6

13. YAML

#### Schritt 7

14. Test
15. QuickRun
16. FullRun

---

### 7. Erfolgs-Kriterien

#### QuickRun

| Metrik     | Ziel  |
| ---------- | ----- |
| JumpsTotal | >1    |
| PBRS       | >0.01 |
| Phase      | ≥ P5  |
| SR P4      | ≥0.5  |

#### FullRun

| Metrik      | Ziel    |
| ----------- | ------- |
| Phase @30M  | ≥P8     |
| LavaSuccess | >0.5    |
| Reward P6   | >0      |
| Phase @60M  | P10–P11 |

#### Abbruch

* `JumpsTotal=0`
* `PBRS<0.005`
* `Reward P0 < +15`

---

### 8. Konsistenzcheck

Alle Arrays: **11 → 12**

* `phaseJumpForces`
* `phaseLavaDeathPenalties`
* `phaseStepPenalties`
* `phaseMaxSteps`
* `Curriculum phases`

---

### 9. Vertagt

* Action Branch 3 Outputs
* BC Pretrain
* AirControl-Schedule
* Per-Phase-Beta
* Diversity-Metrik

---

### 10. Risk Register

| Risiko               | W       | Impact       | Mitigation        |
| -------------------- | ------- | ------------ | ----------------- |
| Dijkstra Regression  | mittel  | P0–P3        | QuickRun          |
| airControl=1         | niedrig | Overshoot    | Wall-Climb-Pause  |
| Beta=5e-3            | niedrig | RandomWalk   | längerer Schedule |
| JumpWarmup trivial   | mittel  | Sprung tot   | Gap erzwingen     |
| Mixing bricht Config | hoch    | Editorfehler | null=Default      |

---

### 11. Zusammenfassung

1. **PBRS reparieren** → Jump-aware BFS + Scale + Pause-Fix
2. **Sprung reanimieren** → JumpWarmup + Lava-Mixing + Beta + Physik
3. **Episode-Budget fixen** → MaxStep runter + Timeout hoch + StepPenalty neu

### V16 Recap
### Kurzfassung des Problems

**Der Agent hängt seit ~1.5M Steps in Phase 1 (`TrivialCorr` — Raum + Korridor + Raum, keine Lava, keine Hindernisse) bei SR ≈ 0.50 fest und kommt nicht über 0.70.**

#### Drei zusammenwirkende Gates

1. **Beta zu hoch** — `beta=5e-3` mit linearem Schedule über `max_steps=60M`. Bei Step 2.2M ist Beta praktisch unverändert (~4.82e-3). Policy-Entropie 2.36 = 82 % des Maximums → Policy ist noch zu 82 % zufällig.

2. **SR-Threshold blockiert** — `useSuccessRateAdvance=1`, `successRateThreshold=0.7`. Mit so zufälliger Policy unerreichbar.

3. **Mixing-Pool [0,1]** — In P1 sieht der Agent ausschließlich Trivial + TrivialCorr. Keine Lava, kein Sprung-Skill nötig.

#### Selbstverstärkende Schleife

Hohes Beta → Policy bleibt zufällig → SR < 0.7 → kein Phase-Advance → keine Lava-Phasen → Sprung-Logit, für den Beta erhöht wurde, ist gar nicht relevant → Beta richtet nur Schaden an.

#### Konsequenz für die Lava-Metriken

`JumpsNearLava = 0`, `LavaJump* = 0` über 59 Datenpunkte ist **kein Vermeidungs-Verhalten**, sondern **physische Abwesenheit von Lava in jedem einzelnen Layout**. Phase 1 (TrivialCorr) enthält per Code (`ProceduralLayoutGenerator.cs:366-372`) keine Lava-Zelle.

#### Fix-Hebel (Reihenfolge der Wirksamkeit)

`beta: 5e-3 → 1e-3` · `successRateThreshold: 0.7 → 0.55` · `max_steps: 60M → 10M`

---

## V17-Plan — Phase-1-Gate auflösen

**Datum:** 2026-05-18
**Stand bei Trigger:** V16 Step 1.04M, SR_P1 EMA 0.458, Entropie 2.44 (≈ 84 % Max), 0 Lava-Sichtungen.
**Hypothese:** Die drei Gates aus dem V16-Recap wirken multiplikativ. Wird β gesenkt und der Advance-Threshold angepasst, ist das Curriculum aus eigener Kraft durchlaufbar — alle anderen V16-Änderungen (PBRS-Konsistenz, JumpWarmup, Mixing-Pools, Physik) bleiben unangetastet.

### Änderungen gegenüber V16

| Hebel                  | Datei : Zeile                                  | V16          | V17          | Wirkung                                                            |
| ---------------------- | ---------------------------------------------- | ------------ | ------------ | ------------------------------------------------------------------ |
| `beta`                 | `config/labyrinth_transformer.yaml:18`         | `5.0e-3`     | `1.0e-3`     | Entropie darf nach Lava-Bedarf absinken; in P0–P3 nicht mehr blockierend |
| `max_steps`            | `config/labyrinth_transformer.yaml:37`         | `60000000`   | `10000000`   | Linearer Beta-Decay 6× schneller — β bei 1M ≈ 0.9e-3 statt 4.92e-3 |
| `successRateThreshold` | `Assets/CurriculumConfig_Default.asset:1525`   | `0.7`        | `0.55`       | EMA P1 (heute 0.46, steigend) erreicht die Hürde realistisch       |

Alles andere unverändert: `useSuccessRateAdvance=1`, `successRateEMAAlpha=0.02`, `minEpisodesBeforeAdvance=1000`, alle `mixingPool`-Felder, alle Phase-Thresholds, `learning_rate_schedule: constant`, `curiosity.strength=0.02`.

### Pre-Flight

1. In Unity `Tools → V16 → Generate JumpWarmup Layouts` ausgeführt → 100 Assets `Assets/Layouts/Procedural/Layout_P_TrivialJumpWarmup_001.asset` … `_100.asset`.
2. Editor speichert (`AssetDatabase.SaveAssets()` + Ctrl+S) ⇒ `CurriculumConfig_Default.asset` Phase index 4 (`difficulty: 11`) bekommt 100 fileID-Einträge.
3. Ohne diesen Schritt: harter Abbruch sobald Phase 3 → 4 advanced (CurriculumTracker logged „hat keine Layouts zugewiesen!").

### Erwartete Trajektorie

- **~0.5–1.5M Steps:** SR_P1 EMA passiert 0.55 → Advance P1→P2.
- **~3M Steps:** P5 (`TrivialLavaSurround`) erreicht — ab hier sollten `Custom/JumpsNearLava > 0` und `Custom/LavaJumps/Attempted > 0` erstmals auftreten.
- **~10M Steps:** Beta-Boden erreicht (β≈0), Policy in Lava-Phasen ausreichend deterministisch.

### Decision-Punkte

| Step | Erwartung                                                              | Wenn verfehlt                                                                 |
| ---- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 2M   | `Custom/CurriculumPhase ≥ 2`                                           | β oder SR-Threshold immer noch zu hoch — Threshold auf 0.5 senken             |
| 5M   | Phase ≥ 5 **und** `Custom/LavaJumps/Attempted > 0`                     | Sprung-Skill physikalisch tot — D-Hebel aus V16-Plan ziehen (airControl 1.0)  |
| 10M  | Mean Reward > +5 in P5–P7                                              | nächste Iteration mit V16-Plan §3–§4 (Jump-Bonus, Step-Penalty-Refinement)    |

### Risiken

- **β = 1e-3 könnte in späten Lava-Phasen zu niedrig sein** für Re-Exploration. Mitigation: Decision-Punkt 5M.
- **`max_steps = 10M`** bei `learning_rate_schedule: constant` wirkt nur auf Beta-Decay; LR bleibt 1e-4. Frühabbruch unbedenklich.
- **`mixingPool [0,1]` in P1 unverändert** — sobald P2 erreicht ist, sieht der Agent über Mixing aber wieder Variationen aus P0/P1. Erst ab P4 (JumpWarmup) bzw. P5 (LavaSurround) tritt Lava auf.

### Erfolg = Hard-Kriterium

V17 gilt als Erfolg, wenn am Ende des Runs `Custom/CurriculumPhase ≥ 5`, `Custom/LavaJumps/Successful > 0` (kumuliert) und Entropie < 1.8.

### V17-Änderungen — Zusammenfassung

**Drei Kern-Hebel (gegen das Phase-1-Gate von V16):**

| Hebel                  | Datei                                        | Alt → Neu         | Wirkung                                             |
| ---------------------- | -------------------------------------------- | ----------------- | --------------------------------------------------- |
| β                      | `config/labyrinth_transformer.yaml:18`       | `5.0e-3 → 1.0e-3` | Entropie darf sinken, Policy wird deterministischer |
| `max_steps`            | `config/labyrinth_transformer.yaml:37`       | `60M → 10M`       | β-Linear-Decay 6× schneller                         |
| `successRateThreshold` | `Assets/CurriculumConfig_Default.asset:1625` | `0.7 → 0.55`      | EMA-Threshold erreichbar (EMA P1 stand bei 0.46)    |

**Pre-Flight-Setup:**

| Aktion                                | Datei                                           | Detail                                                                                                                          |
| ------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 100 JumpWarmup-Layouts ins Curriculum | `Assets/CurriculumConfig_Default.asset:445–546` | `layouts: []` durch 100 GUID-Referenzen ersetzt (direkt aus den `.meta`-Files extrahiert)                                       |
| Editor-Tool um TJW erweitert          | `Assets/Editor/MapGeneratorEditor.cs`           | `TrivialJumpWarmup = 1 << 11` in `DifficultyMask`-Enum, Switch-Case in `DifficultyToMask`, Sort-Position 4 in `DifficultyOrder` |

**Doku:**

| Datei                                                      | Inhalt                                                                                                                                                                                                       |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Dokumentation/Trainingsanalyse_Transformer_Milestone7.md` | V17-Plan-Block angehängt: Hypothese, Hebel-Tabelle, erwartete Trajektorie (P5 bei ~3M, β-Boden bei 10M), Decision-Punkte bei 2M/5M/10M, Erfolgskriterium (`Phase≥5`, `LavaJumps/Successful>0`, Entropie<1.8) |

**Unverändert** (bewusst): `useSuccessRateAdvance=1`, `successRateEMAAlpha=0.02`, `minEpisodesBeforeAdvance=1000`, alle `mixingPool`-Einträge, alle Phase-`threshold`-Werte, `learning_rate_schedule: constant`, `curiosity.strength=0.02`, alle V16-Änderungen an PBRS / Sprung-Physik / Phase-Thresholds.
.
