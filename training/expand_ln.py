"""
Convert opset-17 ONNX to opset-9 so Barracuda 2.0.0 can load it.
Steps:
  1. Expand LayerNormalization -> primitive ops (ReduceMean, Sub, Mul, Div, Sqrt, Add)
  2. Fix Squeeze / Unsqueeze: move axes from input-1 to attribute (opset 9 style)
"""
import os
import onnx
from onnx import helper, numpy_helper, shape_inference
import numpy as np

SRC = "V24_Paket/results/v24/LabyrinthNavigator/LabyrinthNavigator-30999993.onnx"  # dynamo opset-18 with external data
DST = "Assets/ML-Agents/Models/Transformer_v24.onnx"


# ---------- helpers -----------------------------------------------------------

def get_attr(node, name, attr_type, default):
    for a in node.attribute:
        if a.name != name:
            continue
        return a.i if attr_type == "int" else a.f
    return default


def get_rank(shape_map, tensor_name):
    vi = shape_map.get(tensor_name)
    if vi is None:
        return None
    ts = vi.type.tensor_type
    if ts.HasField("shape"):
        return len(ts.shape.dim)
    return None


def build_init_map(model):
    """Return dict name -> numpy array for every initializer."""
    result = {}
    for init in model.graph.initializer:
        result[init.name] = numpy_helper.to_array(init)
    return result


# ---------- passes -----------------------------------------------------------

def expand_layer_norm(model, shape_map):
    new_nodes = []
    new_inits = []
    ln_count = 0

    for node in model.graph.node:
        if node.op_type != "LayerNormalization":
            new_nodes.append(node)
            continue

        axis    = get_attr(node, "axis",    "int",   -1)
        epsilon = get_attr(node, "epsilon", "float",  1e-5)
        if epsilon == 0.0:
            epsilon = 1e-5

        x_name     = node.input[0]
        scale_name = node.input[1]
        bias_name  = node.input[2] if len(node.input) > 2 else None
        y_name     = node.output[0]

        rank = get_rank(shape_map, x_name) or 3
        axis_abs  = (rank + axis) if axis < 0 else axis
        norm_axes = list(range(axis_abs, rank))

        p = "ln%d_" % ln_count
        ln_count += 1

        mean_out = p + "mean"
        new_nodes.append(helper.make_node("ReduceMean", [x_name], [mean_out],
                                          axes=norm_axes, keepdims=1))
        diff_out = p + "diff"
        new_nodes.append(helper.make_node("Sub", [x_name, mean_out], [diff_out]))
        sq_out = p + "sq"
        new_nodes.append(helper.make_node("Mul", [diff_out, diff_out], [sq_out]))
        var_out = p + "var"
        new_nodes.append(helper.make_node("ReduceMean", [sq_out], [var_out],
                                          axes=norm_axes, keepdims=1))
        eps_name = p + "eps"
        new_inits.append(numpy_helper.from_array(
            np.array(epsilon, dtype=np.float32), eps_name))
        var_eps = p + "var_eps"
        new_nodes.append(helper.make_node("Add", [var_out, eps_name], [var_eps]))
        std_out = p + "std"
        new_nodes.append(helper.make_node("Sqrt", [var_eps], [std_out]))
        norm_out = p + "norm"
        new_nodes.append(helper.make_node("Div", [diff_out, std_out], [norm_out]))
        scaled_out = p + "scaled"
        new_nodes.append(helper.make_node("Mul", [norm_out, scale_name], [scaled_out]))
        if bias_name:
            new_nodes.append(helper.make_node("Add", [scaled_out, bias_name], [y_name]))
        else:
            new_nodes.append(helper.make_node("Identity", [scaled_out], [y_name]))

    del model.graph.node[:]
    model.graph.node.extend(new_nodes)
    model.graph.initializer.extend(new_inits)
    return model, ln_count


def strip_opset_newer_attrs(model):
    """Remove attributes that were added in opsets > 11 and are not in opset-11 schema."""
    removals = {
        "Reshape":  {"allowzero"},        # added opset 14
        "ArgMax":   {"select_last_index"}, # added opset 12
        "ArgMin":   {"select_last_index"}, # added opset 12
    }
    fixed = 0
    for node in model.graph.node:
        to_remove = removals.get(node.op_type, set())
        if not to_remove:
            continue
        attrs_to_keep = [a for a in node.attribute if a.name not in to_remove]
        if len(attrs_to_keep) < len(node.attribute):
            del node.attribute[:]
            node.attribute.extend(attrs_to_keep)
            fixed += 1
    return model, fixed




def fix_squeeze_unsqueeze(model, init_map):
    """Convert opset-13 Squeeze/Unsqueeze (axes as input) to opset-9 (axes as attr)."""
    new_nodes = []
    fixed = 0

    for node in model.graph.node:
        if node.op_type not in ("Squeeze", "Unsqueeze"):
            new_nodes.append(node)
            continue

        # opset-9 style already: single input, axes attribute
        if len(node.input) == 1:
            new_nodes.append(node)
            continue

        # opset-13 style: second input is the axes tensor
        data_input = node.input[0]
        axes_input = node.input[1] if len(node.input) > 1 else None

        if axes_input and axes_input in init_map:
            axes = init_map[axes_input].flatten().tolist()
            axes = [int(a) for a in axes]
            new_node = helper.make_node(node.op_type, [data_input], list(node.output),
                                        axes=axes)
            new_nodes.append(new_node)
            fixed += 1
        else:
            # axes not found as constant – keep as-is and hope for the best
            new_nodes.append(node)

    del model.graph.node[:]
    model.graph.node.extend(new_nodes)
    return model, fixed


# ---------- main -------------------------------------------------------------

print("Loading", SRC)
model = onnx.load(SRC, load_external_data=True)
print("Opset %d, %d nodes" % (model.opset_import[0].version, len(model.graph.node)))

try:
    model = shape_inference.infer_shapes(model)
except Exception as e:
    print("Shape inference warning:", e)

shape_map = {vi.name: vi
             for vi in list(model.graph.value_info)
                       + list(model.graph.input)
                       + list(model.graph.output)}

init_map = build_init_map(model)

# 1. Expand LayerNorm
model, ln_expanded = expand_layer_norm(model, shape_map)
print("Expanded %d LayerNorm nodes" % ln_expanded)

# 2. Strip opset-12+ attributes (allowzero, select_last_index, etc.)
model, attr_fixed = strip_opset_newer_attrs(model)
print("Stripped newer-opset attributes from %d nodes" % attr_fixed)

# 3. Fix Squeeze / Unsqueeze
model, sq_fixed = fix_squeeze_unsqueeze(model, init_map)
print("Fixed %d Squeeze/Unsqueeze nodes" % sq_fixed)

# Set opset to 11 (Slice with dynamic inputs valid since opset 10)
del model.opset_import[:]
model.opset_import.append(helper.make_opsetid("", 11))

# Validate
try:
    onnx.checker.check_model(model)
    print("Model check PASSED")
except Exception as e:
    print("Model check WARNING:", e)

onnx.save(model, DST, save_as_external_data=False)
sz = os.path.getsize(DST)
print("Saved -> %s  (%s bytes)" % (DST, f"{sz:,}"))
print("Opset of saved model:", onnx.load(DST).opset_import[0].version)
print("Done.")
