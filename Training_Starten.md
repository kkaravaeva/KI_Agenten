# ML-Agents Training – Anleitung & Nachschlagewerk

Diese Anleitung erklärt, wie das KI-Training für das Labyrinth-Projekt gestartet, überwacht und analysiert wird. Sie richtet sich an Teammitglieder, die noch nicht mit ML-Agents oder TensorBoard vertraut sind.

---

## Was passiert beim Training? (Überblick)

Bevor es losgeht, kurz das Grundprinzip:

**ML-Agents** ist ein Framework von Unity, das es ermöglicht, KI-Agenten in einer Unity-Szene durch Reinforcement Learning zu trainieren. Das funktioniert so:

1. **Unity** simuliert die Spielwelt. Der Agent (unser Labyrinth-Roboter) bewegt sich darin, bekommt Belohnungen (Rewards) wenn er das Ziel erreicht, und Strafen wenn er in ein Loch fällt oder zu lange braucht.
2. **mlagents-learn** ist ein Python-Prozess, der außerhalb von Unity läuft. Er empfängt die Beobachtungen und Rewards vom Agenten, trainiert ein neuronales Netz (Policy) und schickt dem Agenten neue Aktionsempfehlungen zurück.
3. **TensorBoard** ist ein Visualisierungswerkzeug, das den Lernfortschritt als Kurven im Browser anzeigt — z.B. ob der Reward im Laufe des Trainings steigt.

```
Unity (Simulation)  ←──────────────────→  mlagents-learn (Python, Training)
    Agenten beobachten & handeln               Policy wird verbessert
         ↓                                           ↓
    Reward-Signal                          TensorBoard-Logs schreiben
                                                     ↓
                                          Browser: http://localhost:6006
```

Unity und mlagents-learn kommunizieren über einen lokalen **Port (5004)**. Deshalb müssen beide Prozesse gleichzeitig laufen.

---

## Voraussetzungen & Einrichtung

### Python-Umgebung

mlagents-learn läuft in einer eigenen Python-Umgebung (Virtual Environment / venv), die alle nötigen Pakete enthält. Diese muss einmalig eingerichtet sein.

**Prüfen ob die Umgebung vorhanden ist:**

```bash
# Zeigt ob mlagents-learn erreichbar ist
mlagents-learn --help
```

Falls der Befehl nicht gefunden wird: → mlagents-Umgebung ist nicht aktiviert oder nicht installiert. Dann muss die Umgebung zuerst aktiviert werden:

```bash
# Wenn venv (Windows):
<pfad-zum-venv>\Scripts\activate

# Wenn venv (Mac/Linux):
source <pfad-zum-venv>/bin/activate

# Wenn conda:
conda activate mlagents
```

> Wo die Umgebung liegt, hängt vom jeweiligen Rechner ab. Wer die Umgebung eingerichtet hat, sollte den Pfad kennen.

**Versionen die getestet und funktionieren:**

| Paket | Version |
|---|---|
| mlagents | 0.30.0 |
| torch (PyTorch) | 2.0.1 |
| TensorBoard | 2.13.0 |
| Unity ML-Agents Package | 2.0.2 |

### Unity

- Unity-Projekt `KI_Agenten` öffnen
- Szene `Assets/Scenes/Training/Training_MultiArea.unity` laden

---

## Schnellstart (kurze Version)

Für alle die es eilig haben — die vollständige Erklärung folgt weiter unten.

**Terminal 1 — Training starten:**
```bash
mlagents-learn config/labyrinth_training.yaml --run-id=baseline_v1
```
Warten bis `Listening on port 5004` erscheint, dann in Unity **Play** drücken.

**Terminal 2 — TensorBoard starten:**
```bash
python -m tensorboard.main --logdir results --port 6006
```
Browser öffnen: **http://localhost:6006**

**Beenden:** In Unity **Stop** drücken, dann in Terminal 1 `Ctrl+C`.

