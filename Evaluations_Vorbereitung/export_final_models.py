# -*- coding: utf-8 -*-
"""ONNX-Export der finalen final_v3-Modelle (30M Steps) OHNE Unity-Verbindung.

Baut die Policies aus Config-Werten nach, lädt die finalen Checkpoints und
exportiert je Behavior eine .onnx nach Evaluations_Vorbereitung/onnx/.

Basiert auf export_onnx_standalone.py (milestone-7). Wichtig:
- torch.multinomial segfaultet beim ONNX-Export in PyTorch 2.0.1 → das
  Modell-Output-Sampling wird für den Export auf argmax (deterministisch)
  umgestellt. Für Evaluation ist das die übliche Wahl.
- MLP wird mit opset 10 exportiert (Barracuda-kompatibel). LSTM/Transformer
  brauchen wegen der Rolling-Buffer-Memories opset 17 + unflatten-Symbolic —
  diese Dateien sind für ONNX-Runtime/Netron gedacht, NICHT für Barracuda.

Aufruf:  <venv-python> Evaluations_Vorbereitung/export_final_models.py
         (aus dem Projekt-Root C:\\Users\\Finnl\\KI_Agenten)
"""
import os
import torch
from torch.onnx import register_custom_op_symbolic
from torch.onnx.symbolic_helper import parse_args
from mlagents_envs.base_env import (
    BehaviorSpec, ObservationSpec, ActionSpec, DimensionProperty, ObservationType,
)
from mlagents.trainers.settings import SerializationSettings, NetworkSettings
from mlagents.trainers.torch_entities.networks import SimpleActor
from mlagents.trainers.torch_entities.model_serialization import ModelSerializer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "Evaluations_Vorbereitung", "onnx")
RESULTS = os.path.join(ROOT, "results", "model_comparison_final_v3")
os.makedirs(OUT_DIR, exist_ok=True)


@parse_args("v", "i", "is")
def unflatten_symbolic(g, self, dim, sizes):
    self_shape = g.op("Shape", self)
    sizes_t = g.op("Constant", value_t=torch.tensor(list(sizes), dtype=torch.long))
    if dim == -1:
        before = g.op(
            "Slice", self_shape,
            g.op("Constant", value_t=torch.tensor([0], dtype=torch.long)),
            g.op("Constant", value_t=torch.tensor([-1], dtype=torch.long)),
            g.op("Constant", value_t=torch.tensor([0], dtype=torch.long)),
        )
        new_shape = g.op("Concat", before, sizes_t, axis_i=0)
    else:
        before = g.op(
            "Slice", self_shape,
            g.op("Constant", value_t=torch.tensor([0], dtype=torch.long)),
            g.op("Constant", value_t=torch.tensor([dim], dtype=torch.long)),
            g.op("Constant", value_t=torch.tensor([0], dtype=torch.long)),
        )
        after = g.op(
            "Slice", self_shape,
            g.op("Constant", value_t=torch.tensor([dim + 1], dtype=torch.long)),
            g.op("Constant", value_t=torch.tensor([9223372036854775807], dtype=torch.long)),
            g.op("Constant", value_t=torch.tensor([0], dtype=torch.long)),
        )
        new_shape = g.op("Concat", before, sizes_t, after, axis_i=0)
    return g.op("Reshape", self, new_shape)


def obs_specs():
    """Zwei Vektor-Observations, Größen aus den Checkpoint-Normalizern belegt."""
    return [
        ObservationSpec(shape=(176,), dimension_property=(DimensionProperty.UNSPECIFIED,),
                        observation_type=ObservationType.DEFAULT, name="ray_obs"),
        ObservationSpec(shape=(31,), dimension_property=(DimensionProperty.UNSPECIFIED,),
                        observation_type=ObservationType.DEFAULT, name="vector_obs"),
    ]


BEHAVIORS = {
    "MLP_Navigator": dict(
        ckpt="MLP_Navigator-30000089.pt", opset=10,
        settings=NetworkSettings(normalize=False, hidden_units=256, num_layers=2, memory=None),
    ),
    "LSTM_Navigator": dict(
        ckpt="LSTM_Navigator-30003930.pt", opset=17,
        settings=NetworkSettings(
            normalize=True, hidden_units=256, num_layers=2,
            memory=NetworkSettings.MemorySettings(
                sequence_length=16, memory_size=256, memory_type="lstm")),
    ),
    "Transformer_Navigator": dict(
        ckpt="Transformer_Navigator-30006822.pt", opset=17,
        settings=NetworkSettings(
            normalize=False, hidden_units=256, num_layers=2,
            memory=NetworkSettings.MemorySettings(
                sequence_length=16, memory_size=128, memory_type="transformer")),
    ),
}


