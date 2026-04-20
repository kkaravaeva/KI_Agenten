"""
Patcht mlagents 0.30.0 Venv für Transformer-Support (Option A).

Was dieser Patch tut:
1. Kopiert transformer_policy.py als transformer_memory.py in die Venv
2. settings.py: fügt memory_type-Feld zu MemorySettings hinzu
3. networks.py: fügt Transformer-Branch in NetworkBody ein (neben LSTM)

Ausführen (einmalig, vor dem ersten Transformer-Training):
    python training/patch_mlagents.py

Rückgängig machen:
    python training/patch_mlagents.py --undo
"""
import shutil
import sys
from pathlib import Path

_venv_arg = next((a for a in sys.argv[1:] if not a.startswith("--")), None)
if _venv_arg:
    VENV = Path(_venv_arg)
else:
    # Fallback: automatisch per `pip show mlagents` ermitteln
    import subprocess, site
    try:
        _sp = subprocess.check_output([sys.executable, "-m", "pip", "show", "mlagents"],
                                      text=True, stderr=subprocess.DEVNULL)
        _loc = next(l.split(":", 1)[1].strip() for l in _sp.splitlines() if l.startswith("Location:"))
        VENV = Path(_loc).parents[2]  # site-packages -> Lib -> venv-root
    except Exception:
        VENV = Path(r"C:\Users\Finnl\mlagents-31008")

TORCH_ENTITIES = VENV / "Lib/site-packages/mlagents/trainers/torch_entities"
SETTINGS_FILE  = VENV / "Lib/site-packages/mlagents/trainers/settings.py"
NETWORKS_FILE  = TORCH_ENTITIES / "networks.py"
REPO_ROOT      = Path(__file__).parent.parent


# ── Hilfsfunktion ─────────────────────────────────────────────────────────────

def _replace_once(text: str, old: str, new: str, label: str) -> str:
    assert old in text, f"Patch-Marker nicht gefunden in {label}:\n{old!r}"
    assert text.count(old) == 1, f"Marker kommt mehrfach vor in {label} — Patch unsicher"
    return text.replace(old, new, 1)


# ── Patch: settings.py ────────────────────────────────────────────────────────

SETTINGS_MARKER = '        memory_size: int = attr.ib(default=128)'
SETTINGS_PATCH  = (
    '        memory_size: int = attr.ib(default=128)\n'
    '        memory_type: str = attr.ib(default="lstm")  # "lstm" or "transformer"'
)

def patch_settings():
    text = SETTINGS_FILE.read_text(encoding="utf-8")
    if "memory_type" in text:
        print("settings.py: memory_type bereits vorhanden — überspringe.")
        return
    text = _replace_once(text, SETTINGS_MARKER, SETTINGS_PATCH, "settings.py")
    SETTINGS_FILE.write_text(text, encoding="utf-8")
    print("settings.py OK  memory_type hinzugefügt.")

def undo_settings():
    text = SETTINGS_FILE.read_text(encoding="utf-8")
    if "memory_type" not in text:
        print("settings.py: kein Patch gefunden — überspringe.")
        return
    text = text.replace(SETTINGS_PATCH, SETTINGS_MARKER, 1)
    SETTINGS_FILE.write_text(text, encoding="utf-8")
    print("settings.py OK  memory_type entfernt.")


# ── Patch: networks.py ────────────────────────────────────────────────────────

NETWORKS_IMPORT_OLD = (
    "from mlagents.trainers.torch_entities.layers import LSTM, LinearEncoder"
)
NETWORKS_IMPORT_NEW = (
    "from mlagents.trainers.torch_entities.layers import LSTM, LinearEncoder\n"
    "from mlagents.trainers.torch_entities.transformer_memory import TransformerMemory"
)

# Unique context: NetworkBody.__init__ ends with update_normalization (MultiAgent has copy_normalization)
NETWORKS_INIT_OLD = (
    "        if self.use_lstm:\n"
    "            self.lstm = LSTM(self.h_size, self.m_size)\n"
    "        else:\n"
    "            self.lstm = None  # type: ignore\n"
    "\n"
    "    def update_normalization(self, buffer: AgentBuffer) -> None:"
)
NETWORKS_INIT_NEW = (
    "        if self.use_lstm:\n"
    "            _mem_type = network_settings.memory.memory_type\n"
    "            if _mem_type == \"transformer\":\n"
    "                self.lstm = None  # type: ignore\n"
    "                self.transformer_memory: TransformerMemory = TransformerMemory(\n"
    "                    h_size=self.h_size,\n"
    "                    memory_size=self.m_size,\n"
    "                    seq_len=network_settings.memory.sequence_length,\n"
    "                )\n"
    "            else:\n"
    "                self.lstm = LSTM(self.h_size, self.m_size)\n"
    "                self.transformer_memory = None  # type: ignore\n"
    "        else:\n"
    "            self.lstm = None  # type: ignore\n"
    "            self.transformer_memory = None  # type: ignore\n"
    "\n"
    "    def update_normalization(self, buffer: AgentBuffer) -> None:"
)

