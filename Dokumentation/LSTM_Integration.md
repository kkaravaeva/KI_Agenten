# LSTM-Integration – Implementierung (M7.2)

**Status:** Implementiert und unit-getestet
**Implementierungsansatz:** Custom `LSTMMemory`-Modul, analog zu `TransformerMemory`, über denselben venv-Patch

---

## Ziel

Eigenes LSTM-Modul als direkte Baseline zum Transformer-Vergleich.
Gleiche Schnittstelle, gleicher Einbettungspunkt im NetworkBody, gleiche GAE-Output-Shape — nur die Verarbeitungslogik unterscheidet sich.

---

## Architektur

| Parameter | Wert | Begründung |
|---|---|---|
| `input_size` | 256 (= `hidden_units`) | Eingabe direkt aus dem MLP-Encoder, kein Extra-Embedding-Layer |
| `hidden_size` | 64 (= `memory_size // 2`) | Identisch zu mlagents-Konvention und TransformerMemory `output_size` |
| `num_layers` | 1 | Konsistent mit mlagents Built-in LSTM; Balance Ausdrucksstärke vs. Trainingsgeschwindigkeit |
| `batch_first` | True | Natives `[batch, seq, feature]`-Format; kein Transpose nötig (anders als TransformerMemory) |
| Output | alle Zeitschritte | `[batch*seq_len, output_size]` — GAE-kompatibel, identisch zu TransformerMemory |
| h_0 / c_0 | nicht übergeben | Training verarbeitet vollständige Sequenzen (BPTT via mlagents); kein step-weises Memory-Passing nötig |

### Pipeline im NetworkBody

```
VectorSensor (13 float)
  → ObservationEncoder
  → LinearEncoder (MLP, hidden_units=256, num_layers=2)
  → LSTMMemory(h_size=256, memory_size=128)   ← memory_type: lstm
  → Actor-Kopf (diskrete Aktionen)
  → Critic-Kopf (State Value)
```

### Parametervergleich

| Modul | Parameter |
|---|---|
| `LSTMMemory` (h=256, m=128) | ~82 000 |
| `TransformerMemory` (h=256, m=128, seq=8, nhead=4, layers=2) | ~1 070 000 |

---

## Implementierung

### `training/lstm_policy.py`

```python
import torch
import torch.nn as nn

class LSTMMemory(nn.Module):
    def __init__(self, h_size, memory_size, num_layers=1):
        super().__init__()
        self.output_size = memory_size // 2
        self.lstm = nn.LSTM(
            input_size=h_size,
            hidden_size=self.output_size,
            num_layers=num_layers,
            batch_first=True,
        )

    def forward(self, x):
        # x: [batch, seq_len, h_size]
        output, _ = self.lstm(x)
        B, T, _ = output.shape
        return output.reshape(B * T, self.output_size)
```

### `config/labyrinth_lstm.yaml` (Kern)

```yaml
network_settings:
  hidden_units: 256
  num_layers: 2
  memory:
    sequence_length: 8
    memory_size: 128
    memory_type: lstm   # → LSTMMemory (nach Patch)
```

### Dateistruktur

```
KI_Agenten/
├── training/
│   ├── lstm_policy.py          # LSTMMemory-Modul (standalone + unit test)
│   ├── transformer_policy.py   # TransformerMemory-Modul
│   └── patch_mlagents.py       # Patch-Skript (beide Module)
├── config/
│   ├── labyrinth_lstm.yaml     # Training mit LSTMMemory
│   └── labyrinth_transformer.yaml
```

venv (nicht im Repo, per Skript anwenden):
```
torch_entities/
├── lstm_memory.py          # Kopie von lstm_policy.py
└── transformer_memory.py   # Kopie von transformer_policy.py
```

---

## Änderungen an `patch_mlagents.py`

Der Patch wurde um drei additive `elif`-Blöcke erweitert. Die Transformer-Pfade bleiben unverändert:

| Stelle | Änderung |
|---|---|
| Import | `from ... import LSTMMemory` angehängt |
| `NetworkBody.__init__` | `elif _mem_type == "lstm": self.lstm_memory = LSTMMemory(...)` zwischen Transformer-`if` und `else` |
| `NetworkBody.memory_size` | `elif getattr(self, 'lstm_memory', None) is not None: return self.m_size` angehängt |
| `NetworkBody.forward` | `elif getattr(self, 'lstm_memory', None) is not None: encoding = self.lstm_memory(encoding)` angehängt |
| `copy_module` / `remove_module` | kopieren/entfernen auch `lstm_memory.py` |

---

## Entscheidungen

**Warum kein Memory-Passing (h_0/c_0)?**

mlagents chunked den Replay-Buffer intern in Sequenzen der Länge `sequence_length` und übergibt diese als vollständige Batches ans Netz. Im Training steht die komplette Sequenz zur Verfügung — kein step-weises Übergeben von Hidden States nötig. Das ist identisch zur Vorgehensweise bei TransformerMemory.

**Warum `batch_first=True` (anders als TransformerMemory)?**

TransformerMemory nutzt `batch_first=False` als Workaround für einen PyTorch-2.0-ONNX-Bug bei `nn.MultiheadAttention`. Für `nn.LSTM` existiert dieser Bug nicht — `batch_first=True` vereinfacht den Code (kein Transpose nötig).

**Warum `num_layers=1`?**

Konsistent mit der mlagents Built-in LSTM-Tiefe. Ermöglicht einen fairen Vergleich zwischen Custom LSTM, Built-in LSTM und Transformer.

---

## Testergebnis (Unit-Test)

```
python training/lstm_policy.py
Unit-Test OK — output shape: torch.Size([32, 64])
Parameter gesamt: 82,432
```

---

## Ablationsplan

| Konfiguration | Sequenz | Status |
|---|---|---|
| Transformer V1 | 8 | trainiert (50k, Proof of Concept) |
| LSTM Baseline | 8 | Modul bereit, Volltraining (2M) offen |
| MLP Baseline | 1 | offen |