---

## Schritt-für-Schritt-Anleitung

### Schritt 1 — Ins Projektverzeichnis wechseln

Alle Befehle müssen im Wurzelverzeichnis des Projekts ausgeführt werden (dort wo `config/`, `results/` und `Assets/` liegen).

```bash
cd <pfad-zum-projekt>/KI_Agenten
```

---

### Schritt 2 — mlagents-learn starten

```bash
mlagents-learn config/labyrinth_training.yaml --run-id=baseline_v1
```

**Was bedeuten die Parameter?**

- `config/labyrinth_training.yaml` — die Konfigurationsdatei, die festlegt wie das Training abläuft (Lernrate, Netzwerkgröße, wie lange trainiert wird, usw.)
- `--run-id=baseline_v1` — ein frei wählbarer Name für diesen Trainingslauf. Unter diesem Namen werden alle Ergebnisse in `results/baseline_v1/` gespeichert. Wichtig: der Name sollte beschreiben was getestet wird (z.B. `baseline_v1`, `test_reward_shaping`, `higher_lr`).

**Erwartete Ausgabe:**

```
[INFO] Listening on port 5004. Start training by pressing the Play button in the Unity Editor.
```

Der Python-Prozess wartet jetzt auf eine Verbindung aus Unity. Er tut noch nichts außer lauschen.

---

### Schritt 3 — Unity starten und verbinden

1. Unity Editor öffnen (falls nicht offen)
2. Szene `Assets/Scenes/Training/Training_MultiArea.unity` öffnen
3. **Play** drücken (der große Play-Button im Unity Editor)

**Erwartete Ausgabe in Terminal 1:**

```
[INFO] Connected to Unity environment with package version 2.0.2 and communication version 1.5.0
[INFO] Connected new brain: LabyrinthNavigator?team=0
[INFO] LabyrinthNavigator. Step: 10000. Time Elapsed: 67 s. Mean Reward: -2.391. Std of Reward: 0.301. Training.
```

Ab jetzt läuft das Training. Alle 10.000 Steps erscheint eine neue Zeile mit dem aktuellen Stand.

**Was bedeutet die Step-Ausgabe?**

- `Step: 10000` — Gesamtzahl der Entscheidungsschritte aller Agenten zusammen (wir haben 4 parallele Agenten, also sammeln alle 4 gleichzeitig Erfahrung)
- `Mean Reward: -2.391` — der durchschnittliche kumulierte Reward pro Episode. Am Anfang negativ, weil der Agent noch nichts gelernt hat und vor allem Step-Strafen ansammelt. Ein steigender Wert zeigt Lernfortschritt.
- `Std of Reward: 0.301` — Streuung der Rewards. Hohe Streuung = Agent verhält sich noch inkonsistent.

---

### Schritt 4 — TensorBoard starten

TensorBoard visualisiert den Lernfortschritt als Kurven im Browser. Es kann parallel zum Training gestartet werden.

**Terminal 2 öffnen** (mlagents-learn läuft weiter in Terminal 1) und ausführen:

```bash
python -m tensorboard.main --logdir results --port 6006
```

> **Hinweis:** Falls `tensorboard` als direkter Befehl nicht funktioniert (`tensorboard --logdir results`), immer `python -m tensorboard.main` verwenden — das ist zuverlässiger.

**Erwartete Ausgabe:**

```
TensorBoard 2.13.0 at http://localhost:6006/ (Press CTRL+C to quit)
```

Browser öffnen: **http://localhost:6006**

TensorBoard schreibt erst Daten, nachdem der erste `summary_freq`-Intervall abgelaufen ist (bei uns 10.000 Steps, also nach ~70 Sekunden). Falls die Kurven noch leer sind: warten und die Seite neu laden.

---

### Schritt 5 — Metriken verstehen

Im **SCALARS**-Tab von TensorBoard erscheinen folgende Kurven:

