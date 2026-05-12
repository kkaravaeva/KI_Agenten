Jetzt habe ich alles für eine vollständige Analyse. Das wird umfangreich:

---

# MASTER PLAN — Finales Transformer-Training

---

## Hardware-Analyse

| Komponente  | Spezifikation                         | Bewertung                                        |
| ----------- | ------------------------------------- | ------------------------------------------------ |
| CPU         | AMD Ryzen 5 5625U, 6C/12T, 2.3 GHz    | Laptop-CPU, ausreichend für 4 parallele Prozesse |
| RAM         | 32 GB DDR4 3200 MHz                   | **Sehr gut** — kein Flaschenhals                 |
| GPU         | RTX 3050 Laptop, **4.3 GB VRAM**      | CUDA aktiv ✓, VRAM ist der limitierende Faktor   |
| Disk        | 476 GB, 55 GB frei                    | Ausreichend für Checkpoints                      |
| VRAM-Budget | Modell: ~51 MB, Aktivierungen: ~42 MB | **~4.1 GB Headroom** nach Modell/Optimizer       |

**Kritische Hardware-Warnung**: Das ist ein Laptop. 7 Tage Dauerlast bei 100% CPU+GPU führt zu thermischem Throttling. Das halbiert in schlimmsten Fällen die Trainingsgeschwindigkeit nach 8–12 Stunden.

**Maßnahme**: Laptop auf harte Oberfläche stellen, Belüftung freihalten, ggf. Kühlpad. Kein Betrieb auf Bett oder Decke.

---

## Aktuelle Engpässe (was uns bremst)

```
Setup jetzt:          Standalone+optimiert:    Delta:
───────────────────────────────────────────────────────
1 Unity Editor        4 Unity Processes        4×
10 Areas/Szene        10 Areas/Prozess         gleich → 40 Agents total
time_scale=1 (!)      ML-Agents default=20     20×  (bereits aktiv via mlagents)
Mit Rendering         no_graphics=true         +20%
~300 Steps/Sek        ~1.500–2.000 Steps/Sek   5–6×
```

**Wichtige Entdeckung**: `ProjectSettings/TimeManager.asset` hat `m_TimeScale: 1` — aber ML-Agents überschreibt das auf 20 beim Start. Das ist bereits aktiv. Kein Handlungsbedarf.

---

## Optimierungsstapel (Impact-Reihenfolge)

### 1. Standalone Build + `--num-envs=4` ← größter Hebel

```
VRAM-Check:  4 × 200 MB = 800 MB → 3.5 GB frei ✓
CPU-Check:   4 × 2 Threads = 8 Threads + 2 Python = 10/12 Threads ✓
RAM-Check:   4 × 800 MB Unity + 2 GB Python = 5.2 GB / 32 GB ✓
```

Mit `--num-envs=4` × 10 Areas = **40 parallele Agenten**.

### 2. `seq_len: 8 → 16` (keine Codeänderung nötig)

Einfache YAML-Änderung, TransformerMemory bekommt `seq_len=16` automatisch über den Patch. Rollingbuffer wächst von 1.792 auf 3.840 Floats/Agent — bei 40 Agents = 0.6 MB Overhead. Negligible.

Für Easy/Medium/Hard-Maps (größere Korridore, längere Wege) bringt das messbar besseren Kontext.

### 3. Curiosity Reward (fast obligatorisch für Hard)

Agent bekommt intrinsische Belohnung für unbekannte Zustände — löst das Sparse-Reward-Problem auf Hard-Maps. ML-Agents 0.30 hat ICM nativ.

### 4. `normalize: true`

Über das Curriculum wechseln die Observationsverteilungen stark (7×7 → 37×45). Normalisierung stabilisiert den Encoder.

### 5. `no_graphics: true` + `quality_level: 0`

Nur mit Standalone Build. Spart ~20% GPU-Zeit.

### 6. `max_steps: 500_000_000`

Bei ~1.750 Steps/Sek läuft das Training **in ~80 Stunden durch** (~3.3 Tage). Die letzten 3.7 Tage trainiert der Agent dann ausschließlich auf Hard (loopPhases=false → bleibt auf letzter Phase). Das ist optimal.

---

## Finale Konfiguration

```yaml
behaviors:
  LabyrinthNavigator:
    trainer_type: ppo

    network_settings:
      normalize: true                # NEU: stabilisiert bei wechselnden Kartengrößen
      hidden_units: 256
      num_layers: 2
      memory:
        sequence_length: 16          # NEU: 8→16, 2× mehr Kontext für große Maps
        memory_size: 128
        memory_type: transformer

    hyperparameters:
      learning_rate: 1.0e-4
      batch_size: 512
      buffer_size: 40960             # passt für 40 parallele Agenten
      beta: 1.0e-3
      epsilon: 0.2
      lambd: 0.95
      num_epoch: 3
      learning_rate_schedule: linear

    reward_signals:
      extrinsic:
        gamma: 0.99
        strength: 1.0
      curiosity:                     # NEU: für Hard-Maps essenziell
        strength: 0.02
        gamma: 0.99
        encoding_size: 64
        learning_rate: 3.0e-4

    env_settings:                    # NEU
      time_scale: 20.0
      no_graphics: true              # nur Standalone, kein Rendering
      quality_level: 0

    max_steps: 500000000             # NEU: 500M für 7-Tage-Run
    time_horizon: 256
    summary_freq: 50000              # NEU: weniger I/O (war 10000)
    keep_checkpoints: 5
    checkpoint_interval: 500000     # NEU: alle ~5 Min (war 200k = 2 Min)
```