class FakePolicy:
    def __init__(self, actor, behavior_spec):
        self.actor = actor
        self.behavior_spec = behavior_spec
        self.export_memory_size = actor.memory_size


def export_one(name, spec):
    print(f"\n=== {name} (opset {spec['opset']}) ===", flush=True)
    SerializationSettings.convert_to_onnx = True
    SerializationSettings.onnx_opset = spec["opset"]

    behavior_spec = BehaviorSpec(
        observation_specs=obs_specs(),
        action_spec=ActionSpec(continuous_size=0, discrete_branches=(3, 3, 3)),
    )
    actor = SimpleActor(
        observation_specs=behavior_spec.observation_specs,
        network_settings=spec["settings"],
        action_spec=behavior_spec.action_spec,
        conditional_sigma=False,
        tanh_squash=False,
    )
    ckpt = torch.load(os.path.join(RESULTS, name, spec["ckpt"]), map_location="cpu")
    missing, unexpected = actor.load_state_dict(ckpt["Policy"], strict=False)
    print(f"  state_dict geladen | missing={len(missing)} unexpected={len(unexpected)}", flush=True)
    if missing:
        print("  MISSING:", missing[:6], flush=True)
    if unexpected:
        print("  UNEXPECTED:", unexpected[:6], flush=True)
    actor.eval()

    serializer = ModelSerializer(FakePolicy(actor, behavior_spec))
    out = os.path.join(OUT_DIR, name)
    serializer.export_policy_model(out)
    size = os.path.getsize(out + ".onnx")
    print(f"  OK -> {out}.onnx ({size/1024/1024:.2f} MB)", flush=True)


def patch_and_register():
    # torch.multinomial segfaultet im ONNX-Export (torch 2.0.1) → argmax
    from mlagents.trainers.torch_entities.distributions import CategoricalDistInstance
    CategoricalDistInstance.exported_model_output = (
        lambda self: torch.argmax(self.probs, dim=1, keepdim=True)
    )
    for opset in (10, 11, 15, 17):
        try:
            register_custom_op_symbolic("aten::unflatten", unflatten_symbolic, opset)
        except Exception:
            pass


def main():
    """Orchestrator: je Behavior+Opset ein Subprozess — native Crashes
    (Segfaults im ONNX-Tracer) reißen so nur den Versuch, nicht alles."""
    import subprocess, sys
    opset_candidates = {
        "MLP_Navigator": [10, 11, 15, 17],
        "LSTM_Navigator": [17, 15],
        "Transformer_Navigator": [17],
    }
    results = {}
    for name in BEHAVIORS:
        results[name] = None
        for opset in opset_candidates[name]:
            print(f"\n>>> Versuch: {name} @ opset {opset}", flush=True)
            r = subprocess.run(
                [sys.executable, "-u", os.path.abspath(__file__), "one", name, str(opset)],
                cwd=ROOT, capture_output=True, text=True, timeout=300)
            print(r.stdout, flush=True)
            if r.returncode == 0 and os.path.exists(os.path.join(OUT_DIR, f"{name}.onnx")):
                results[name] = opset
                break
            print(f"    -> fehlgeschlagen (Exit {r.returncode})", flush=True)
            if r.stderr:
                tail = [l for l in r.stderr.splitlines() if l.strip()][-4:]
                for l in tail:
                    print("    stderr:", l, flush=True)
    print("\n===== Ergebnis =====", flush=True)
    for name, opset in results.items():
        print(f"  {name}: " + (f"OK (opset {opset})" if opset else "FEHLGESCHLAGEN"), flush=True)


if __name__ == "__main__":
    import sys
    if len(sys.argv) == 4 and sys.argv[1] == "one":
        name, opset = sys.argv[2], int(sys.argv[3])
        spec = dict(BEHAVIORS[name])
        spec["opset"] = opset
        patch_and_register()
        export_one(name, spec)
    else:
        main()
