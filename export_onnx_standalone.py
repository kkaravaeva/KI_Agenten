"""
Standalone ONNX-Export aus Checkpoint, OHNE Unity-Verbindung.
Konstruiert die Policy manuell aus den Specs im Checkpoint.
"""
import torch
from torch.onnx import register_custom_op_symbolic
from torch.onnx.symbolic_helper import parse_args
import numpy as np
from mlagents_envs.base_env import BehaviorSpec, ObservationSpec, ActionSpec, DimensionProperty, ObservationType
from mlagents.trainers.settings import (
    SerializationSettings,
    NetworkSettings,
)
from mlagents.trainers.torch_entities.networks import SimpleActor
from mlagents.trainers.torch_entities.model_serialization import ModelSerializer


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


def make_network_settings():
    mem = NetworkSettings.MemorySettings(
        sequence_length=16, memory_size=128, memory_type="transformer"
    )
    return NetworkSettings(
        normalize=False, hidden_units=256, num_layers=2, memory=mem
    )


def main():
    print("[1] start", flush=True)
    SerializationSettings.convert_to_onnx = True
    SerializationSettings.onnx_opset = 17
    register_custom_op_symbolic("aten::unflatten", unflatten_symbolic, 17)

    # Patch: torch.multinomial segfaults in PyTorch 2.0.1 ONNX export.
    # Use deterministic argmax sampling instead — same behavior as deterministic_sample.
    from mlagents.trainers.torch_entities.distributions import CategoricalDistInstance
    CategoricalDistInstance.exported_model_output = (
        lambda self: torch.argmax(self.probs, dim=1, keepdim=True)
    )
    print("[2] settings patched", flush=True)

    # BehaviorSpec aus den Checkpoint-Konstanten
    obs_spec = ObservationSpec(
        shape=(190,),
        dimension_property=(DimensionProperty.UNSPECIFIED,),
        observation_type=ObservationType.DEFAULT,
        name="vector_obs",
    )
    action_spec = ActionSpec(continuous_size=0, discrete_branches=(3, 3, 2))
    behavior_spec = BehaviorSpec(
        observation_specs=[obs_spec],
        action_spec=action_spec,
    )

    network_settings = make_network_settings()
    print("[3] network_settings built", flush=True)

    actor = SimpleActor(
        observation_specs=behavior_spec.observation_specs,
        network_settings=network_settings,
        action_spec=behavior_spec.action_spec,
        conditional_sigma=False,
        tanh_squash=False,
    )

    print("[4] actor built", flush=True)

    ckpt = torch.load("results/v14/manual_save/checkpoint.pt", map_location="cpu")
    print("[5] checkpoint loaded", flush=True)
    missing, unexpected = actor.load_state_dict(ckpt["Policy"], strict=False)
    print(f"Missing keys: {len(missing)} | Unexpected: {len(unexpected)}")
    if missing:
        print("  Missing:", missing[:5])
    if unexpected:
        print("  Unexpected:", unexpected[:5])

    actor.eval()

    # Fake-Policy-Wrapper damit ModelSerializer ihn benutzen kann
    class FakePolicy:
        def __init__(self, actor, behavior_spec):
            self.actor = actor
            self.behavior_spec = behavior_spec
            # actor.memory_size is the actual internal size (= 3840 for transformer)
            self.export_memory_size = actor.memory_size

    policy = FakePolicy(actor, behavior_spec)
    print("[6] policy wrapper built", flush=True)
    serializer = ModelSerializer(policy)
    print("[7] serializer built", flush=True)

    output_path = "results/v14/manual_save/LabyrinthNavigator_v14"
    print(f"[8] Exporting to {output_path}.onnx ...", flush=True)
    serializer.export_policy_model(output_path)

    import os
    size = os.path.getsize(output_path + ".onnx")
    print(f"SUCCESS! Size: {size:,} bytes ({size/1024/1024:.2f} MB)")


if __name__ == "__main__":
    main()