# Unique context: NetworkBody.memory_size is followed by forward(); MultiAgent has update_normalization
NETWORKS_PROP_OLD = (
    "    def copy_normalization(self, other_network: \"NetworkBody\") -> None:\n"
    "        self.observation_encoder.copy_normalization(other_network.observation_encoder)\n"
    "\n"
    "    @property\n"
    "    def memory_size(self) -> int:\n"
    "        return self.lstm.memory_size if self.use_lstm else 0\n"
    "\n"
    "    def forward("
)
NETWORKS_PROP_NEW = (
    "    def copy_normalization(self, other_network: \"NetworkBody\") -> None:\n"
    "        self.observation_encoder.copy_normalization(other_network.observation_encoder)\n"
    "\n"
    "    @property\n"
    "    def memory_size(self) -> int:\n"
    "        if self.lstm is not None:\n"
    "            return self.lstm.memory_size\n"
    "        elif getattr(self, 'transformer_memory', None) is not None:\n"
    "            return self.m_size\n"
    "        return 0\n"
    "\n"
    "    def forward("
)

# Unique context: NetworkBody.forward() returns immediately after LSTM block (no torch.cat)
NETWORKS_FWD_OLD = (
    "        if self.use_lstm:\n"
    "            # Resize to (batch, sequence length, encoding size)\n"
    "            encoding = encoding.reshape([-1, sequence_length, self.h_size])\n"
    "            encoding, memories = self.lstm(encoding, memories)\n"
    "            encoding = encoding.reshape([-1, self.m_size // 2])\n"
    "        return encoding, memories\n"
    "\n"
    "\n"
    "class MultiAgentNetworkBody"
)
NETWORKS_FWD_NEW = (
    "        if self.use_lstm:\n"
    "            encoding = encoding.reshape([-1, sequence_length, self.h_size])\n"
    "            if getattr(self, 'transformer_memory', None) is not None:\n"
    "                encoding = self.transformer_memory(encoding)\n"
    "            else:\n"
    "                encoding, memories = self.lstm(encoding, memories)\n"
    "                encoding = encoding.reshape([-1, self.m_size // 2])\n"
    "        return encoding, memories\n"
    "\n"
    "\n"
    "class MultiAgentNetworkBody"
)

def patch_networks():
    text = NETWORKS_FILE.read_text(encoding="utf-8")
    if "TransformerMemory" in text:
        print("networks.py: Transformer-Branch bereits vorhanden — überspringe.")
        return
    text = _replace_once(text, NETWORKS_IMPORT_OLD, NETWORKS_IMPORT_NEW, "networks.py (import)")
    text = _replace_once(text, NETWORKS_INIT_OLD,   NETWORKS_INIT_NEW,   "networks.py (__init__)")
    text = _replace_once(text, NETWORKS_PROP_OLD,   NETWORKS_PROP_NEW,   "networks.py (property)")
    text = _replace_once(text, NETWORKS_FWD_OLD,    NETWORKS_FWD_NEW,    "networks.py (forward)")
    NETWORKS_FILE.write_text(text, encoding="utf-8")
    print("networks.py OK  Transformer-Branch eingefügt.")

def undo_networks():
    text = NETWORKS_FILE.read_text(encoding="utf-8")
    if "TransformerMemory" not in text:
        print("networks.py: kein Patch gefunden — überspringe.")
        return
    text = text.replace(NETWORKS_IMPORT_NEW, NETWORKS_IMPORT_OLD, 1)
    text = text.replace(NETWORKS_INIT_NEW,   NETWORKS_INIT_OLD,   1)
    text = text.replace(NETWORKS_PROP_NEW,   NETWORKS_PROP_OLD,   1)
    text = text.replace(NETWORKS_FWD_NEW,    NETWORKS_FWD_OLD,    1)
    NETWORKS_FILE.write_text(text, encoding="utf-8")
    print("networks.py OK  Patch rückgängig gemacht.")


# ── Modul kopieren ─────────────────────────────────────────────────────────────

def copy_module():
    src = REPO_ROOT / "training" / "transformer_policy.py"
    dst = TORCH_ENTITIES / "transformer_memory.py"
    assert src.exists(), f"Quelldatei nicht gefunden: {src}"
    shutil.copy(src, dst)
    print(f"transformer_memory.py OK  -> {dst}")

def remove_module():
    dst = TORCH_ENTITIES / "transformer_memory.py"
    if dst.exists():
        dst.unlink()
        print(f"transformer_memory.py OK  entfernt.")
    else:
        print("transformer_memory.py: nicht vorhanden — überspringe.")


# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    undo = "--undo" in sys.argv[1:]

    if undo:
        print("=== Patch rückgängig machen ===")
        remove_module()
        undo_settings()
        undo_networks()
        print("\nUndo abgeschlossen.")
    else:
        print("=== mlagents 0.30.0 Transformer-Patch ===")
        copy_module()
        patch_settings()
        patch_networks()
        print("\nPatch abgeschlossen.")
        print("Teste jetzt mit: python training/transformer_policy.py")
