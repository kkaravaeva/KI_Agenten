import torch
import torch.nn as nn


class LSTMMemory(nn.Module):
    """
    Custom LSTM als Ersatz für die mlagents-eigene LSTM-Implementierung.
    Analogon zu TransformerMemory — identische Ein-/Ausgabe-Shapes.

    Input:  [batch, seq_len, h_size]   z.B. [64, 8, 256]
    Output: [batch*seq_len, output_size]  z.B. [512, 64]  (= memory_size // 2)

    Architektur-Entscheidungen:
    - hidden_size = memory_size // 2: identisch zu mlagents LSTM-Konvention
    - num_layers=1: Standard; konsistent mit mlagents-eigener LSTM-Tiefe
    - batch_first=True: konsistentes Interface mit TransformerMemory
    - Alle Zeitschritte als Output: [B*T, output_size] — GAE-kompatibel wie TransformerMemory
    - h_0/c_0 nicht übergeben: Training verarbeitet vollständige Sequenzen (BPTT via mlagents),
      kein step-weises Memory-Passing nötig
    """

    def __init__(
        self,
        h_size: int,
        memory_size: int,
        num_layers: int = 1,
    ):
        super().__init__()
        self.output_size = memory_size // 2
        self.lstm = nn.LSTM(
            input_size=h_size,
            hidden_size=self.output_size,
            num_layers=num_layers,
            batch_first=True,
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [batch, seq_len, h_size]
        output, _ = self.lstm(x)
        # output: [batch, seq_len, output_size]
        B, T, _ = output.shape
        # [batch*seq_len, output_size] — identisch zu TransformerMemory-Output-Shape für GAE
        return output.reshape(B * T, self.output_size)


if __name__ == "__main__":
    # Unit-Test: hidden_units=256, memory_size=128, seq_len=8 — exakt wie in den YAMLs
    model = LSTMMemory(h_size=256, memory_size=128)
    dummy = torch.zeros(4, 8, 256)
    out = model(dummy)
    assert out.shape == (4 * 8, 64), f"Unerwartete Shape: {out.shape}"
    print(f"Unit-Test OK — output shape: {out.shape}")
    total = sum(p.numel() for p in model.parameters())
    print(f"Parameter gesamt: {total:,}")
