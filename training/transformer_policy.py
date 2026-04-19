import torch
import torch.nn as nn


class TransformerMemory(nn.Module):
    """
    Ersatz für LSTM in mlagents NetworkBody.
    Verarbeitet eine Sequenz MLP-kodierter Observations via Self-Attention.

    Input:  [batch, seq_len, h_size]   z.B. [64, 8, 256]
    Output: [batch, output_size]       z.B. [64, 64]  (= memory_size // 2)

    Architektur-Entscheidungen:
    - d_model = h_size (= hidden_units aus YAML): kein Extra-Embedding-Layer nötig,
      da der MLP-Encoder bereits auf h_size projiziert hat
    - nhead=4: teilt 256 gleichmäßig (256/4 = 64 dim pro Head)
    - num_layers=2: Balance zwischen Ausdrucksstärke und Trainingsgeschwindigkeit
    - Gelernte Positional Encoding (nn.Embedding) mit statischem Buffer: ONNX-Export-sicher
    - Manuelle Transformer-Layer statt nn.TransformerEncoder: vermeidet CUDA Fast-Path
      Segfaults (PyTorch 2.0 optimierte Kernel) und ist stabiler für mlagents-Export
    - Letzter Token als Output: repräsentiert aktuelle Entscheidung mit historischem Kontext
    """

    def __init__(
        self,
        h_size: int,
        memory_size: int,
        seq_len: int,
        nhead: int = 4,
        num_layers: int = 2,
    ):
        super().__init__()
        assert h_size % nhead == 0, (
            f"hidden_units ({h_size}) muss durch nhead ({nhead}) teilbar sein"
        )
        self.output_size = memory_size // 2

        self.pos_enc = nn.Embedding(seq_len, h_size)
        # Statischer Buffer statt torch.arange() im forward — ONNX-Export-sicher
        self.register_buffer("pos_indices", torch.arange(seq_len))

        # batch_first=False für ONNX-Kompatibilität (PyTorch 2.0 bug mit batch_first=True)
        self.attn_layers = nn.ModuleList([
            nn.MultiheadAttention(h_size, nhead, dropout=0.1, batch_first=False)
            for _ in range(num_layers)
        ])
        self.norms1 = nn.ModuleList([nn.LayerNorm(h_size) for _ in range(num_layers)])
        self.ffs = nn.ModuleList([
            nn.Sequential(
                nn.Linear(h_size, h_size * 2),
                nn.ReLU(),
                nn.Linear(h_size * 2, h_size),
            )
            for _ in range(num_layers)
        ])
        self.norms2 = nn.ModuleList([nn.LayerNorm(h_size) for _ in range(num_layers)])
        self.output_proj = nn.Linear(h_size, self.output_size)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [batch, seq_len, h_size]
        B, T, _ = x.shape
        x = x + self.pos_enc(self.pos_indices[:T])
        # MultiheadAttention erwartet [seq_len, batch, h_size] (batch_first=False)
        x = x.transpose(0, 1)
        for attn, norm1, ff, norm2 in zip(
            self.attn_layers, self.norms1, self.ffs, self.norms2
        ):
            attn_out, _ = attn(x, x, x)
            x = norm1(x + attn_out)
            x = norm2(x + ff(x))
        # Zurück zu [batch, seq_len, h_size], dann alle Positionen ausgeben
        # [batch*seq_len, output_size] — identisch zu LSTM-Output-Shape für GAE
        x = x.transpose(0, 1)
        return self.output_proj(x).reshape(B * T, self.output_size)


if __name__ == "__main__":
    # Unit-Test: hidden_units=256, memory_size=128, seq_len=8 — exakt wie in den YAMLs
    model = TransformerMemory(h_size=256, memory_size=128, seq_len=8)
    dummy = torch.zeros(4, 8, 256)
    out = model(dummy)
    assert out.shape == (4 * 8, 64), f"Unerwartete Shape: {out.shape}"  # batch*seq_len, output_size
    print(f"Unit-Test OK — output shape: {out.shape}")
    total = sum(p.numel() for p in model.parameters())
    print(f"Parameter gesamt: {total:,}")