#### Environment/Cumulative Reward
Die wichtigste Kurve. Zeigt den durchschnittlichen kumulierten Reward pro Episode.

- **Startwert:** Negativ (~−2.2), weil der Agent am Anfang fast immer die maximale Episodenlänge ausschöpft und nur Step-Strafen akkumuliert
- **Lernfortschritt:** Wert steigt, wenn der Agent lernt das Ziel schneller zu erreichen
- **Zielwert:** Nahe 1.0 (Ziel erreicht, wenig Step-Strafen)

#### Environment/Episode Length
Wie viele Steps eine Episode im Durchschnitt dauert.

- **Startwert:** Nahe 2500 (MaxStep — Agent läuft meist in die Zeit)
- **Lernfortschritt:** Wert sinkt, wenn der Agent effizienter wird

#### Losses/Policy Loss
Wie stark sich die Policy (das Entscheidungsverhalten) von Update zu Update ändert.

- Am Anfang größere Werte, wird kleiner wenn das Training konvergiert
- Sehr große oder explodierende Werte können auf Probleme mit der Lernrate hindeuten

#### Losses/Value Loss
Wie gut das Netzwerk den erwarteten zukünftigen Reward vorhersagt.

- Ähnliches Muster wie Policy Loss
- Sinkt über Zeit wenn das Netzwerk die Umgebung besser versteht

#### Orientierungswerte (Testlauf vom 14.04.2026)

In den ersten 50.000 Steps ist kein deutlicher Lernfortschritt zu erwarten — das dient nur der Verifikation. Echter Lernfortschritt beginnt typischerweise nach 200.000–500.000 Steps.

| Step | Mean Reward | Anmerkung |
|------|-------------|-----------|
| 10.000 | ~−2.4 | Startpunkt, reine Exploration |
| 50.000 | ~−2.0 | Kein echter Fortschritt, normale Schwankung |
| 200.000+ | tbd | Erste Lernzeichen erwartet |

---

### Schritt 6 — Training beenden

**Sauberes Beenden (empfohlen):**
1. In Unity **Stop** drücken
2. mlagents-learn erkennt die getrennte Verbindung und wartet neu auf Port 5004
3. In Terminal 1: `Ctrl+C` drücken

**Sofortiger Abbruch:**
In Terminal 1 einfach `Ctrl+C`.

**TensorBoard beenden:**
In Terminal 2: `Ctrl+C`

> mlagents-learn speichert beim Beenden keinen zusätzlichen Checkpoint. Der zuletzt gespeicherte Checkpoint bleibt erhalten. Checkpoints werden alle 200.000 Steps automatisch gespeichert.

---

### Schritt 7 — Training fortsetzen (nach Unterbrechung)

Falls das Training unterbrochen wurde (PC neugestartet, Unity abgestürzt, etc.) kann es am letzten Checkpoint fortgesetzt werden:

```bash
mlagents-learn config/labyrinth_training.yaml --run-id=baseline_v1 --resume
```

`--resume` sucht den letzten Checkpoint in `results/baseline_v1/` und setzt dort fort. Danach wieder in Unity Play drücken.

---

## Projektstruktur während des Trainings

Während des Trainings entstehen folgende Dateien:

```
results/
└── baseline_v1/                          ← ein Verzeichnis pro run-id
    ├── LabyrinthNavigator/
    │   ├── LabyrinthNavigator-200000.onnx ← Checkpoint nach 200k Steps
    │   ├── LabyrinthNavigator-400000.onnx ← Checkpoint nach 400k Steps
    │   └── events.out.tfevents.*          ← TensorBoard-Rohdaten
    ├── configuration.yaml                 ← Kopie der YAML zum Zeitpunkt des Starts
    └── run_logs/
        ├── timers.json                    ← Performance-Metriken
        └── training_status.json           ← Aktueller Trainingsstand
```

