# saved_models\inspect_scaler.py
import pickle, joblib, pathlib, pprint, sys
pkl = pathlib.Path("scaler.pkl")
job = pathlib.Path("scaler.joblib")
def inspect(obj):
    t = type(obj)
    print("TYPE:", t)
    try:
        attrs = getattr(obj, "__dict__", None)
        if attrs is not None:
            print("ATTRS (dict) keys:", list(attrs.keys())[:50])
            for k in ("mean_", "scale_", "var_", "n_samples_seen_"):
                if k in attrs:
                    print(f"{k} head:", str(attrs[k])[:200])
            return
    except Exception as e:
        print("Error reading __dict__:", e)
    try:
        print("REPR (head):")
        print(repr(obj)[:1000])
    except Exception as e:
        print("Error repr:", e)

if job.exists():
    try:
        obj = joblib.load(job)
        print("Loaded joblib:", job)
        inspect(obj)
    except Exception as e:
        print("Joblib load error:", repr(e))
        sys.exit(0)
elif pkl.exists():
    try:
        with open(pkl, "rb") as f:
            obj = pickle.load(f)
        print("Loaded pickle:", pkl)
        inspect(obj)
    except Exception as e:
        print("Pickle load error:", repr(e))
        try:
            with open(pkl, "rb") as f:
                raw = f.read(1000)
            print("Raw bytes head (1000 bytes):")
            print(raw[:1000])
        except Exception as e2:
            print("Couldn't read raw bytes:", repr(e2))
else:
    print("No scaler file found in current directory (checked scaler.pkl and scaler.joblib)")
