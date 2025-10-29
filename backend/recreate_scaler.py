from pathlib import Path
import pickle, joblib, sys
import pandas as pd
from sklearn.preprocessing import StandardScaler

PROJECT_ROOT = Path(__file__).resolve().parent
candidates = [
    PROJECT_ROOT / ".." / "data" / "raw" / "winequality-red.csv",
    PROJECT_ROOT / ".." / "data" / "processed" / "wine_processed.csv",
    PROJECT_ROOT / "data" / "raw" / "winequality-red.csv",
    PROJECT_ROOT / "data" / "processed" / "wine_processed.csv"
]

found = None
for p in candidates:
    if p.exists():
        found = p
        break

print("Project root:", PROJECT_ROOT)
if not found:
    print("ERROR: Could not find CSV. Checked:")
    for p in candidates: print("  -", p)
    sys.exit(2)

print("Using CSV:", found)
df = pd.read_csv(found)
feature_cols_space = [
    'fixed acidity', 'volatile acidity', 'citric acid',
    'residual sugar', 'chlorides', 'free sulfur dioxide',
    'total sulfur dioxide', 'density', 'pH', 'sulphates', 'alcohol'
]
feature_cols_underscore = [
    'fixed_acidity', 'volatile_acidity', 'citric_acid',
    'residual_sugar', 'chlorides', 'free_sulfur_dioxide',
    'total_sulfur_dioxide', 'density', 'ph', 'sulphates', 'alcohol'
]

if all(c in df.columns for c in feature_cols_space):
    features_df = df[feature_cols_space]
elif all(c in df.columns for c in feature_cols_underscore):
    features_df = df[feature_cols_underscore]
    features_df.columns = feature_cols_space
else:
    print("ERROR: expected columns not found; columns present:", list(df.columns)[:50])
    sys.exit(3)

scaler = StandardScaler()
scaler.fit(features_df.values)

saved_dir = PROJECT_ROOT / "saved_models"
saved_dir.mkdir(parents=True, exist_ok=True)

with open(saved_dir / "scaler.pkl", "wb") as f:
    pickle.dump(scaler, f)
joblib.dump(scaler, saved_dir / "scaler.joblib")

print("Saved scaler.pkl and scaler.joblib to", saved_dir)
