# Transformer-Integration – Konzept & Umsetzungsplan

## Ist-Stand des Projekts

- **Agent**: `Assets/Scripts/Agent/LabyrinthAgent.cs`
- **Observations**: 13 flache Float-Werte pro Timestep
  - 6× Boden-Sensor (Typ-Code + normierte Distanz für 3 Raycast-Positionen)
  - 3× normierte Eigengeschwindigkeit (x, y, z)
  - 1× isGrounded
  - 3× normierte Richtung zum Ziel (x, y, z)
- **Aktionen**: Diskret — Branch 0: 5 Bewegungsrichtungen, Branch 1: binärer Sprung
- **Aktuelles Modell**: Standard-MLP von ML-Agents (Barracuda 2.0.0)
- **RL-Algorithmus**: PPO (ML-Agents Trainer)

---

## Motivation für den Transformer

Das aktuelle MLP sieht nur den **aktuellen Timestep** — es hat kein Gedächtnis. Ein Transformer kann über eine **Sequenz vergangener Beobachtungen** attendieren und so zeitliche Muster erkennen:

- "Ich laufe seit 3 Schritten auf Lava zu" → früher umkehren
- "Die letzte Aktion hat mich dem Ziel genähert" → Richtung beibehalten
- Robustheit gegenüber zufälligen Hindernisplatzierungen (Map wechselt jede Episode)

Das ist der entscheidende konzeptuelle Unterschied zum MLP und direkt in der Aufgabenstellung gefordert.

---

## Ansatz 1: Custom PyTorch Policy via ML-Agents Python API (empfohlen)

### Schritt 1 — BufferSensor in Unity (C#)

`BufferSensorComponent` sammelt die letzten N Beobachtungen als Sequenz.

Im Unity Inspector am Agent-GameObject hinzufügen:
- **Observable Size**: 13 (Größe eines einzelnen Observation-Vektors)
- **Max Num Observables**: 8 (Fenstergröße = 8 Timesteps)

In `LabyrinthAgent.cs` — am Ende von `CollectObservations()`:

```csharp
// BufferSensor-Referenz als Feld
private BufferSensorComponent bufferSensor;

public override void Initialize()
{
    rb = GetComponent<Rigidbody>();
    bufferSensor = GetComponent<BufferSensorComponent>();
    FindGoal(warnIfMissing: false);
}

public override void CollectObservations(VectorSensor sensor)
{
    // ... bestehende 13 Observations wie bisher ...

    // Aktuellen Step als Token in den BufferSensor pushen
    float[] stepToken = new float[]
    {
        typeCode0, dist0, typeCode1, dist1, typeCode2, dist2,   // 6× Boden
        normalizedVelocity.x, normalizedVelocity.y, normalizedVelocity.z, // 3× Velocity
        isGrounded ? 1f : 0f,                                              // 1× Ground
        directionToGoal.x, directionToGoal.y, directionToGoal.z           // 3× Ziel
    };
    bufferSensor.AppendObservation(stepToken);
}
```

### Schritt 2 — Custom Transformer in Python

Neue Datei: `training/transformer_policy.py`

```python
import torch
import torch.nn as nn

class TransformerEncoder(nn.Module):
    """
    Nimmt eine Sequenz von Observation-Vektoren und gibt einen
    latenten Zustandsvektor zurück, den der Actor/Critic-Kopf verwendet.
    
    Input:  [batch, seq_len, obs_size]  z.B. [512, 8, 13]
    Output: [batch, d_model]            z.B. [512, 64]
    """
    def __init__(self, obs_size=13, d_model=64, nhead=4, num_layers=2, seq_len=8):
        super().__init__()
        self.embedding   = nn.Linear(obs_size, d_model)
        self.pos_enc     = nn.Embedding(seq_len, d_model)   # gelernte Positionskodierung
        encoder_layer    = nn.TransformerEncoderLayer(
            d_model=d_model, nhead=nhead,
            dim_feedforward=128, dropout=0.1, batch_first=True
        )
        self.transformer = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.output_proj = nn.Linear(d_model, 128)

    def forward(self, obs_sequence):
        B, T, _ = obs_sequence.shape
        positions = torch.arange(T, device=obs_sequence.device)
        x = self.embedding(obs_sequence) + self.pos_enc(positions)
        x = self.transformer(x)
        return self.output_proj(x[:, -1, :])   # letzter Token = aktuelle Entscheidung
```

