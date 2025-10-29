import pickle, joblib, pathlib, numpy as np
p = pathlib.Path("saved_models")
for fname in ("label_encoder.joblib", "label_encoder.pkl"):
    fp = p / fname
    if not fp.exists():
        print(f"{fname} -> MISSING")
        continue
    try:
        if fp.suffix == ".joblib":
            import joblib
            obj = joblib.load(fp)
        else:
            with open(fp, "rb") as f:
                obj = pickle.load(f)
        print(f"{fname} -> {type(obj)}")
        if hasattr(obj, "classes_"):
            print("  classes_ length:", len(getattr(obj, "classes_")))
            print("  sample classes (first 10):", list(getattr(obj, "classes_"))[:10])
        else:
            # short repr for arrays or other objects
            r = repr(obj)
            print("  repr head:", r[:400])
    except Exception as e:
        print(f"{fname} -> ERROR loading: {repr(e)}")
