"""
Tests for Wine Quality Prediction API.
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app
import numpy as np

client = TestClient(app)

def test_good_wine_prediction():
    """
    Test prediction for a known good wine sample.
    """
    good_wine = {
        "fixed_acidity": 7.5,
        "volatile_acidity": 0.3,
        "citric_acid": 0.4,
        "residual_sugar": 2.0,
        "chlorides": 0.05,
        "free_sulfur_dioxide": 30,
        "total_sulfur_dioxide": 100,
        "density": 0.995,
        "pH": 3.3,
        "sulphates": 0.75,
        "alcohol": 12.5
    }
    
    response = client.post("/api/v1/prediction/predict", json=good_wine)
    assert response.status_code == 200
    
    result = response.json()
    assert result["prediction"] >= 6.0, "Good wine should have prediction >= 6.0"
    assert result["quality_label"] in ["Above Average", "Excellent"]
    assert result["probability_good"] > 0.7, "Good wine should have high probability"

def test_bad_wine_prediction():
    """
    Test prediction for a known low-quality wine sample.
    """
    bad_wine = {
        "fixed_acidity": 7.0,
        "volatile_acidity": 1.1,  # High volatile acidity
        "citric_acid": 0.1,      # Low citric acid
        "residual_sugar": 2.0,
        "chlorides": 0.15,       # High chlorides
        "free_sulfur_dioxide": 10, # Low SO2
        "total_sulfur_dioxide": 50,
        "density": 0.997,
        "pH": 3.5,
        "sulphates": 0.3,        # Low sulphates
        "alcohol": 9.0           # Low alcohol
    }
    
    response = client.post("/api/v1/prediction/predict", json=bad_wine)
    assert response.status_code == 200
    
    result = response.json()
    assert result["prediction"] < 6.0, "Bad wine should have prediction < 6.0"
    assert result["quality_label"] in ["Below Average", "Average"]
    assert result["probability_good"] < 0.3, "Bad wine should have low probability"

def test_feature_validation():
    """
    Test input validation for wine features.
    """
    invalid_wine = {
        "fixed_acidity": 20.0,  # Too high
        "volatile_acidity": 0.3,
        "citric_acid": 0.4,
        "residual_sugar": 2.0,
        "chlorides": 0.05,
        "free_sulfur_dioxide": 30,
        "total_sulfur_dioxide": 100,
        "density": 0.995,
        "pH": 3.3,
        "sulphates": 0.75,
        "alcohol": 12.5
    }
    
    response = client.post("/api/v1/prediction/predict", json=invalid_wine)
    assert response.status_code == 400
    assert "fixed_acidity" in response.json()["detail"].lower()

def test_missing_features():
    """
    Test handling of missing features.
    """
    incomplete_wine = {
        "fixed_acidity": 7.5,
        "volatile_acidity": 0.3,
        # Missing other features
    }
    
    response = client.post("/api/v1/prediction/predict", json=incomplete_wine)
    assert response.status_code == 400

def test_prediction_range():
    """
    Test that predictions stay within valid range.
    """
    # Test 10 random wines
    for _ in range(10):
        wine = {
            "fixed_acidity": np.random.uniform(3.0, 16.0),
            "volatile_acidity": np.random.uniform(0.0, 2.0),
            "citric_acid": np.random.uniform(0.0, 2.0),
            "residual_sugar": np.random.uniform(0.0, 70.0),
            "chlorides": np.random.uniform(0.0, 1.0),
            "free_sulfur_dioxide": np.random.uniform(0.0, 300.0),
            "total_sulfur_dioxide": np.random.uniform(0.0, 500.0),
            "density": np.random.uniform(0.98, 1.05),
            "pH": np.random.uniform(2.5, 4.5),
            "sulphates": np.random.uniform(0.0, 3.0),
            "alcohol": np.random.uniform(8.0, 16.0)
        }
        
        response = client.post("/api/v1/prediction/predict", json=wine)
        assert response.status_code == 200
        
        result = response.json()
        assert 3.0 <= result["prediction"] <= 9.0, "Prediction should be between 3 and 9"
        assert 0.0 <= result["probability_good"] <= 1.0, "Probability should be between 0 and 1"
        assert 0.0 <= result["confidence"] <= 1.0, "Confidence should be between 0 and 1"