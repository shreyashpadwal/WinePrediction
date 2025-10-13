"""
Test suite for ML service.
"""

import pytest
import numpy as np
import pandas as pd
from unittest.mock import patch, MagicMock, mock_open
import sys
import os
import pickle
import json

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.services.ml_service import MLPredictor, get_ml_predictor, initialize_ml_predictor


@pytest.fixture
def sample_wine_features():
    """Sample wine features for testing."""
    return {
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


@pytest.fixture
def mock_model():
    """Mock ML model for testing."""
    mock_model = MagicMock()
    mock_model.predict.return_value = np.array([1])  # Good quality
    mock_model.predict_proba.return_value = np.array([[0.15, 0.85]])  # 85% good
    return mock_model


@pytest.fixture
def mock_scaler():
    """Mock scaler for testing."""
    mock_scaler = MagicMock()
    mock_scaler.transform.return_value = np.array([[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1]])
    return mock_scaler


@pytest.fixture
def mock_label_encoder():
    """Mock label encoder for testing."""
    mock_encoder = MagicMock()
    mock_encoder.inverse_transform.return_value = np.array(['Good'])
    mock_encoder.classes_ = np.array(['Bad', 'Good'])
    return mock_encoder


@pytest.fixture
def mock_model_info():
    """Mock model comparison info."""
    return {
        "best_model": "Random Forest (Tuned)",
        "best_accuracy": 0.85,
        "feature_names": [
            'fixed_acidity', 'volatile_acidity', 'citric_acid', 'residual_sugar',
            'chlorides', 'free_sulfur_dioxide', 'total_sulfur_dioxide',
            'density', 'ph', 'sulphates', 'alcohol'
        ],
        "target_classes": ['Bad', 'Good']
    }


class TestMLPredictor:
    """Test MLPredictor class."""
    
    @patch('builtins.open', new_callable=mock_open)
    @patch('pickle.load')
    @patch('json.load')
    @patch('pathlib.Path.exists')
    def test_ml_predictor_initialization(
        self, 
        mock_exists, 
        mock_json_load, 
        mock_pickle_load, 
        mock_file,
        mock_model,
        mock_scaler,
        mock_label_encoder,
        mock_model_info
    ):
        """Test MLPredictor initialization."""
        # Mock file existence
        mock_exists.return_value = True
        
        # Mock pickle loads
        mock_pickle_load.side_effect = [mock_model, mock_scaler, mock_label_encoder]
        
        # Mock JSON load
        mock_json_load.return_value = mock_model_info
        
        # Create predictor
        predictor = MLPredictor()
        
        # Verify initialization
        assert predictor.best_model is not None
        assert predictor.scaler is not None
        assert predictor.label_encoder is not None
        assert len(predictor.all_models) > 0
    
    @patch('builtins.open', new_callable=mock_open)
    @patch('pickle.load')
    @patch('pathlib.Path.exists')
    def test_ml_predictor_missing_files(self, mock_exists, mock_pickle_load, mock_file):
        """Test MLPredictor initialization with missing files."""
        # Mock file not existing
        mock_exists.return_value = False
        
        with pytest.raises(FileNotFoundError):
            MLPredictor()
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_predict_success(self, mock_load_models, sample_wine_features, mock_model, mock_scaler, mock_label_encoder):
        """Test successful prediction."""
        # Create predictor with mocked components
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.best_model = mock_model
        predictor.scaler = mock_scaler
        predictor.label_encoder = mock_label_encoder
        predictor.logger = MagicMock()
        
        # Test prediction
        result = predictor.predict(sample_wine_features)
        
        # Verify result
        assert "prediction" in result
        assert "confidence" in result
        assert "probability_good" in result
        assert "model_used" in result
        
        assert result["prediction"] == "Good"
        assert result["confidence"] == 0.85
        assert result["probability_good"] == 0.85
        assert result["model_used"] == "Best Model"
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_predict_missing_scaler(self, mock_load_models, sample_wine_features, mock_model):
        """Test prediction with missing scaler."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.best_model = mock_model
        predictor.scaler = None
        predictor.label_encoder = MagicMock()
        predictor.logger = MagicMock()
        
        with pytest.raises(ValueError, match="Scaler not loaded"):
            predictor.predict(sample_wine_features)
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_predict_missing_model(self, mock_load_models, sample_wine_features, mock_scaler):
        """Test prediction with missing model."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.best_model = None
        predictor.scaler = mock_scaler
        predictor.label_encoder = MagicMock()
        predictor.logger = MagicMock()
        
        with pytest.raises(ValueError, match="Best model not loaded"):
            predictor.predict(sample_wine_features)
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_get_all_predictions(self, mock_load_models, sample_wine_features, mock_model, mock_scaler, mock_label_encoder):
        """Test getting predictions from all models."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.best_model = mock_model
        predictor.scaler = mock_scaler
        predictor.label_encoder = mock_label_encoder
        predictor.all_models = {"Test Model": mock_model}
        predictor.logger = MagicMock()
        
        predictions = predictor.get_all_predictions(sample_wine_features)
        
        assert len(predictions) == 1
        assert predictions[0].model_name == "Test Model"
        assert predictions[0].prediction == "Good"
        assert predictions[0].confidence == 0.85
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_get_model_info(self, mock_load_models, mock_model, mock_scaler, mock_label_encoder, mock_model_info):
        """Test getting model information."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.best_model = mock_model
        predictor.scaler = mock_scaler
        predictor.label_encoder = mock_label_encoder
        predictor.all_models = {"Test Model": mock_model}
        predictor.model_info = mock_model_info
        predictor.logger = MagicMock()
        
        info = predictor.get_model_info()
        
        assert info["best_model_loaded"] is True
        assert info["scaler_loaded"] is True
        assert info["label_encoder_loaded"] is True
        assert info["total_models"] == 1
        assert "Test Model" in info["model_names"]
        assert info["best_model_name"] == "Random Forest (Tuned)"
        assert info["best_accuracy"] == 0.85
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_validate_features_valid(self, mock_load_models, sample_wine_features):
        """Test feature validation with valid data."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.logger = MagicMock()
        
        is_valid, error_msg = predictor.validate_features(sample_wine_features)
        
        assert is_valid is True
        assert error_msg is None
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_validate_features_missing(self, mock_load_models):
        """Test feature validation with missing features."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.logger = MagicMock()
        
        incomplete_features = {
            'fixed_acidity': 7.4,
            'volatile_acidity': 0.7,
            # Missing other features
        }
        
        is_valid, error_msg = predictor.validate_features(incomplete_features)
        
        assert is_valid is False
        assert "Missing features" in error_msg
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_validate_features_extra(self, mock_load_models, sample_wine_features):
        """Test feature validation with extra features."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.logger = MagicMock()
        
        extra_features = sample_wine_features.copy()
        extra_features['extra_feature'] = 1.0
        
        is_valid, error_msg = predictor.validate_features(extra_features)
        
        assert is_valid is False
        assert "Unexpected features" in error_msg
    
    @patch('app.services.ml_service.MLPredictor._load_models')
    def test_validate_features_invalid_values(self, mock_load_models):
        """Test feature validation with invalid values."""
        predictor = MLPredictor.__new__(MLPredictor)
        predictor.logger = MagicMock()
        
        invalid_features = {
            'fixed_acidity': float('nan'),  # Invalid value
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
        
        is_valid, error_msg = predictor.validate_features(invalid_features)
        
        assert is_valid is False
        assert "invalid value" in error_msg


class TestGlobalFunctions:
    """Test global functions."""
    
    @patch('app.services.ml_service.ml_predictor', None)
    @patch('app.services.ml_service.MLPredictor')
    def test_get_ml_predictor(self, mock_ml_predictor_class):
        """Test get_ml_predictor function."""
        mock_instance = MagicMock()
        mock_ml_predictor_class.return_value = mock_instance
        
        result = get_ml_predictor()
        
        assert result == mock_instance
        mock_ml_predictor_class.assert_called_once()
    
    @patch('app.services.ml_service.ml_predictor', None)
    @patch('app.services.ml_service.MLPredictor')
    def test_initialize_ml_predictor_success(self, mock_ml_predictor_class):
        """Test successful ML predictor initialization."""
        mock_instance = MagicMock()
        mock_ml_predictor_class.return_value = mock_instance
        
        result = initialize_ml_predictor()
        
        assert result is True
        mock_ml_predictor_class.assert_called_once()
    
    @patch('app.services.ml_service.MLPredictor')
    def test_initialize_ml_predictor_failure(self, mock_ml_predictor_class):
        """Test failed ML predictor initialization."""
        mock_ml_predictor_class.side_effect = Exception("Initialization failed")
        
        result = initialize_ml_predictor()
        
        assert result is False


class TestDataTransformation:
    """Test data transformation functionality."""
    
    def test_feature_scaling(self, sample_wine_features, mock_scaler):
        """Test feature scaling."""
        # Convert to DataFrame
        feature_df = pd.DataFrame([sample_wine_features])
        
        # Apply scaling
        scaled_features = mock_scaler.transform(feature_df)
        
        # Verify scaling was called
        mock_scaler.transform.assert_called_once()
        assert scaled_features.shape == (1, 11)
    
    def test_label_encoding(self, mock_label_encoder):
        """Test label encoding/decoding."""
        # Test encoding
        encoded = np.array([1])  # Good quality
        decoded = mock_label_encoder.inverse_transform(encoded)
        
        assert decoded[0] == "Good"
        mock_label_encoder.inverse_transform.assert_called_with(encoded)


if __name__ == "__main__":
    pytest.main([__file__])
