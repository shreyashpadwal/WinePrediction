import pickle, joblib, pathlib, sys

p = pathlib.Path("saved_models")

def load(fp):
    if not fp.exists():
        return None
    if fp.suffix == ".joblib":
        import joblib
        return joblib.load(fp)
    with open(fp, "rb") as f:
        return pickle.load(f)

names = ["best_model.joblib", "best_model.pkl", "scaler.joblib", "scaler.pkl", "label_encoder.joblib", "label_encoder.pkl"]
for name in names:
    fp = p / name
    obj = load(fp)
    print("-" * 60)
    print(f"{name:25} ->", type(obj))
    if obj is None:
        print("   -> FILE MISSING or could not be loaded")
        continue
    # show some useful introspection
    try:
        if hasattr(obj, "__dict__"):
            keys = list(getattr(obj, "__dict__", {}).keys())
            print("   attrs:", keys[:12])
    except Exception:
        pass
    if hasattr(obj, "classes_"):
        try:
            cls = list(getattr(obj, "classes_"))
            print("   classes_ sample:", cls[:10])
        except Exception:
            print("   classes_ present (could not list)")
    # show repr head for arrays or other objects
    try:
        r = repr(obj)
        print("   repr head:", r[:400])
    except Exception:
        pass
print("-" * 60)
print("INSPECTION DONE")
