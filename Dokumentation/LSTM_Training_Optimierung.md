# LSTM Training – Optimierungsprotokoll

**Run:** `lstm_v2`  
**Architektur:** Custom `LSTMMemory` (h=256, hidden=64, seq_len=16)  
**Datum:** 2026-05-18

---

## 1. Ausgangslage

Vor diesem Run existierte `lstm_v1`, der sofort abgebrochen war (keine Steps aufgezeichnet).
Ursache: der Patch hatte `LSTMMemory` zwar instanziert, aber nie aufgerufen.

### Identifizierte Bugs vor `lstm_v2`

| # | Datei | Problem | Fix |
|---|---|---|---|
| 1 | `patch_mlagents.py` – `NETWORKS_FWD_NEW` | `self.lstm_memory` hatte keinen Branch in `forward()` — der `else`-Zweig rief `self.lstm` auf, das `None` war → Crash | `elif getattr(self, 'lstm_memory', None) is not None:` mit Rolling Buffer eingefügt |
| 2 | `patch_mlagents.py` – `NETWORKS_PROP_NEW` | `memory_size` gab 0 zurück für LSTM → Trainer allokierte keinen Memory-Buffer | `elif lstm_memory → (seq_len-1) * h_size` eingefügt |
| 3 | `lstm_policy.py` | `seq_len` nicht gespeichert → kein `self.seq_len` für Rolling Buffer | `seq_len`-Parameter und `self.seq_len` hinzugefügt |
| 4 | `torch_policy.py` – `_export_m_size` | ONNX-Export nutzte `m_size=128` (YAML) statt `actor.memory_size=3840` → Reshape-Crash beim Checkpoint-Save | `if self.m_size != self._export_m_size: self._export_m_size = self.m_size` ergänzt |

---

## 2. Konfigurationsänderungen gegenüber Vorgänger-Runs

| Parameter | Vorher (`lstm_v1`-Config) | Neu (`lstm_v2`) | Begründung |
|---|---|---|---|
| `normalize` | `false` | `true` | Stabilisiert Encoder bei wechselnden Kartengrößen im Curriculum |
| `batch_size` | `1024` | `512` | Passt zu 1 Umgebung; kleinere Batches = häufigere Updates |
| `buffer_size` | `81920` | `40960` | Abgestimmt auf Single-Env-Setup |
| `beta` | `1.0e-3` | `2.0e-3` | Mehr Exploration zu Beginn |
| `gamma` | `0.997` | `0.995` | Etwas weniger Discount, schnelleres Lernen für kürzere Episoden |
| `max_steps` | `60M` | `10M` | Realistisch bei ~280 Steps/Sek mit Unity Editor |
| `summary_freq` | `20000` | `50000` | Weniger I/O-Overhead |

---

## 3. Trainingsverlauf (TensorBoard-Daten)

### 3.1 Session 1 — Erststart (Steps 0–350k)

| Step | Cum. Reward | Success Rate | Ep. Length | Entropy | Value Loss | Curriculum Phase |
|---:|---:|---:|---:|---:|---:|---:|
| 50k | -1.93 | 20.7% | 103 | 2.89 | 8.91 | 0.0 |
| 100k | +2.96 | 33.6% | 96 | 2.87 | 10.05 | 0.0 |
| 150k | -2.58 | 19.9% | 107 | 2.85 | 14.83 | 0.63 |
| 200k | -10.30 | 0.7% | 119 | 2.84 | 3.33 | 1.0 |
| 250k | -10.01 | 1.4% | 119 | 2.82 | 2.99 | 1.0 |
| 300k | -9.06 | 3.8% | 118 | 2.78 | 3.48 | 1.0 |
| 350k | -5.42 | 12.9% | 116 | 2.70 | 5.40 | 1.4 |

**Interpretation:**
- Bis 100k: Agent lernt auf Phase 0 (Trivial), erste Erfolge (33.6% Success)
- ~150k: **Phasenwechsel auf Phase 1** (Easy) — sofortiger Einbruch auf 0.7% Success, Reward −10
- Ab 300k: langsame Erholung, Agent beginnt Phase 1 zu meistern
- Entropy fällt langsam: Agent wird zunehmend deterministischer

**Abbruch bei 350k** wegen Unity-Timeout.

---

### 3.2 Session 2 — Resume (Steps 400k–650k)

| Step | Cum. Reward | Success Rate | Ep. Length | Entropy | Value Loss | Curriculum Phase |
|---:|---:|---:|---:|---:|---:|---:|
| 400k | +29.93 | 55.6% | 15 | 2.15 | — | 0.0 |
| 450k | +26.70 | 92.2% | 36 | 2.25 | 20.28 | 0.14 |
| 500k | +6.32 | 41.8% | 100 | 2.35 | 9.47 | 1.0 |
| 550k | +8.48 | 47.3% | 95 | 2.21 | 9.28 | 1.0 |
| 600k | +9.94 | 51.1% | 92 | 2.11 | 9.21 | 1.0 |
| 650k | +11.20 | 54.1% | 92 | 2.01 | 8.49 | 1.9 |

**Interpretation:**
- 400k–450k: **Anomalie** direkt nach Resume — sehr kurze Episoden (Ø 15–36 Steps), extrem hohe Success Rate (92%) und Reward. Der Agent hat Zustand aus dem Checkpoint geladen und trifft zunächst fast immer das Ziel. Vermutlich Phase 0 (Trivial) zu Beginn der neuen Session.
- Ab 500k: **Phasenwechsel auf Phase 1** — Episodenlänge springt auf 100, Success fällt auf 42%, Reward auf +6.
- 500k–650k: **stabiler Aufwärtstrend** — Reward +6→+11, Success 42%→54%, Episodenlänge sinkt leicht (Agent wird effizienter)
- Entropy fällt 2.35→2.01: Agent lernt konsistentere Strategie
- Value Loss stabilisiert sich bei ~8–9 (Critic lernt noch, Reward-Signal ist variabel)

---

## 4. Gesamtbewertung bei 650k Steps

| Metrik | Wert | Einschätzung |
|---|---|---|
| Success Rate | 54.1% | Gut für <1M Steps auf Phase 1 |
| Mean Reward | +11.2 | Positiv, steigend |
| Episode Length | 91.8 Steps | Agent findet Ziel in ~1/3 der max. Zeit |
| Entropy | 2.01 | Lernt, aber noch explorativ |
| Curriculum Phase | ~1.9 | Kurz vor Übergang zu Phase 2 |

---

## 5. Trainingsgeschwindigkeit

| Messung | Steps/Sekunde |
|---|---|
| Session 1 (Ø) | ~290 |
| Session 2 (Ø) | ~270 |
| **Gesamt** | **~280** |

Bei 280 Steps/Sek und `max_steps=10M`:
- **Geschätzte Restlaufzeit:** ~9 Stunden (ab Step 650k)

---

## 6. Offene Maßnahmen

- [ ] Standalone Build erstellen → 3–5× schneller
- [ ] Reward-Funktion: `lavaDeathPenalty` −1.0 → −3.0, `goalReward` 5.0 → 10.0 (v6-Plan)
- [ ] Run bis 10M Steps durchlaufen lassen
- [ ] Vergleich mit Transformer-Run auf identischer Konfiguration
