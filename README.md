# KI_Agenten

## Transformer-Setup (einmalig pro Entwickler-Rechner)

Der Transformer läuft nicht out-of-the-box — mlagents 0.30.0 muss einmalig gepatcht werden.

**Voraussetzungen:** Python 3.10, PyTorch 2.0.1+cu118, venv unter `C:\Users\<Name>\mlagents-31008\`

### Schritte

1. Repo klonen / pullen
2. Venv aktivieren:
   ```
   C:\Users\<Name>\mlagents-31008\Scripts\activate
   ```
3. Patch anwenden:
   ```
   python training/patch_mlagents.py
   ```
4. Training starten:
   ```
   mlagents-learn config/labyrinth_transformer.yaml --run-id=transformer_v1
   ```
5. In Unity auf **Play** drücken

Zum Rückgängigmachen: `python training/patch_mlagents.py --undo`

Zum Vergleich mit LSTM: `config/labyrinth_lstm.yaml` verwenden (kein Patch nötig).

Details: `Dokumentation/Transformer_Integration.md`
