"""
Test error handling and edge cases.
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.main import app
from app.utils.error_handlers import (
    WinePredictionError,
    ModelNotLoadedError,
    InvalidWineDataError,
    GeminiAPIError,
    ValidationError,
    validate_wine_features,
    check_so2_relationship
)

client = TestClient(app)


class TestErrorHandlers:
    """Test custom error handlers."""
    
    def test_wine_prediction_error(self):
        """Test WinePredictionError creation."""
        error = WinePredictionError("Test error", "TEST_ERROR")
        assert str(error) == "Test error"
        assert error.error_code == "TEST_ERROR"
    
    def test_model_not_loaded_error(self):
        """Test ModelNotLoadedError."""
        error = ModelNotLoadedError()
        assert "ML model is not loaded" in str(error)
        assert error.error_code == "MODEL_NOT_LOADED"
    
    def test_invalid_wine_data_error(self):
        """Test InvalidWineDataError."""
        error = InvalidWineDataError("Custom message")
        assert str(error) == "Custom message"
        assert error.error_code == "INVALID_WINE_DATA"
    
    def test_gemini_api_error(self):
        """Test GeminiAPIError."""
        error = GeminiAPIError("API failed")
        assert str(error) == "API failed"
        assert error.error_code == "GEMINI_API_ERROR"
    
    def test_validation_error(self):
        """Test ValidationError."""
        error = ValidationError("Invalid input")
        assert str(error) == "Invalid input"
        assert error.error_code == "VALIDATION_ERROR"


class TestValidationFunctions:
    """Test validation functions."""
    
    def test_validate_wine_features_valid(self):
        """Test validation with valid features."""
        valid_features = {
            'fixed_acidity': 7.4,
            'volatile_acidity': 0.7,
            'citric_acid': 0.0,
            'residual_sugar': 1.9,
            'chlorides': 0.076,
            'free_sulfur_dioxide': 11.0,
            'total_sulfur_dioxide': 34.0,
            'density': 0.9978,
            'ph': 3.51,
            'sulphates': 0.56,
            'alcohol': 9.4
        }
        
        # Should not raise any exception
        validate_wine_features(valid_features)
    
    def test_validate_wine_features_missing(self):
        """Test validation with missing features."""
        incomplete_features = {
            'fixed_acidity': 7.4,
            'volatile_acidity': 0.7,
            # Missing other features
        }
        
        with pytest.raises(ValidationError, match="Missing required features"):
            validate_wine_features(incomplete_features)
    
    def test_validate_wine_features_extra(self):
        """Test validation with extra features."""
        extra_features = {
            'fixed_acidity': 7.4,
            'volatile_acidity': 0.7,
            'citric_acid': 0.0,
            'residual_sugar': 1.9,
            'chlorides': 0.076,
            'free_sulfur_dioxide': 11.0,
            'total_sulfur_dioxide': 34.0,
            'density': 0.9978,
            'ph': 3.51,
            'sulphates': 0.56,
            'alcohol': 9.4,
            'extra_feature': 1.0  # Extra feature
        }
        
        with pytest.raises(ValidationError, match="Unexpected features"):
            validate_wine_features(extra_features)
    
    def test_validate_wine_features_invalid_types(self):
        """Test validation with invalid types."""
        invalid_features = {
            'fixed_acidity': "not a number",
            'volatile_acidity': 0.7,
            'citric_acid': 0.0,
            'residual_sugar': 1.9,
            'chlorides': 0.076,
            'free_sulfur_dioxide': 11.0,
            'total_sulfur_dioxide': 34.0,
            'density': 0.9978,
            'ph': 3.51,
            'sulphates': 0.56,
            'alcohol': 9.4
        }
        
        with pytest.raises(ValidationError, match="must be numeric"):
            validate_wine_features(invalid_features)
    
    def test_validate_wine_features_nan_values(self):
        """Test validation with NaN values."""
        import math
        
        nan_features = {
            'fixed_acidity': math.nan,
            'volatile_acidity': 0.7,
            'citric_acid': 0.0,
            'residual_sugar': 1.9,
            'chlorides': 0.076,
            'free_sulfur_dioxide': 11.0,
            'total_sulfur_dioxide': 34.0,
            'density': 0.9978,
            'ph': 3.51,
            'sulphates': 0.56,
            'alcohol': 9.4
        }
        
        with pytest.raises(ValidationError, match="invalid value"):
            validate_wine_features(nan_features)
    
    def test_check_so2_relationship_valid(self):
        """Test SO2 relationship check with valid data."""
        valid_features = {
            'free_sulfur_dioxide': 11.0,
            'total_sulfur_dioxide': 34.0
        }
        
        # Should not raise any exception
        check_so2_relationship(valid_features)
    
    def test_check_so2_relationship_invalid(self):
        """Test SO2 relationship check with invalid data."""
        invalid_features = {
            'free_sulfur_dioxide': 50.0,
            'total_sulfur_dioxide': 34.0  # Less than free SO2
        }
        
        with pytest.raises(ValidationError, match="must be >="):
            check_so2_relationship(invalid_features)


class TestAPIErrorHandling:
    """Test API error handling."""
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_prediction_with_model_error(self, mock_get_ml):
        """Test prediction endpoint with model error."""
        mock_predictor = MagicMock()
        mock_predictor.validate_features.side_effect = ModelNotLoadedError("Model not available")
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
        assert response.status_code == 503
        assert "MODEL_NOT_LOADED" in response.json()["error_code"]
    
    @patch('app.routes.prediction.get_ml_predictor')
    def test_prediction_with_validation_error(self, mock_get_ml):
        """Test prediction endpoint with validation error."""
        mock_predictor = MagicMock()
        mock_predictor.validate_features.side_effect = ValidationError("Invalid data")
        mock_get_ml.return_value = mock_predictor
        
        sample_data = {
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
        
        response = client.post("/api/v1/prediction/predict", json=sample_data)
        assert response.status_code == 422
        assert "VALIDATION_ERROR" in response.json()["error_code"]
    
    def test_prediction_with_malformed_json(self):
        """Test prediction endpoint with malformed JSON."""
        response = client.post(
            "/api/v1/prediction/predict",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code == 422
    
    def test_prediction_with_missing_fields(self):
        """Test prediction endpoint with missing required fields."""
        incomplete_data = {
            "fixed_acidity": 7.4,
            "volatile_acidity": 0.7,
            # Missing other required fields
        }
        
        response = client.post("/api/v1/prediction/predict", json=incomplete_data)
        assert response.status_code == 422
    
    def test_health_endpoint_with_model_error(self):
        """Test health endpoint when model fails to load."""
        with patch('app.routes.prediction.get_ml_predictor') as mock_get_ml:
            mock_predictor = MagicMock()
            mock_predictor.get_model_info.side_effect = ModelNotLoadedError("Model not available")
            mock_get_ml.return_value = mock_predictor
            
            response = client.get("/api/v1/prediction/health")
            assert response.status_code == 200  # Health endpoint should still work
            assert response.json()["status"] == "unhealthy"


class TestEdgeCases:
    """Test edge cases and boundary conditions."""
    
    def test_extreme_wine_values(self):
        """Test with extreme but valid wine values."""
        extreme_data = {
            "fixed_acidity": 16.0,  # Maximum
            "volatile_acidity": 0.0,  # Minimum
            "citric_acid": 2.0,  # Maximum
            "residual_sugar": 70.0,  # Maximum
            "chlorides": 1.0,  # Maximum
            "free_sulfur_dioxide": 300.0,  # Maximum
            "total_sulfur_dioxide": 500.0,  # Maximum
            "density": 1.05,  # Maximum
            "ph": 4.5,  # Maximum
            "sulphates": 3.0,  # Maximum
            "alcohol": 16.0,  # Maximum
        }
        
        # Should not raise validation error
        validate_wine_features(extreme_data)
    
    def test_boundary_wine_values(self):
        """Test with boundary wine values."""
        boundary_data = {
            "fixed_acidity": 3.0,  # Minimum
            "volatile_acidity": 2.0,  # Maximum
            "citric_acid": 0.0,  # Minimum
            "residual_sugar": 0.0,  # Minimum
            "chlorides": 0.0,  # Minimum
            "free_sulfur_dioxide": 0.0,  # Minimum
            "total_sulfur_dioxide": 0.0,  # Minimum
            "density": 0.98,  # Minimum
            "ph": 2.5,  # Minimum
            "sulphates": 0.0,  # Minimum
            "alcohol": 8.0,  # Minimum
        }
        
        # Should not raise validation error
        validate_wine_features(boundary_data)
    
    def test_so2_boundary_cases(self):
        """Test SO2 relationship boundary cases."""
        # Equal values should be valid
        equal_so2 = {
            'free_sulfur_dioxide': 30.0,
            'total_sulfur_dioxide': 30.0
        }
        check_so2_relationship(equal_so2)
        
        # Zero values should be valid
        zero_so2 = {
            'free_sulfur_dioxide': 0.0,
            'total_sulfur_dioxide': 0.0
        }
        check_so2_relationship(zero_so2)


if __name__ == "__main__":
    pytest.main([__file__])