**Was sind `.onnx`-Dateien?**
ONNX (Open Neural Network Exchange) ist ein plattformübergreifendes Format für trainierte neuronale Netze. Unity kann `.onnx`-Dateien direkt einlesen — so wird das trainierte Modell später in die Szene integriert, damit der Agent ohne Python-Verbindung autonom handeln kann.

---

## Was bedeuten die Trainingskonfigurationsparameter?

Die vollständige Konfiguration liegt in `config/labyrinth_training.yaml`. Hier die wichtigsten Parameter erklärt:

| Parameter | Wert | Bedeutung |
|---|---|---|
| `trainer_type: ppo` | PPO | Proximal Policy Optimization — Standard-Algorithmus für diskrete Aktionsräume, stabil und bewährt |
| `max_steps: 2000000` | 2 Mio. | Gesamtanzahl Trainingsschritte über alle Agenten. ~800 Episoden für erste Baseline |
| `summary_freq: 10000` | 10.000 | Alle 10.000 Steps wird ein Datenpunkt in TensorBoard geschrieben |
| `checkpoint_interval: 200000` | 200.000 | Alle 200k Steps wird ein `.onnx`-Checkpoint gespeichert |
| `learning_rate: 3e-4` | 0.0003 | Wie stark das Netz pro Update angepasst wird. Zu groß = instabil, zu klein = langsam |
| `batch_size: 512` | 512 | Wie viele Erfahrungen pro Netzwerk-Update verwendet werden |
| `buffer_size: 10240` | 10.240 | Wie viele Erfahrungen vor jedem Update gesammelt werden (~4 Episoden) |
| `gamma: 0.99` | 0.99 | Discount-Faktor: wie stark zukünftige Rewards gewichtet werden. 0.99 = Agent plant ~100 Steps voraus |
| `hidden_units: 256` | 256 | Größe der versteckten Schichten im neuronalen Netz |
| `num_layers: 2` | 2 | Anzahl der Schichten im Netz |
| `behavior_name` | `LabyrinthNavigator` | Muss exakt mit dem Namen in Unity (BehaviorParameters-Komponente auf Agent.prefab) übereinstimmen |

**Was ist PPO?**
Proximal Policy Optimization ist ein Reinforcement-Learning-Algorithmus. Er trainiert eine *Policy* — eine Funktion, die aus Beobachtungen (was sieht der Agent?) Aktionen (was soll er tun?) macht. PPO ist besonders stabil, weil es verhindert, dass sich die Policy bei einem einzelnen Update zu stark verändert.

---

## Troubleshooting

### mlagents-learn startet nicht / Port-Fehler

**Symptom:**
```
RuntimeError: Failed to bind to address [::]:5004
UnityWorkerInUseException: worker number 0 is still in use
```

**Ursache:** Ein alter Python-Prozess (mlagents-learn) läuft noch und blockiert Port 5004.

**Lösung:**
```bash
# Windows (in cmd.exe):
netstat -ano | findstr 5004     # PID des Prozesses herausfinden
taskkill /PID <die-PID> /f      # Prozess beenden

# Mac/Linux:
lsof -i :5004                   # PID herausfinden
kill <die-PID>
```

Danach mlagents-learn neu starten.

---

### Vorheriger Run-ID gefunden

**Symptom:**
```
UnityTrainerException: Previous data from this run ID was found.
```

**Lösung:** Entweder `--resume` (fortsetzen) oder `--force` (Daten überschreiben) anhängen:

```bash
mlagents-learn config/labyrinth_training.yaml --run-id=baseline_v1 --resume
# oder
mlagents-learn config/labyrinth_training.yaml --run-id=baseline_v1 --force
```

---

### Unity verbindet sich nicht / kein "Connected"-Meldung

Mögliche Ursachen und Lösungen:

