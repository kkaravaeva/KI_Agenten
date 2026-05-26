"""
Convert the opset-18 ONNX (dynamo exporter) to a lower opset
so that Barracuda 2.0.0 can load it.
Barracuda 2.0.0 supports opset 9–11.
"""
import os, sys
import onnx
from onnx import version_converter

MODEL_DIR = r"V24_Paket/results/v24/LabyrinthNavigator"
SRC = os.path.join(MODEL_DIR, "LabyrinthNavigator-30999993.onnx")
DST = r"Assets/ML-Agents/Models/Transformer_v24.onnx"

print(f"Loading {SRC} ...")
model = onnx.load(SRC, load_external_data=True)
src_opset = model.opset_import[0].version
print(f"Source opset: {src_opset}")

# Print the set of op types so we know what we're dealing with
op_types = sorted({n.op_type for n in model.graph.node})
print(f"Op types used: {op_types}")

# Try to convert down, stepping from 11 up to 17 until one works
for target in [11, 12, 13, 14, 15, 16, 17]:
    try:
        converted = version_converter.convert_version(model, target)
        print(f"Successfully converted to opset {target}")
        onnx.save(converted, DST, save_as_external_data=False)
        print(f"Saved to {DST}")
        print(f"File size: {os.path.getsize(DST):,} bytes")
        sys.exit(0)
    except Exception as e:
        print(f"opset {target} failed: {e}")

print("All conversion attempts failed.")
sys.exit(1)
