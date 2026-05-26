"""
Patcht ein ML-Agents ONNX-Modell (Rolling-Buffer LSTM/Transformer), sodass
Barracuda 2.0.0 mit beliebig vielen gleichzeitigen Agenten funktioniert.

Problem:
  Barracuda 2.0.0 führt constant-folding auf Shape→Gather→Concat Ketten aus,
  indem es die statischen Typinfos (value_info) verwendet. Da die intermediären
  Tensoren alle mit batch=1 annotiert sind (torch.jit.trace), berechnet Barracuda
  die Reshape-Targets zur Ladezeit statt zur Laufzeit → immer [1, 15, 256] statt
  [N, 15, 256].

Fix:
  Jede dynamische Concat-basierte Reshape-Shape durch einen expliziten Konstant-
  Tensor mit -1 als Batch-Dim ersetzen. Das ist eine native ONNX-Reshape-Funktion
  und wird von Barracuda korrekt ausgewertet.

Verwendung:
  python training/fix_onnx_batch.py Assets/ML-Agents/Models/lstm_curiosity.onnx
  # schreibt lstm_curiosity_fixed.onnx daneben
"""

import sys
import numpy as np
import onnx
from onnx import numpy_helper, helper, TensorProto
from pathlib import Path


def _collect_nodes(graph):
    node_by_output = {}
    for node in graph.node:
        for out in node.output:
            node_by_output[out] = node
    return node_by_output


def _get_constant_value(name, node_by_output, init_by_name):
    """Gibt den numpy-Wert zurück wenn 'name' eine Konstante ist, sonst None."""
    if name in init_by_name:
        return numpy_helper.to_array(init_by_name[name])
    if name in node_by_output:
        node = node_by_output[name]
        if node.op_type == "Constant":
            for attr in node.attribute:
                if attr.name == "value":
                    return numpy_helper.to_array(attr.t)
    return None


def _is_dynamic_batch_concat(shape_input_name, node_by_output, init_by_name):
    """
    Prüft ob shape_input_name von einem Concat-Node kommt, dessen erstes Element
    eine dynamische Batch-Dim ist (Shape→Gather→Unsqueeze oder Mul→Unsqueeze).
    Gibt (True, [dim1, dim2, ...]) zurück wenn ja, wobei die dims die restlichen
    statischen Werte sind.
    """
    if shape_input_name not in node_by_output:
        return False, []
    concat_node = node_by_output[shape_input_name]
    if concat_node.op_type != "Concat":
        return False, []

    # Erstes Concat-Input muss ein Unsqueeze sein (der die dynamische Batch-Dim einwickelt)
    if not concat_node.input:
        return False, []
    first_input = concat_node.input[0]
    if first_input not in node_by_output:
        return False, []
    first_node = node_by_output[first_input]
    if first_node.op_type != "Unsqueeze":
        return False, []

    # Stelle sicher, dass die Unsqueeze-Quelle dynamisch ist
    # (entweder Gather(Shape, 0) oder Mul(Gather, Gather))
    unsqueeze_src = first_node.input[0]
    if unsqueeze_src not in node_by_output:
        return False, []
    src_node = node_by_output[unsqueeze_src]
    if src_node.op_type not in ("Gather", "Mul"):
        return False, []

    # Restliche Concat-Inputs müssen Konstanten sein
    static_dims = []
    for inp in concat_node.input[1:]:
        val = _get_constant_value(inp, node_by_output, init_by_name)
        if val is None:
            return False, []
        static_dims.extend(val.flatten().tolist())

    return True, [int(d) for d in static_dims]


def fix_batch_dim(model_path: str) -> str:
    src = Path(model_path)
    dst = src.with_stem(src.stem + "_fixed")

    model = onnx.load(str(src))
    graph = model.graph

    init_by_name = {i.name: i for i in graph.initializer}
    node_by_output = _collect_nodes(graph)

    new_nodes = []   # neue Constant-Nodes die wir einfügen
    # Liste von (reshape_node_index, new_const_output_name)
    rewire_list = []

    for idx, node in enumerate(graph.node):
        if node.op_type != "Reshape":
            continue
        if len(node.input) < 2:
            continue

        shape_input = node.input[1]
        is_dynamic, static_dims = _is_dynamic_batch_concat(
            shape_input, node_by_output, init_by_name
        )
        if not is_dynamic:
            continue

        new_shape = np.array([-1] + static_dims, dtype=np.int64)
        const_name = f"__fixed_shape_{node.name.replace('/', '_')}"
        const_node = helper.make_node(
            "Constant",
            inputs=[],
            outputs=[const_name],
            value=numpy_helper.from_array(new_shape, name=const_name),
        )
        new_nodes.append(const_node)
        rewire_list.append((idx, const_name))

        print(f"  {node.name}: [{', '.join(str(d) for d in [1] + static_dims)}] -> {new_shape.tolist()}")

    if not rewire_list:
        print("Keine passenden Reshape-Nodes gefunden.")
        print("Das Modell verwendet entweder keine dynamische Shape-Berechnung")
        print("oder ist bereits korrekt. Versuche direktes Reshape-Initializer-Patching...")
        return _fallback_patch(src, dst, graph, init_by_name, node_by_output)

    # Constant-Nodes an den Anfang des Graphen einfügen
    for cn in new_nodes:
        graph.node.insert(0, cn)

    # Reshape-Nodes umverdrahten (Index verschoben durch die eingefügten Nodes)
    offset = len(new_nodes)
    for orig_idx, new_const_out in rewire_list:
        graph.node[orig_idx + offset].input[1] = new_const_out

    print(f"\n{len(rewire_list)} Reshape-Node(s) gepatcht.")

    try:
        onnx.checker.check_model(model)
        print("ONNX-Validierung OK.")
    except onnx.checker.ValidationError as e:
        print(f"Validierungswarnung: {e}")

    onnx.save(model, str(dst))
    print(f"Gespeichert: {dst}")
    return str(dst)


def _fallback_patch(src, dst, graph, init_by_name, node_by_output):
    """Fallback: Initializer-Konstanten mit Batch=1 direkt auf -1 setzen."""
    patched = 0
    for node in graph.node:
        if node.op_type != "Reshape" or len(node.input) < 2:
            continue
        shape_name = node.input[1]
        if shape_name not in init_by_name:
            continue
        init = init_by_name[shape_name]
        arr = numpy_helper.to_array(init).copy()
        if arr.ndim == 1 and len(arr) >= 2 and arr[0] == 1:
            print(f"  Fallback-Patch: {arr.tolist()} → ", end="")
            arr[0] = -1
            print(arr.tolist())
            new_init = numpy_helper.from_array(arr, name=shape_name)
            graph.initializer.remove(init)
            graph.initializer.append(new_init)
            patched += 1

    if patched == 0:
        print("Auch Fallback-Patch hat nichts gefunden. Modell ist möglicherweise kompatibel.")
        return str(src)

    model = onnx.load(str(src))  # reload to avoid graph mutation issues
    onnx.save(model, str(dst))
    print(f"Gespeichert: {dst}")
    return str(dst)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Verwendung: python fix_onnx_batch.py <modell.onnx>")
        sys.exit(1)
    fix_batch_dim(sys.argv[1])
