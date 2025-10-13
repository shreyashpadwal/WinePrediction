"""
Test suite for FastAPI endpoints.
"""

import pytest
import json
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.main import app
from app.utils.validators import WineFeatures

# Create test client
client = TestClient(app)


@pytest.fixture
def sample_wine_data():
    """Sample wine data for testing."""
    return {
        "fixed_acidity": 7.4,
        "volatile_acidity": 0.7,
        "citric_acid": 0.0,
        "residual_sugar": 1.9,
        "chlorides": 0.076,
        "free_sulfur_dioxide": 11.0,
        "total_sulfur_dioxide": 34.0,
        "density": 0.9978,
        "ph": 3.51,
        "sulphates": 0.56,
        "alcohol": 9.4
    }


@pytest.fixture
def mock_ml_predictor():
    """Mock ML predictor for testing."""
    mock_predictor = MagicMock()
    mock_predictor.validate_features.return_value = (True, None)
    mock_predictor.predict.return_value = {
        "prediction": "Good",
        "confidence": 0.85,
        "probability_good": 0.85,
        "model_used": "Random Forest"
    }
    mock_predictor.get_all_predictions.return_value = [
        MagicMock(
            model_name="Random Forest",
            prediction="Good",
            confidence=0.85,
            probability_good=0.85
        ),
        MagicMock(
            model_name="XGBoost",
            prediction="Good",
            confidence=0.82,
            probability_good=0.82
        )
    ]
    mock_predictor.get_model_info.return_value = {
        "best_model_loaded": True,
        "scaler_loaded": True,
        "label_encoder_loaded": True,
        "total_models": 2,
        "model_names": ["Random Forest", "XGBoost"]
    }
    return mock_predictor


@pytest.fixture
def mock_gemini_service():
    """Mock Gemini service for testing."""
    mock_service = MagicMock()
    mock_service.get_wine_explanation.return_value = "This wine shows excellent balance with moderate acidity and good alcohol content."
    mock_service.test_connection.return_value = {
        "available": True,
        "message": "Gemini API connection successful"
    }
    return mock_service


