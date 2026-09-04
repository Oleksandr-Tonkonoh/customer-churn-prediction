import joblib
import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent

model = joblib.load(BASE_DIR / "models" / "churn_model.pkl")
threshold = joblib.load(BASE_DIR / "models" / "churn_threshold.pkl")

def predict_churn(customer_data: dict):
    df = pd.DataFrame([customer_data])

    probability = model.predict_proba(df)[0, 1]

    prediction = int(probability >= threshold)

    return probability, prediction