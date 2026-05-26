import onnx
model = onnx.load("Assets/ML-Agents/Models/Transformer_v24.onnx")
for n in model.graph.node:
    if n.op_type == "LayerNormalization":
        attrs = {a.name: (a.i if a.type == 1 else a.f) for a in n.attribute}
        print("LN inputs=%s outputs=%s attrs=%s" % (list(n.input), list(n.output), attrs))
print("Total LN nodes:", sum(1 for n in model.graph.node if n.op_type == "LayerNormalization"))