**Start-Befehl:**
```bash
"C:/Users/Finnl/mlagents-31008/Scripts/python.exe" -m mlagents.trainers.learn \
  config/labyrinth_transformer.yaml \
  --run-id=transformer_final \
  --env="path/to/LabyrinthTraining.exe" \
  --num-envs=4 \
  --force
```

---

## Erwarteter Verlauf über 7 Tage

```
Zeit        Steps         Phase           Was passiert
──────────────────────────────────────────────────────────────────────
0–3h        0–18M         Trivial         Entropy fällt 2.3→1.5
                                          Agent lernt 7×7 sicher
3h–18h      18M–108M      Easy            Erste echte Maze-Navigation
                                          15-20×18-25 Karten
18h–2d      108M–220M     Medium          Agent kämpft mit
                                          größeren Mazes + Loops
2d–3.5d     220M–500M     Hard            Curriculum fertig
3.5d–7d     500M–1.05B    Hard (weiter)   Reines Hard-Training
                                          ~550M Steps nur Hard
──────────────────────────────────────────────────────────────────────
Gesamt:     ~1 Milliarde Steps
```

**Was realistisch rauszuholen ist:**

| Schwierigkeit | Erwartung                                                          |
| ------------- | ------------------------------------------------------------------ |
| Trivial       | Sicher gelöst (100% Success Rate)                                  |
| Easy          | Gut generalisiert (80–95%)                                         |
| Medium        | Solide (60–80%)                                                    |
| Hard          | Partiell gelernt (30–60%) — von hier hängt viel an der Architektur |

Hard-Generalisierung unter 60% mit seq_len=16 ist realistisch. Über 80% bräuchte seq_len=32+ und deutlich mehr Steps.

---

## Todo-Liste für heute

```
[ ] 1. Windows: Energie/Update (5 Min)
[ ] 2. Unity: Run in Background (1 Min)
[ ] 3. Unity: Standalone Build erstellen (30–60 Min)
[ ] 4. YAML: finale Config einspielen (5 Min)
[ ] 5. LSTM-Hintergrundprozess beenden
[ ] 6. Test-Run: --num-envs=4 starten, 
       warten bis Step 50.000 → Entropy check
[ ] 7. Thermal-Test: 30 Min Volllast, 
       GPU-Temp prüfen (HWMonitor)
[ ] 8. Finalen Run starten
```


● Direkter Vergleich:

  ┌──────────────┬───────────────────┬──────────────────┐
  │              │    Dein Laptop    │ Kollege Desktop  │
  ├──────────────┼───────────────────┼──────────────────┤
  │ CPU          │ Ryzen 5 5625U,    │ Ryzen 5 3600,    │
  │              │ 2.3 GHz, 6C/12T   │ 3.6 GHz, 6C/12T  │
  ├──────────────┼───────────────────┼──────────────────┤
  │ GPU          │ RTX 3050 Laptop,  │ GTX 1660, 6 GB   │
  │              │ 4.3 GB VRAM       │ VRAM             │
  ├──────────────┼───────────────────┼──────────────────┤
  │ RAM          │ 32 GB             │ 16 GB            │
  ├──────────────┼───────────────────┼──────────────────┤
  │ GPU          │ Ampere (neuer)    │ Turing           │
  │ Architektur  │                   │                  │
  ├──────────────┼───────────────────┼──────────────────┤
  │ TDP CPU      │ ~25W (Laptop)     │ 65W (Desktop)    │
  ├──────────────┼───────────────────┼──────────────────┤
  │ TDP GPU      │ ~40–80W           │ 120W (konstant)  │
  │              │ (gedrosselt)      │                  │
  └──────────────┴───────────────────┴──────────────────┘

  ---
  Entscheidung: Desktop für den 7-Tage-Run

  Der einzige Faktor der wirklich zählt: thermisches
  Throttling.

  Dein Laptop wird nach wenigen Stunden Dauerlast drosseln.
  Das ist keine Frage des ob, sondern des wann und wie
  stark. Der Desktop läuft 7 Tage bei 100% ohne zu
  throttlen.

  Dein Laptop:   Peak 8 TFLOPS → nach 4h Dauerlast: ~4
  TFLOPS (-50%)
  GTX 1660:      konstant 5 TFLOPS × 7 Tage = gleich am Tag
  1 wie Tag 7

  Für unser Modell ist VRAM kein Unterschied — das Modell
  braucht nur ~200 MB, die GTX 1660 hat mit 6 GB sogar mehr
  Luft nach oben für größere Batches.

  RAM ist der einzige Punkt wo dein Laptop gewinnt (32 GB vs
   16 GB). Aber für --num-envs=4 braucht man nur ~6 GB RAM —
   16 GB des Kollegen reichen vollkommen.

  ---
  Empfehlung

  Nutze den Desktop des Kollegen für den 1-Wochen-Run.
  Zuverlässigkeit schlägt Peak-Performance bei einem
  unbeaufsichtigten 7-Tage-Lauf immer.

  Und die beste Option: beide Maschinen gleichzeitig — zwei
  unabhängige Runs mit identischer Config, unterschiedlicher
   --run-id. Nach einer Woche hast du zwei Trainings zum
  Vergleichen. Falls einer crasht, hast du den anderen als
  Backup.

  # Dein Laptop:
  --run-id=transformer_final_laptop

  # Kollege Desktop:
  --run-id=transformer_final_desktop