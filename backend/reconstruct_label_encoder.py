import pickle, joblib, pathlib, numpy as np
from sklearn.preprocessing import LabelEncoder
p = pathlib.Path("saved_models")
arr_path = p / "label_encoder.pkl"
if not arr_path.exists():
    print("label_encoder.pkl not found — cannot reconstruct")
    raise SystemExit(1)
with open(arr_path, "rb") as f:
    obj = pickle.load(f)
print("Loaded type:", type(obj))
# If it's already a LabelEncoder, exit
if hasattr(obj, "classes_") and not isinstance(obj, (list, tuple, np.ndarray)):
    print("Already a LabelEncoder object — nothing to do.")
    raise SystemExit(0)

# obj should be an array/list of classes
classes = list(obj)
print("Reconstructing LabelEncoder with", len(classes), "classes. Sample:", classes[:10])
le = LabelEncoder()
le.classes_ = np.array(classes, dtype=object)
with open(p / "label_encoder.pkl", "wb") as f:
    pickle.dump(le, f)
joblib.dump(le, p / "label_encoder.joblib")
print("Reconstructed and saved LabelEncoder at", p)
