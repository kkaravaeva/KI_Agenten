import onnx

# Check the opset-18 model's LN attributes
print("=== Opset-18 source ===")
m18 = onnx.load(
    "V24_Paket/results/v24/LabyrinthNavigator/LabyrinthNavigator-30999993.onnx",
    load_external_data=True
)
for n in m18.graph.node:
    if n.op_type == "LayerNormalization":
        attrs = {}
        for a in n.attribute:
            if a.type == onnx.AttributeProto.FLOAT:
                attrs[a.name] = ("float", a.f)
            elif a.type == onnx.AttributeProto.INT:
                attrs[a.name] = ("int", a.i)
        print("  %s  attrs=%s" % (n.name, attrs))

# Check the expanded opset-11 model's ReduceMean axes
print("\n=== Opset-11 expanded ===")
m11 = onnx.load("Assets/ML-Agents/Models/Transformer_v24.onnx")
reduce_nodes = [(n.name, {a.name: list(a.ints) for a in n.attribute})
                for n in m11.graph.node if n.op_type == "ReduceMean"]
for name, attrs in reduce_nodes:
    print("  ReduceMean %s axes=%s" % (name, attrs.get("axes")))
