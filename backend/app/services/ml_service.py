"""
ML Service for Wine Quality Prediction.
Handles model loading, prediction, and model comparison.
"""

import pickle
import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Any, Tuple
from pathlib import Path
import logging
from datetime import datetime

from ..utils.logger import get_logger, log_errors, LoggerMixin
from ..utils.validators import WineFeatures, ModelPrediction

logger = get_logger(__name__)


class MLPredictor(LoggerMixin):
    """
    Machine Learning predictor for wine quality.
    Handles model loading, prediction, and comparison across multiple models.
    """
    
    def __init__(self, models_dir: str = "saved_models"):
        """
        Initialize ML predictor with model loading.
        
        Args:
            models_dir: Directory containing saved models
        """
        self.models_dir = Path(models_dir)
        self.best_model = None
        self.scaler = None
        self.label_encoder = None
        self.all_models = {}
        self.model_info = {}
        
        self._load_models()
    
    def _convert_feature_names(self, features: Dict[str, float]) -> Dict[str, float]:
        """
        Convert API feature names (with underscores) to model feature names (with spaces).
        
        Args:
            features: Dictionary with API feature names (e.g., 'fixed_acidity')
            
        Returns:
            Dictionary with model feature names (e.g., 'fixed acidity')
        """
        feature_name_mapping = {
            'fixed_acidity': 'fixed acidity',
            'volatile_acidity': 'volatile acidity',
            'citric_acid': 'citric acid',
            'residual_sugar': 'residual sugar',
            'chlorides': 'chlorides',
            'free_sulfur_dioxide': 'free sulfur dioxide',
            'total_sulfur_dioxide': 'total sulfur dioxide',
            'density': 'density',
            'ph': 'pH',
            'sulphates': 'sulphates',
            'alcohol': 'alcohol'
        }
        
        return {feature_name_mapping.get(k, k): v for k, v in features.items()}
    
    @log_errors
    def _load_models(self) -> None:
        """Load all saved models and preprocessing objects."""
        try:
            # Load best model
            best_model_path = self.models_dir / "best_model.pkl"
            if best_model_path.exists():
                with open(best_model_path, 'rb') as f:
                    self.best_model = pickle.load(f)
                self.logger.info(f"Best model loaded from {best_model_path}")
            else:
                self.logger.error(f"Best model file not found: {best_model_path}")
                raise FileNotFoundError(f"Best model file not found: {best_model_path}")
            
            # Load scaler
            scaler_path = self.models_dir / "scaler.pkl"
            if scaler_path.exists():
                with open(scaler_path, 'rb') as f:
                    self.scaler = pickle.load(f)
                self.logger.info(f"Scaler loaded from {scaler_path}")
            else:
                self.logger.error(f"Scaler file not found: {scaler_path}")
                raise FileNotFoundError(f"Scaler file not found: {scaler_path}")
            
            # Load label encoder
            label_encoder_path = self.models_dir / "label_encoder.pkl"
            if label_encoder_path.exists():
                with open(label_encoder_path, 'rb') as f:
                    self.label_encoder = pickle.load(f)
                self.logger.info(f"Label encoder loaded from {label_encoder_path}")
            else:
                self.logger.error(f"Label encoder file not found: {label_encoder_path}")
                raise FileNotFoundError(f"Label encoder file not found: {label_encoder_path}")
            
            # Load model comparison info
            comparison_path = self.models_dir / "model_comparison.json"
            if comparison_path.exists():
                import json
                with open(comparison_path, 'r') as f:
                    self.model_info = json.load(f)
                self.logger.info(f"Model comparison info loaded from {comparison_path}")
            
            # Load all models for comparison
            self._load_all_models()
            
        except Exception as e:
            self.logger.error(f"Error loading models: {str(e)}")
            raise
    
    @log_errors
    def _load_all_models(self) -> None:
        """Load all available models for comparison."""
        try:
            # For now, we'll use the best model for all predictions
            # In a real scenario, you might have multiple model files
            self.all_models = {
                "Best Model": self.best_model,
                # Add other models here if available
            }
            self.logger.info(f"Loaded {len(self.all_models)} models for comparison")
        except Exception as e:
            self.logger.error(f"Error loading all models: {str(e)}")
            # Don't raise here, as we can still work with just the best model
    
    @log_errors
    def predict(self, features: Dict[str, float]) -> Dict[str, Any]:
        """
        Predict wine quality using the best model.
        
        Args:
            features: Dictionary of wine features (with underscores)
            
        Returns:
            Dictionary containing prediction, confidence, and probability
        """
        try:
            # Convert feature names to match model training
            model_features = self._convert_feature_names(features)
            
            # Convert features to DataFrame
            feature_df = pd.DataFrame([model_features])
            
            # Scale features
            if self.scaler is None:
                raise ValueError("Scaler not loaded")
            
            scaled_features = self.scaler.transform(feature_df)
            
            # Make prediction
            if self.best_model is None:
                raise ValueError("Best model not loaded")
            
            # Get prediction and probability
            prediction_encoded = self.best_model.predict(scaled_features)[0]
            probabilities = self.best_model.predict_proba(scaled_features)[0]
            
            # Decode prediction
            if self.label_encoder is None:
                raise ValueError("Label encoder not loaded")
            
            prediction = self.label_encoder.inverse_transform([prediction_encoded])[0]
            confidence = float(max(probabilities))
            probability_good = float(probabilities[1]) if len(probabilities) > 1 else 0.0
            
            result = {
                "prediction": prediction,
                "confidence": confidence,
                "probability_good": probability_good,
                "model_used": "Best Model"
            }
            
            self.logger.info(f"Prediction made: {prediction} (confidence: {confidence:.3f})")
            return result
            
        except Exception as e:
            self.logger.error(f"Error making prediction: {str(e)}")
            raise
    
    @log_errors
    def get_all_predictions(self, features: Dict[str, float]) -> List[ModelPrediction]:
        """
        Get predictions from all available models.
        
        Args:
            features: Dictionary of wine features (with underscores)
            
        Returns:
            List of predictions from all models
        """
        try:
            predictions = []
            
            # Convert feature names to match model training
            model_features = self._convert_feature_names(features)
            
            # Convert features to DataFrame
            feature_df = pd.DataFrame([model_features])
            
            # Scale features
            if self.scaler is None:
                raise ValueError("Scaler not loaded")
            
            scaled_features = self.scaler.transform(feature_df)
            
            for model_name, model in self.all_models.items():
                try:
                    # Make prediction
                    prediction_encoded = model.predict(scaled_features)[0]
                    probabilities = model.predict_proba(scaled_features)[0]
                    
                    # Decode prediction
                    if self.label_encoder is None:
                        raise ValueError("Label encoder not loaded")
                    
                    prediction = self.label_encoder.inverse_transform([prediction_encoded])[0]
                    confidence = float(max(probabilities))
                    probability_good = float(probabilities[1]) if len(probabilities) > 1 else 0.0
                    
                    predictions.append(ModelPrediction(
                        model_name=model_name,
                        prediction=prediction,
                        confidence=confidence,
                        probability_good=probability_good
                    ))
                    
                except Exception as e:
                    self.logger.warning(f"Error predicting with {model_name}: {str(e)}")
                    # Add a fallback prediction
                    predictions.append(ModelPrediction(
                        model_name=model_name,
                        prediction="Unknown",
                        confidence=0.0,
                        probability_good=0.0
                    ))
            
            self.logger.info(f"Generated {len(predictions)} model predictions")
            return predictions
            
        except Exception as e:
            self.logger.error(f"Error getting all predictions: {str(e)}")
            raise
    
    @log_errors
    def get_model_info(self) -> Dict[str, Any]:
        """
        Get information about the loaded models.
        
        Returns:
            Dictionary containing model information
        """
        try:
            info = {
                "best_model_loaded": self.best_model is not None,
                "scaler_loaded": self.scaler is not None,
                "label_encoder_loaded": self.label_encoder is not None,
                "total_models": len(self.all_models),
                "model_names": list(self.all_models.keys())
            }
            
            # Add model comparison info if available
            if self.model_info:
                info.update({
                    "best_model_name": self.model_info.get("best_model", "Unknown"),
                    "best_accuracy": self.model_info.get("best_accuracy", 0.0),
                    "features_count": self.model_info.get("feature_names", [])
                })
            
            return info
            
        except Exception as e:
            self.logger.error(f"Error getting model info: {str(e)}")
            return {"error": str(e)}
    
    @log_errors
    def validate_features(self, features: Dict[str, float]) -> Tuple[bool, Optional[str]]:
        """
        Validate wine features against expected ranges.
        
        Args:
            features: Dictionary of wine features
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            # Expected feature names
            expected_features = [
                'fixed_acidity', 'volatile_acidity', 'citric_acid', 'residual_sugar',
                'chlorides', 'free_sulfur_dioxide', 'total_sulfur_dioxide',
                'density', 'ph', 'sulphates', 'alcohol'
            ]
            
            # Check if all features are present
            missing_features = [f for f in expected_features if f not in features]
            if missing_features:
                return False, f"Missing features: {missing_features}"
            
            # Check for extra features
            extra_features = [f for f in features.keys() if f not in expected_features]
            if extra_features:
                return False, f"Unexpected features: {extra_features}"
            
            # Check for non-numeric values
            for feature, value in features.items():
                if not isinstance(value, (int, float)):
                    return False, f"Feature {feature} must be numeric, got {type(value)}"
                
                if np.isnan(value) or np.isinf(value):
                    return False, f"Feature {feature} has invalid value: {value}"
            
            return True, None
            
        except Exception as e:
            self.logger.error(f"Error validating features: {str(e)}")
            return False, f"Validation error: {str(e)}"


# Global instance
ml_predictor = None


def get_ml_predictor() -> MLPredictor:
    """
    Get the global ML predictor instance.
    
    Returns:
        MLPredictor instance
    """
    global ml_predictor
    if ml_predictor is None:
        ml_predictor = MLPredictor()
    return ml_predictor


def initialize_ml_predictor() -> bool:
    """
    Initialize the global ML predictor.
    
    Returns:
        True if initialization successful, False otherwise
    """
    try:
        global ml_predictor
        ml_predictor = MLPredictor()
        logger.info("ML predictor initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize ML predictor: {str(e)}")
        return False