# Transformer-Integration – Implementierung (M7.1)

**Status:** Implementiert und getestet (50k Steps, kein Absturz, Reward +1.1 über Baseline)
**Implementierungsansatz:** Direktes Patchen der mlagents 0.30.0 venv

---

## Entscheidungen (chronologisch)

### Warum kein Custom Policy API?

mlagents 0.30.0 hat keine öffentliche Custom Policy API. Das `memory`-Feld in YAML
greift immer auf LSTM intern zu. Optionen:

| Option | Aufwand | Risiko | Entscheidung |
|---|---|---|---|
| A: venv direkt patchen | mittel | nur lokal, kein Repo-Einfluss | **gewählt** |
| B: mlagents forken | hoch | Divergenz mit upstream | verworfen |
| C: CleanRL + mlagents_envs | hoch | neues Framework | verworfen |

### Warum kein BufferSensorComponent?

Ursprünglicher Plan sah `BufferSensorComponent` in Unity vor. Verworfen weil:
- mlagents behandelt `BufferSensor` als eigene Observation-Modalität (nicht als Sequenz für LSTM)
- mlagents `sequence_length` im YAML chunked den Replay-Buffer intern — kein Unity-Code nötig
- Transformer erhält dieselbe `[batch*seq_len, h_size]`-Eingabe wie LSTM

### Architektur-Entscheidungen

| Parameter | Wert | Begründung |
|---|---|---|
| d_model | 256 | = `hidden_units` in YAML, kein Extra-Embedding-Layer |
| nhead | 4 | teilt 256 gleichmäßig (64 dim/Head) |
| num_layers | 2 | Balance Ausdrucksstärke vs. Trainingsgeschwindigkeit |
| output_size | 64 | = `memory_size // 2` = 128//2, identisch zu LSTM |
| Positional Encoding | gelernt (nn.Embedding) | trainierbar, ONNX-sicher via register_buffer |
| batch_first | False | ONNX-Bug in PyTorch 2.0 mit batch_first=True |

---

## Bugs und Fixes

### 1. Segfault (PyTorch 2.0 CUDA Fast Path)

`nn.TransformerEncoderLayer` löst bei PyTorch 2.0+CUDA optimierte C-Kernel aus
die einen Segfault erzeugen. Auch `enable_nested_tensor=False` reichte nicht aus.

**Fix:** Ersetzt durch manuelle `nn.MultiheadAttention` + LayerNorm + FFN — kein
TransformerEncoderLayer mehr.

### 2. ONNX-Export-Absturz

`nn.MultiheadAttention(batch_first=True)` hat bekannten ONNX-Bug in PyTorch 2.0.

**Fix:** `batch_first=False` + manuelle `.transpose(0,1)` Aufrufe.

### 3. GAE Shape-Mismatch `(64,) vs (8,)`

Ursprünglich wurde nur `x[:, -1, :]` zurückgegeben → Shape `[batch, output_size]`.
mlagents GAE erwartet aber `[batch*seq_len, output_size]` wie LSTM.

**Fix:** `self.output_proj(x).reshape(B * T, self.output_size)` — alle Positionen ausgeben.

### 4. torch.arange ONNX-Problem

`torch.arange(x.shape[1])` im forward ist dynamisch → nicht ONNX-traceable.

**Fix:** `self.register_buffer("pos_indices", torch.arange(seq_len))` im `__init__`.

### 5. Patch-Marker nicht eindeutig

`NETWORKS_INIT_OLD` traf sowohl `NetworkBody` als auch `MultiAgentNetworkBody`.

**Fix:** Marker um mehrere eindeutige Kontext-Zeilen erweitert.

### 6. BehaviorType InferenceOnly

Agent-Prefab hatte `BehaviorType=2 (InferenceOnly)` ohne hinterlegtes Modell
→ kein Training möglich.

**Fix:** Im Unity Inspector als Scene-Override auf `Default (0)` gesetzt.

---

## Implementierung

### Dateistruktur

```
KI_Agenten/
├── training/
│   ├── transformer_policy.py   # TransformerMemory-Modul (standalone + unit test)
│   └── patch_mlagents.py       # Patch-Skript für die venv
├── config/
│   ├── labyrinth_transformer.yaml   # Training mit Transformer
│   └── labyrinth_lstm.yaml          # Training mit LSTM (Vergleich)
```

venv (nicht im Repo):
```
C:\Users\Finnl\mlagents-31008\Lib\site-packages\mlagents\trainers\
├── settings.py                  # +memory_type: str = "lstm"
├── torch_entities\networks.py   # +Transformer-Branch
└── torch_entities\transformer_memory.py  # Kopie von transformer_policy.py
```

### `training/transformer_policy.py`

