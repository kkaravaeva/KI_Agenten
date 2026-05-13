"""
ONNX-Export für ML-Agents Transformer-Memory-Modelle.

Drei Patches sind nötig wegen Bugs/Limitierungen in ML-Agents 0.30 + PyTorch 2.0.1:

1) SerializationSettings.convert_to_onnx = True
   ONNX-Export ist standardmaessig deaktiviert in dieser ML-Agents-Version.

2) TorchPolicy.export_memory_size -> actor.memory_size
   Bug in torch_policy.py: _export_m_size wird VOR dem Transformer-Resize gespeichert.
   Dadurch hat das ONNX-Dummy-Tensor Shape [1,1,128] statt [1,1,3840] (=(seq_len-1)*h_size).

3) Custom symbolic fuer aten::unflatten
   PyTorch 2.0.1's nn.MultiheadAttention nutzt unflatten() intern fuer Q/K/V-Splitting,
   aber der ONNX-Exporter dieser PyTorch-Version unterstuetzt unflatten nicht. Wir registrieren
   eine eigene Symbolic, die unflatten ueber Shape/Slice/Concat/Reshape rekonstruiert.

4) opset_version = 17
   Default ist 10 (zu alt fuer Transformer-Ops).
"""
import sys
import torch
from torch.onnx import register_custom_op_symbolic
from torch.onnx.symbolic_helper import parse_args
from mlagents.trainers.settings import SerializationSettings
from mlagents.trainers.policy.torch_policy import TorchPolicy


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


def run():
    SerializationSettings.convert_to_onnx = True
    SerializationSettings.onnx_opset = 17
    TorchPolicy.export_memory_size = property(lambda self: self.actor.memory_size)
    register_custom_op_symbolic("aten::unflatten", unflatten_symbolic, 17)

    sys.argv = [
        "mlagents-learn",
        "config/labyrinth_transformer_export.yaml",
        "--run-id=v14_onnx_export",
        "--initialize-from=v14",
        "--env=Builds/KI Agenten.exe",
        "--num-envs=1",
        "--no-graphics",
        "--force",
    ]
    from mlagents.trainers.learn import main
    main()


if __name__ == "__main__":
    run()