### Schritt 3 — Trainer-Konfiguration (YAML)

```yaml
# config/labyrinth_transformer.yaml
behaviors:
  LabyrinthAgent:
    trainer_type: ppo
    network_settings:
      memory:
        sequence_length: 8    # Fenster: 8 vergangene Steps
        memory_size: 64       # d_model des Transformers
    hyperparameters:
      batch_size: 512
      buffer_size: 10000
      learning_rate: 3.0e-4
      beta: 5.0e-3
      epsilon: 0.2
      lambd: 0.95
      num_epoch: 3
    reward_signals:
      extrinsic:
        gamma: 0.99
        strength: 1.0
    max_steps: 5000000
    time_horizon: 64
    summary_freq: 10000
```

---

## Ansatz 2: Decision Transformer

Der **Decision Transformer** (Chen et al., 2021) nimmt als Input die Sequenz
`(Return-to-go, State, Action)` und lernt durch Supervised Learning auf gesammelten
Trajectories, Aktionen vorherzusagen die einem Ziel-Return entsprechen.

**Vorteil für diese Aufgabe**: Passt direkt zur binären Reward-Struktur (+1 Ziel, -1 Tod).
Gut geeignet als dritte Variante im Bericht-Vergleich.

**Implementierung**: Über die ML-Agents Low-Level Python API (`mlagents_envs`) —
Unity schickt Observations und empfängt Actions, das Transformer-Modell läuft komplett
in Python ohne Bindung an den ML-Agents Trainer.

---

## Ansatz 3: GTrXL (Gated Transformer-XL)

**Gated Transformer-XL** kombiniert LSTM-Gates mit Transformer-Attention.
Bekannt aus DeepMind's Agent57. ML-Agents hat experimentelle Unterstützung
über `use_recurrent: true` + angepasste Memory-Größe.

Aufwändiger, aber interessant für den Bericht — zeigt Kenntnisstand zu
State-of-the-Art Memory-Architekturen.

---

## Vergleichsmatrix für die Ablationsstudie

| Variante | Modell | Sequenz | Notizen |
|----------|--------|---------|---------|
| Baseline | MLP | 1 Step | Aktueller Stand, Pflicht laut Aufgabe |
| V1 | Transformer (2 Layer, 4 Head) | 8 Steps | Empfohlene Hauptvariante |
| V2 | Transformer (4 Layer, 8 Head) | 8 Steps | Ablation: Modellgröße |
| V3 | Transformer (2 Layer, 4 Head) | 4 Steps | Ablation: Fenstergröße |
| V4 | Transformer (2 Layer, 4 Head) | 16 Steps | Ablation: Fenstergröße |
| V5 | Decision Transformer | 8 Steps | Bonus-Variante |

---

## Empfohlene Implementierungsreihenfolge

1. **`BufferSensor`** in `LabyrinthAgent.cs` einbauen — gibt die Sequenzdaten
2. **MLP-Baseline** trainieren und Metriken sichern (Pflicht für Vergleich)
3. **`transformer_policy.py`** schreiben und mit ML-Agents integrieren
4. **Transformer V1** trainieren, Metriken mit Baseline vergleichen
5. **Ablationen** durchführen (Fenstergröße, Modellgröße)
6. Ergebnisse in Bericht dokumentieren

---

## Technische Hinweise

- **ML-Agents Python API-Version**: Prüfen ob `mlagents` >= 0.28 installiert ist
  — ab dann sind Custom PyTorch Policies offiziell unterstützt
- **Alternative zu ML-Agents Trainer**: CleanRL oder Stable-Baselines3 mit
  `mlagents_envs` als Gym-Wrapper — mehr Freiheit bei der Modellarchitektur
- **Barracuda 2.0.0** (bereits im Projekt) unterstützt den Inference-Export
  von trainierten `.onnx`-Modellen zurück nach Unity für Deployment

---

## Relevante Quellen (zur Dokumentation im Bericht)

- Chen et al. (2021): *Decision Transformer: Reinforcement Learning via Sequence Modeling*
- Parisotto et al. (2020): *Stabilizing Transformers for Reinforcement Learning* (GTrXL)
- ML-Agents Dokumentation: Custom Network Architectures
- Vaswani et al. (2017): *Attention Is All You Need* (Original Transformer)