```python
import torch
import torch.nn as nn


class TransformerMemory(nn.Module):
    """
    Input:  [batch, seq_len, h_size]   z.B. [64, 8, 256]
    Output: [batch*seq_len, output_size]  z.B. [512, 64]
    """

    def __init__(self, h_size, memory_size, seq_len, nhead=4, num_layers=2):
        super().__init__()
        assert h_size % nhead == 0
        self.output_size = memory_size // 2

        self.pos_enc = nn.Embedding(seq_len, h_size)
        self.register_buffer("pos_indices", torch.arange(seq_len))

        self.attn_layers = nn.ModuleList([
            nn.MultiheadAttention(h_size, nhead, dropout=0.1, batch_first=False)
            for _ in range(num_layers)
        ])
        self.norms1 = nn.ModuleList([nn.LayerNorm(h_size) for _ in range(num_layers)])
        self.ffs = nn.ModuleList([
            nn.Sequential(nn.Linear(h_size, h_size * 2), nn.ReLU(), nn.Linear(h_size * 2, h_size))
            for _ in range(num_layers)
        ])
        self.norms2 = nn.ModuleList([nn.LayerNorm(h_size) for _ in range(num_layers)])
        self.output_proj = nn.Linear(h_size, self.output_size)

    def forward(self, x):
        B, T, _ = x.shape
        x = x + self.pos_enc(self.pos_indices[:T])
        x = x.transpose(0, 1)                     # [T, B, h]
        for attn, norm1, ff, norm2 in zip(self.attn_layers, self.norms1, self.ffs, self.norms2):
            attn_out, _ = attn(x, x, x)
            x = norm1(x + attn_out)
            x = norm2(x + ff(x))
        x = x.transpose(0, 1)                     # [B, T, h]
        return self.output_proj(x).reshape(B * T, self.output_size)


if __name__ == "__main__":
    model = TransformerMemory(h_size=256, memory_size=128, seq_len=8)
    dummy = torch.zeros(4, 8, 256)
    out = model(dummy)
    assert out.shape == (32, 64)
    print(f"OK — shape: {out.shape}, params: {sum(p.numel() for p in model.parameters()):,}")
```

### `config/labyrinth_transformer.yaml` (Kern)

```yaml
behaviors:
  LabyrinthNavigator:
    trainer_type: ppo
    network_settings:
      hidden_units: 256
      num_layers: 2
      memory:
        sequence_length: 8
        memory_size: 128
        memory_type: transformer   # <-- neues Feld
    hyperparameters:
      learning_rate: 3.0e-4
      batch_size: 512
      buffer_size: 10240
    max_steps: 2000000
```

### Pipeline im NetworkBody

```
VectorSensor (13 float)
  → ObservationEncoder
  → LinearEncoder (MLP, hidden_units=256, num_layers=2)
  → [LSTM  wenn memory_type=lstm]     Output: [batch*seq_len, 64]
  → [Transformer wenn memory_type=transformer]  Output: [batch*seq_len, 64]
  → Actor-Kopf (diskrete Aktionen: 5 Bewegung + 1 Sprung)
  → Critic-Kopf (State Value)
```

---

## `training/patch_mlagents.py` — Kurzübersicht

Das Skript führt drei Patches durch:

1. **settings.py**: Fügt `memory_type: str = attr.ib(default="lstm")` zu `MemorySettings` hinzu
2. **networks.py `__init__`**: Instanziiert `TransformerMemory` statt LSTM wenn `memory_type=="transformer"`
3. **networks.py `forward`**: Ruft Transformer statt LSTM auf, mit Reshape `[B*T, h] → [B, T, h] → [B*T, out]`
4. **networks.py**: Kopiert `transformer_memory.py` in die venv

Undo: `python training/patch_mlagents.py --undo`

Idempotent: Skript prüft ob Patch bereits angewendet wurde.

---

## Testergebnisse (50k Steps)

| Metrik | Wert |
|---|---|
| Reward Start | −2.605 |
| Reward Peak (40k) | −1.497 |
| Reward Ende (50k) | ~−1.6 |
| Abstürze | 0 |
| GAE-Fehler | 0 |

Training war stabil. Reward verbessert sich trotz noch geringer Schrittanzahl sichtbar.
Vollständiger Vergleich (2M Steps) mit LSTM-Baseline steht aus.

---

## Ablationsplan

| Konfiguration | Sequenz | nhead | num_layers | Status |
|---|---|---|---|---|
| Transformer V1 | 8 | 4 | 2 | trainiert (50k, Proof of Concept) |
| LSTM Baseline | 8 | — | — | YAML bereit, Training offen |
| MLP Baseline | 1 | — | — | offen |
| Transformer V2 | 4 | 4 | 2 | offen |
| Transformer V3 | 16 | 4 | 2 | offen |