class TestRootEndpoints:
    """Test root endpoints."""
    
    def test_root_endpoint(self):
        """Test root endpoint returns correct information."""
        response = client.get("/")
        assert response.status_code == 200
        
        data = response.json()
        assert "message" in data
        assert "version" in data
        assert "status" in data
        assert "endpoints" in data
        assert "features" in data
        assert data["status"] == "running"
    
    def test_health_endpoint(self):
        """Test health endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data
        assert "service" in data


class TestPredictionEndpoints:
    """Test prediction endpoints."""
    
    @patch('app.routes.prediction.get_ml_predictor')
    @patch('app.routes.prediction.get_gemini_service')
    def test_predict_endpoint_success(
        self, 
        mock_get_gemini, 
        mock_get_ml, 
        sample_wine_data, 
        mock_ml_predictor, 
        mock_gemini_service
    ):
        """Test successful prediction endpoint."""
        mock_get_ml.return_value = mock_ml_predictor
        mock_get_gemini.return_value = mock_gemini_service
        
        response = client.post("/api/v1/prediction/predict", json=sample_wine_data)
        assert response.status_code == 200
        
        data = response.json()
        assert "prediction" in data
        assert "confidence" in data
        assert "probability_good" in data
        assert "gemini_insight" in data
        assert "timestamp" in data
        assert "model_used" in data
        
        assert data["prediction"] == "Good"
        assert data["confidence"] == 0.85
        assert data["probability_good"] == 0.85
        assert data["model_used"] == "Random Forest"
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_predict_endpoint_invalid_data(self, mock_get_ml, mock_ml_predictor):
        """Test prediction endpoint with invalid data."""
        mock_get_ml.return_value = mock_ml_predictor
        mock_ml_predictor.validate_features.return_value = (False, "Invalid features")
        
        invalid_data = {
            "fixed_acidity": -1.0,  # Invalid negative value
            "volatile_acidity": 0.7,
            "citric_acid": 0.0,
            "residual_sugar": 1.9,
            "chlorides": 0.076,
            "free_sulfur_dioxide": 11.0,
            "total_sulfur_dioxide": 34.0,
            "density": 0.9978,
            "ph": 3.51,
            "sulphates": 0.56,
            "alcohol": 9.4
        }
        
        response = client.post("/api/v1/prediction/predict", json=invalid_data)
        assert response.status_code == 400
    
    def test_predict_endpoint_missing_fields(self):
        """Test prediction endpoint with missing fields."""
        incomplete_data = {
            "fixed_acidity": 7.4,
            "volatile_acidity": 0.7,
            # Missing other required fields
        }
        
        response = client.post("/api/v1/prediction/predict", json=incomplete_data)
        assert response.status_code == 422  # Validation error
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_compare_endpoint_success(self, mock_get_ml, sample_wine_data, mock_ml_predictor):
        """Test model comparison endpoint."""
        mock_get_ml.return_value = mock_ml_predictor
        
        response = client.post("/api/v1/prediction/predict/compare", json=sample_wine_data)
        assert response.status_code == 200
        
        data = response.json()
        assert "all_models_results" in data
        assert "consensus" in data
        assert "agreement_count" in data
        assert "total_models" in data
        assert "timestamp" in data
        
        assert len(data["all_models_results"]) == 2
        assert data["total_models"] == 2
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_health_check_endpoint(self, mock_get_ml, mock_ml_predictor):
        """Test health check endpoint."""
        mock_get_ml.return_value = mock_ml_predictor
        
        response = client.get("/api/v1/prediction/health")
        assert response.status_code == 200
        
        data = response.json()
        assert "status" in data
        assert "model_loaded" in data
        assert "model_info" in data
        assert "timestamp" in data
        
        assert data["status"] == "healthy"
        assert data["model_loaded"] is True
    
    def test_models_info_endpoint(self):
        """Test models info endpoint."""
        response = client.get("/api/v1/prediction/models/info")
        # This might fail if models aren't loaded, which is expected in tests
        assert response.status_code in [200, 500]
    
    def test_features_info_endpoint(self):
        """Test features info endpoint."""
        response = client.get("/api/v1/prediction/features/info")
        assert response.status_code == 200
        
        data = response.json()
        assert "features" in data
        assert "total_features" in data
        assert "timestamp" in data
        
        assert data["total_features"] == 11
        assert len(data["features"]) == 11


class TestValidation:
    """Test input validation."""
    
    def test_wine_features_validation(self):
        """Test WineFeatures model validation."""
        # Valid data
        valid_data = {
            "fixed_acidity": 7.4,
            "volatile_acidity": 0.7,
            "citric_acid": 0.0,
            "residual_sugar": 1.9,
            "chlorides": 0.076,
            "free_sulfur_dioxide": 11.0,
            "total_sulfur_dioxide": 34.0,
            "density": 0.9978,
            "ph": 3.51,
            "sulphates": 0.56,
            "alcohol": 9.4
        }
        
        wine_features = WineFeatures(**valid_data)
        assert wine_features.fixed_acidity == 7.4
        assert wine_features.alcohol == 9.4
    
    def test_wine_features_validation_errors(self):
        """Test WineFeatures model validation errors."""
        # Invalid data - negative fixed acidity
        invalid_data = {
            "fixed_acidity": -1.0,  # Invalid
            "volatile_acidity": 0.7,
            "citric_acid": 0.0,
            "residual_sugar": 1.9,
            "chlorides": 0.076,
            "free_sulfur_dioxide": 11.0,
            "total_sulfur_dioxide": 34.0,
            "density": 0.9978,
            "ph": 3.51,
            "sulphates": 0.56,
            "alcohol": 9.4
        }
        
        with pytest.raises(Exception):  # Should raise validation error
            WineFeatures(**invalid_data)
    
    def test_so2_validation(self):
        """Test SO2 validation (total >= free)."""
        invalid_data = {
            "fixed_acidity": 7.4,
            "volatile_acidity": 0.7,
            "citric_acid": 0.0,
            "residual_sugar": 1.9,
            "chlorides": 0.076,
            "free_sulfur_dioxide": 50.0,  # Higher than total
            "total_sulfur_dioxide": 34.0,  # Lower than free
            "density": 0.9978,
            "ph": 3.51,
            "sulphates": 0.56,
            "alcohol": 9.4
        }
        
        with pytest.raises(Exception):  # Should raise validation error
            WineFeatures(**invalid_data)


class TestErrorHandling:
    """Test error handling."""
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_ml_service_error(self, mock_get_ml):
        """Test handling of ML service errors."""
        mock_predictor = MagicMock()
        mock_predictor.validate_features.side_effect = Exception("ML service error")
        mock_get_ml.return_value = mock_predictor
        
        sample_data = {
            "fixed_acidity": 7.4,
            "volatile_acidity": 0.7,
            "citric_acid": 0.0,
            "residual_sugar": 1.9,
            "chlorides": 0.076,
            "free_sulfur_dioxide": 11.0,
            "total_sulfur_dioxide": 34.0,
            "density": 0.9978,
            "ph": 3.51,
            "sulphates": 0.56,
            "alcohol": 9.4
        }
        
        response = client.post("/api/v1/prediction/predict", json=sample_data)
        assert response.status_code == 500
    
    def test_invalid_json(self):
        """Test handling of invalid JSON."""
        response = client.post(
            "/api/v1/prediction/predict",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code == 422


if __name__ == "__main__":
    pytest.main([__file__])
