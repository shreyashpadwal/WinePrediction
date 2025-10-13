"""
Integration tests for the complete wine prediction flow.
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

# Create test client
client = TestClient(app)


@pytest.fixture
def sample_wine_samples():
    """Multiple wine samples for testing."""
    return [
        {
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
        },
        {
            "fixed_acidity": 8.1,
            "volatile_acidity": 0.6,
            "citric_acid": 0.1,
            "residual_sugar": 2.1,
            "chlorides": 0.092,
            "free_sulfur_dioxide": 15.0,
            "total_sulfur_dioxide": 40.0,
            "density": 0.9985,
            "ph": 3.25,
            "sulphates": 0.65,
            "alcohol": 10.2
        },
        {
            "fixed_acidity": 6.8,
            "volatile_acidity": 0.8,
            "citric_acid": 0.0,
            "residual_sugar": 1.4,
            "chlorides": 0.045,
            "free_sulfur_dioxide": 8.0,
            "total_sulfur_dioxide": 28.0,
            "density": 0.9965,
            "ph": 3.35,
            "sulphates": 0.45,
            "alcohol": 8.8
        }
    ]


@pytest.fixture
def mock_services():
    """Mock all services for integration testing."""
    # Mock ML predictor
    mock_ml_predictor = MagicMock()
    mock_ml_predictor.validate_features.return_value = (True, None)
    mock_ml_predictor.predict.return_value = {
        "prediction": "Good",
        "confidence": 0.85,
        "probability_good": 0.85,
        "model_used": "Random Forest"
    }
    mock_ml_predictor.get_all_predictions.return_value = [
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
        ),
        MagicMock(
            model_name="Logistic Regression",
            prediction="Bad",
            confidence=0.78,
            probability_good=0.22
        )
    ]
    mock_ml_predictor.get_model_info.return_value = {
        "best_model_loaded": True,
        "scaler_loaded": True,
        "label_encoder_loaded": True,
        "total_models": 3,
        "model_names": ["Random Forest", "XGBoost", "Logistic Regression"]
    }
    
    # Mock Gemini service
    mock_gemini_service = MagicMock()
    mock_gemini_service.get_wine_explanation.return_value = "This wine shows excellent balance with moderate acidity and good alcohol content."
    mock_gemini_service.test_connection.return_value = {
        "available": True,
        "message": "Gemini API connection successful"
    }
    
    return mock_ml_predictor, mock_gemini_service


class TestEndToEndFlow:
    """Test complete end-to-end prediction flow."""
    
    @patch('app.routes.prediction.get_gemini_service')
    @patch('app.routes.prediction.get_ml_predictor')
    def test_complete_prediction_flow(self, mock_get_ml, mock_get_gemini, sample_wine_samples, mock_services):
        """Test complete prediction flow with multiple samples."""
        mock_ml_predictor, mock_gemini_service = mock_services
        mock_get_ml.return_value = mock_ml_predictor
        mock_get_gemini.return_value = mock_gemini_service
        
        for i, wine_sample in enumerate(sample_wine_samples):
            # Test prediction endpoint
            response = client.post("/api/v1/prediction/predict", json=wine_sample)
            assert response.status_code == 200
            
            data = response.json()
            
            # Verify response structure
            required_fields = ["prediction", "confidence", "probability_good", "gemini_insight", "timestamp", "model_used"]
            for field in required_fields:
                assert field in data, f"Missing field {field} in response for sample {i}"
            
            # Verify data types and ranges
            assert isinstance(data["prediction"], str)
            assert data["prediction"] in ["Good", "Bad"]
            assert 0.0 <= data["confidence"] <= 1.0
            assert 0.0 <= data["probability_good"] <= 1.0
            assert isinstance(data["gemini_insight"], str)
            assert len(data["gemini_insight"]) > 0
            assert isinstance(data["timestamp"], str)
            assert isinstance(data["model_used"], str)
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_model_comparison_flow(self, mock_get_ml, sample_wine_samples, mock_services):
        """Test model comparison flow."""
        mock_ml_predictor, _ = mock_services
        mock_get_ml.return_value = mock_ml_predictor
        
        for wine_sample in sample_wine_samples:
            # Test comparison endpoint
            response = client.post("/api/v1/prediction/predict/compare", json=wine_sample)
            assert response.status_code == 200
            
            data = response.json()
            
            # Verify response structure
            required_fields = ["all_models_results", "consensus", "agreement_count", "total_models", "timestamp"]
            for field in required_fields:
                assert field in data, f"Missing field {field} in comparison response"
            
            # Verify data types and values
            assert isinstance(data["all_models_results"], list)
            assert len(data["all_models_results"]) == 3
            assert data["consensus"] in ["Good", "Bad", "Mixed"]
            assert 0 <= data["agreement_count"] <= data["total_models"]
            assert data["total_models"] == 3
            
            # Verify each model result
            for model_result in data["all_models_results"]:
                assert "model_name" in model_result
                assert "prediction" in model_result
                assert "confidence" in model_result
                assert "probability_good" in model_result
                assert model_result["prediction"] in ["Good", "Bad"]
                assert 0.0 <= model_result["confidence"] <= 1.0
                assert 0.0 <= model_result["probability_good"] <= 1.0


class TestHealthAndInfoEndpoints:
    """Test health and information endpoints."""
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_health_endpoint_integration(self, mock_get_ml, mock_services):
        """Test health endpoint integration."""
        mock_ml_predictor, _ = mock_services
        mock_get_ml.return_value = mock_ml_predictor
        
        response = client.get("/api/v1/prediction/health")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert data["model_loaded"] is True
        assert "model_info" in data
        assert "timestamp" in data
    
    def test_features_info_endpoint(self):
        """Test features info endpoint."""
        response = client.get("/api/v1/prediction/features/info")
        assert response.status_code == 200
        
        data = response.json()
        assert "features" in data
        assert "total_features" in data
        assert data["total_features"] == 11
        
        # Verify each feature has required fields
        for feature in data["features"]:
            required_fields = ["name", "display_name", "unit", "min", "max", "description"]
            for field in required_fields:
                assert field in feature, f"Missing field {field} in feature info"


class TestErrorScenarios:
    """Test error scenarios and edge cases."""
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_ml_service_failure(self, mock_get_ml):
        """Test handling of ML service failure."""
        mock_ml_predictor = MagicMock()
        mock_ml_predictor.validate_features.side_effect = Exception("ML service error")
        mock_get_ml.return_value = mock_ml_predictor
        
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
    
    @patch('app.routes.prediction.get_gemini_service')
    @patch('app.routes.prediction.get_ml_predictor')
    def test_gemini_service_failure(self, mock_get_ml, mock_get_gemini, sample_wine_samples, mock_services):
        """Test handling of Gemini service failure."""
        mock_ml_predictor, mock_gemini_service = mock_services
        mock_get_ml.return_value = mock_ml_predictor
        mock_get_gemini.return_value = mock_gemini_service
        
        # Make Gemini service fail
        mock_gemini_service.get_wine_explanation.side_effect = Exception("Gemini API error")
        
        wine_sample = sample_wine_samples[0]
        response = client.post("/api/v1/prediction/predict", json=wine_sample)
        
        # Should still succeed but without AI explanation
        assert response.status_code == 200
        data = response.json()
        assert data["gemini_insight"] is None
    
    def test_malformed_json(self):
        """Test handling of malformed JSON."""
        response = client.post(
            "/api/v1/prediction/predict",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code == 422
    
    def test_missing_required_fields(self):
        """Test handling of missing required fields."""
        incomplete_data = {
            "fixed_acidity": 7.4,
            "volatile_acidity": 0.7,
            # Missing other required fields
        }
        
        response = client.post("/api/v1/prediction/predict", json=incomplete_data)
        assert response.status_code == 422


class TestPerformance:
    """Test performance characteristics."""
    
    @patch('app.routes.prediction.get_gemini_service')
    @patch('app.routes.prediction.get_ml_predictor')
    def test_response_time(self, mock_get_ml, mock_get_gemini, sample_wine_samples, mock_services):
        """Test that responses are returned within acceptable time."""
        import time
        
        mock_ml_predictor, mock_gemini_service = mock_services
        mock_get_ml.return_value = mock_ml_predictor
        mock_get_gemini.return_value = mock_gemini_service
        
        wine_sample = sample_wine_samples[0]
        
        start_time = time.time()
        response = client.post("/api/v1/prediction/predict", json=wine_sample)
        end_time = time.time()
        
        response_time = end_time - start_time
        
        assert response.status_code == 200
        assert response_time < 2.0, f"Response time {response_time:.2f}s exceeds 2 second limit"
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_concurrent_requests(self, mock_get_ml, sample_wine_samples, mock_services):
        """Test handling of concurrent requests."""
        import threading
        import time
        
        mock_ml_predictor, _ = mock_services
        mock_get_ml.return_value = mock_ml_predictor
        
        results = []
        errors = []
        
        def make_request(wine_sample):
            try:
                response = client.post("/api/v1/prediction/predict", json=wine_sample)
                results.append(response.status_code)
            except Exception as e:
                errors.append(str(e))
        
        # Create multiple threads
        threads = []
        for wine_sample in sample_wine_samples:
            thread = threading.Thread(target=make_request, args=(wine_sample,))
            threads.append(thread)
        
        # Start all threads
        start_time = time.time()
        for thread in threads:
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        end_time = time.time()
        
        # Verify all requests succeeded
        assert len(errors) == 0, f"Errors occurred: {errors}"
        assert len(results) == len(sample_wine_samples)
        assert all(status == 200 for status in results)
        
        total_time = end_time - start_time
        assert total_time < 5.0, f"Concurrent requests took too long: {total_time:.2f}s"


if __name__ == "__main__":
    pytest.main([__file__])