- Falsche Szene offen → `Assets/Scenes/Training/Training_MultiArea.unity` öffnen
- mlagents-learn noch nicht gestartet → erst Terminal-Befehl, dann Play
- Port 5004 blockiert → siehe Port-Fehler oben
- Unity ML-Agents Package falsche Version → in Unity unter Window → Package Manager prüfen (sollte 2.0.x sein)

---

### behavior_name stimmt nicht überein

**Symptom:** `[WARNING] No behavior name found` oder Agenten stehen still.

**Ursache:** Der `behavior_name` in der YAML stimmt nicht exakt mit dem Namen in Unity überein.

**Prüfen:**
1. In `config/labyrinth_training.yaml`: Wert von `behavior_name`
2. In Unity: `Assets/Prefabs/Agent/Agent.prefab` → Inspektor → `BehaviorParameters` → `Behavior Name`

Beide müssen identisch sein: `LabyrinthNavigator`

---

### TensorBoard zeigt keine Kurven

**Mögliche Ursachen:**

1. **Zu früh geöffnet** — TensorBoard schreibt erst nach 10.000 Steps. Warten und Seite neu laden.
2. **Falsches `--logdir`** — der Pfad muss auf das Elternverzeichnis aller Run-Ordner zeigen, also `results/` und nicht `results/baseline_v1/`.
3. **Keine Daten vorhanden** — prüfen ob `results/<run-id>/LabyrinthNavigator/events.out.tfevents.*` existiert.
4. **Browser-Cache** — Seite mit `Shift+F5` hart neu laden.

---

### Agent bewegt sich nicht / Reward bleibt konstant bei 0

- Prüfen ob das Training tatsächlich läuft (erscheinen Step-Meldungen in Terminal 1?)
- In Unity prüfen ob der Agent im Play-Mode sichtbar aktiv ist (Bewegung in der Szene)
- Prüfen ob `Decision Requester`-Komponente auf dem Agent-GameObject vorhanden ist

---

## Mehrere Experimente parallel verwalten

Jeder Run hat eine eigene `--run-id`. So können verschiedene Konfigurationen verglichen werden:

```bash
# Experiment 1: Basis-Konfiguration
mlagents-learn config/labyrinth_training.yaml --run-id=baseline_v1

# Experiment 2: Höhere Lernrate (YAML vorher anpassen)
mlagents-learn config/labyrinth_training.yaml --run-id=higher_lr_v1
```

TensorBoard zeigt alle Runs in `results/` gleichzeitig an — die Kurven der verschiedenen Experimente können direkt verglichen werden:

```bash
python -m tensorboard.main --logdir results --port 6006
```

---

## Glossar

| Begriff | Bedeutung |
|---|---|
| **Policy** | Das trainierte Entscheidungsverhalten des Agenten (gespeichert als `.onnx`-Datei) |
| **Episode** | Ein Durchlauf vom Start bis zum Ziel (oder bis zur maximalen Step-Anzahl) |
| **Step** | Ein einzelner Entscheidungsschritt des Agenten |
| **Reward** | Belohnungssignal, das dem Agenten nach einer Aktion gegeben wird |
| **Cumulative Reward** | Summe aller Rewards innerhalb einer Episode |
| **PPO** | Proximal Policy Optimization — der verwendete Trainingsalgorithmus |
| **behavior_name** | Bezeichner, über den Unity-Agent und Python-Trainer sich zuordnen |
| **run-id** | Frei wählbarer Name für einen Trainingslauf, bestimmt den Speicherort der Ergebnisse |
| **Checkpoint** | Zwischengespeicherter Zustand des neuronalen Netzes während des Trainings |
| **ONNX** | Dateiformat für trainierte neuronale Netze, das Unity direkt einlesen kann |
| **venv** | Python Virtual Environment — isolierte Python-Umgebung mit allen benötigten Paketen |
| **TensorBoard** | Web-Visualisierungswerkzeug für Trainingsmetriken |
| **summary_freq** | Wie oft (in Steps) TensorBoard-Datenpunkte geschrieben werden |
