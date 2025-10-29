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

    def _is_scaler_valid(self) -> bool:
        """Return True if self.scaler looks like a real transformer with .transform()."""
        return (self.scaler is not None) and (not isinstance(self.scaler, np.ndarray)) and hasattr(self.scaler, "transform")

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
            # Try both .joblib and .pkl extensions for the model
            best_model_path = self.models_dir / "best_model.joblib"
            if not best_model_path.exists():
                best_model_path = self.models_dir / "best_model.pkl"
            
            if best_model_path.exists():
                if best_model_path.suffix == '.joblib':
                    import joblib
                    self.best_model = joblib.load(best_model_path)
                else:
                    with open(best_model_path, 'rb') as f:
                        self.best_model = pickle.load(f)
                self.logger.info(f"Best model loaded from {best_model_path}")
            else:
                self.logger.error(f"Best model file not found: {best_model_path}")
                raise FileNotFoundError(f"Best model file not found: {best_model_path}")
            
            # Try both .joblib and .pkl for scaler
            scaler_path = self.models_dir / "scaler.joblib"
            if not scaler_path.exists():
                scaler_path = self.models_dir / "scaler.pkl"
            
            if scaler_path.exists():
                if scaler_path.suffix == '.joblib':
                    import joblib
                    self.scaler = joblib.load(scaler_path)
                else:
                    with open(scaler_path, 'rb') as f:
                        try:
                            self.scaler = pickle.load(f)
                        except EOFError as e:
                            self.logger.error(f"Scaler pickle EOFError while loading {scaler_path}: {e}")
                            self.scaler = None
                # Log scaler type for quick debugging
                self.logger.info(f"Scaler loaded from {scaler_path} (type={type(self.scaler)})")
            else:
                self.logger.error(f"Scaler file not found: {scaler_path}")
                raise FileNotFoundError(f"Scaler file not found: {scaler_path}")
            
            # Try both .joblib and .pkl for label encoder
            label_encoder_path = self.models_dir / "label_encoder.joblib"
            if not label_encoder_path.exists():
                label_encoder_path = self.models_dir / "label_encoder.pkl"
            
            if label_encoder_path.exists():
                if label_encoder_path.suffix == '.joblib':
                    import joblib
                    self.label_encoder = joblib.load(label_encoder_path)
                else:
                    with open(label_encoder_path, 'rb') as f:
                        try:
                            self.label_encoder = pickle.load(f)
                        except EOFError as e:
                            self.logger.error(f"Label encoder pickle EOFError while loading {label_encoder_path}: {e}")
                            self.label_encoder = None
                self.logger.info(f"Label encoder loaded from {label_encoder_path} (type={type(self.label_encoder)})")
            else:
                # For regression models, we don't need a label encoder
                self.label_encoder = None
                self.logger.info("No label encoder found - assuming regression model")
            
            # If label_encoder was saved incorrectly as a numpy array of classes (common mistake),
            # wrap it in a simple object that provides inverse_transform and classes_.
            if self.label_encoder is not None and isinstance(self.label_encoder, np.ndarray):
                classes_arr = np.array(self.label_encoder)
                class _SimpleLabelEncoder:
                    def __init__(self, classes):
                        self.classes_ = np.array(classes, dtype=object)

                    def inverse_transform(self, values):
                        out = []
                        for v in values:
                            try:
                                # try interpreting as integer index
                                idx = int(v)
                                out.append(self.classes_[idx])
                            except Exception:
                                # try matching value to classes
                                try:
                                    matches = np.where(self.classes_ == v)[0]
                                    if len(matches) > 0:
                                        out.append(self.classes_[matches[0]])
                                    else:
                                        out.append(v)
                                except Exception:
                                    out.append(v)
                        return np.array(out, dtype=object)
                self.logger.warning("Label encoder loaded as numpy.ndarray — wrapping it into a simple label-encoder with inverse_transform().")
                self.label_encoder = _SimpleLabelEncoder(classes_arr)
            
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
            # Log input features
            self.logger.debug(f"Raw input features: {features}")
            
            # Convert feature names to match model training
            model_features = self._convert_feature_names(features)
            
            # Ensure consistent feature order
            expected_features = [
                'fixed acidity', 'volatile acidity', 'citric acid', 
                'residual sugar', 'chlorides', 'free sulfur dioxide',
                'total sulfur dioxide', 'density', 'pH', 'sulphates', 'alcohol'
            ]
            
            # Create DataFrame with ordered features
            feature_values = [model_features.get(feat, 0.0) for feat in expected_features]
            feature_df = pd.DataFrame([feature_values], columns=expected_features)
            self.logger.debug(f"Ordered features: {feature_df.to_dict('records')[0]}")
            
            # Check if model is a pipeline that includes preprocessing
            is_pipeline = hasattr(self.best_model, 'steps')
            has_preprocessor = hasattr(self.best_model, 'named_steps') and any(
                step for step in getattr(self.best_model, 'named_steps', {}).keys()
                if 'preprocessor' in step or 'scaler' in step
            )
            
            # Determine if we need external preprocessing
            if is_pipeline and has_preprocessor:
                self.logger.info("Using model's internal pipeline for preprocessing")
                processed_features = feature_df
            else:
                # Scale features using external scaler
                if self.scaler is None:
                    raise ValueError("Scaler not loaded and model has no internal preprocessing")
                # Defensive: handle wrong-saved scaler (numpy array)
                if isinstance(self.scaler, np.ndarray):
                    # scaler is an array (likely incorrectly saved). Log and skip transform.
                    self.logger.warning(
                        "Scaler appears to be a numpy.ndarray (likely saved incorrectly). "
                        "Skipping scaler.transform and using raw feature_df as processed_features."
                    )
                    processed_features = feature_df
                else:
                    processed_features = self.scaler.transform(feature_df)
                    # Keep a consistent dataframe/array shape for downstream
                    try:
                        self.logger.debug(f"Scaled features shape: {processed_features.shape}")
                    except Exception:
                        pass
            
            # Make prediction
            if self.best_model is None:
                raise ValueError("Best model not loaded")
            
            # Get the final estimator (handle both pipeline and standalone models)
            final_estimator = self.best_model.named_steps['classifier'] if is_pipeline else self.best_model
            
            # Detect model type
            is_regressor = (
                hasattr(final_estimator, "predict") and 
                not hasattr(final_estimator, "predict_proba")
            )

            # Debug: log model type and estimator info
            self.logger.debug({
                'is_pipeline': is_pipeline,
                'has_preprocessor': has_preprocessor,
                'final_estimator_type': type(final_estimator).__name__,
                'is_regressor': is_regressor
            })
            
            # Make prediction based on model type
            if is_regressor:
                # Regression case
                raw_prediction = self.best_model.predict(processed_features)[0]
                prediction = float(raw_prediction)
                
                # Map regression output to quality score (3-9 scale)
                prediction = max(3, min(9, round(prediction)))
                
                # Calculate confidence based on prediction range
                typical_range = [3, 9]  # Wine quality typical range
                range_size = typical_range[1] - typical_range[0]
                distance_from_bounds = min(
                    abs(raw_prediction - typical_range[0]),
                    abs(raw_prediction - typical_range[1])
                )
                confidence = 1.0 - (distance_from_bounds / range_size)
                confidence = max(0.5, min(0.99, confidence))  # Bound confidence
                
                # Calculate probability of being good wine (>=6)
                probability_good = 1.0 if prediction >= 6 else 0.0
                
            else:
                # Classification case
                probabilities = self.best_model.predict_proba(processed_features)[0]
                prediction_encoded = self.best_model.predict(processed_features)[0]

                # Debug: log raw classification outputs
                try:
                    le_classes = getattr(self.label_encoder, 'classes_', None)
                except Exception:
                    le_classes = None
                self.logger.debug({
                    'prediction_encoded': prediction_encoded,
                    'probabilities': probabilities.tolist() if hasattr(probabilities, 'tolist') else list(probabilities),
                    'label_encoder_classes': le_classes
                })
                
                # Safe decoding: use inverse_transform if available; otherwise try sensible fallbacks
                decoded_prediction = None
                try:
                    if self.label_encoder is not None and hasattr(self.label_encoder, "inverse_transform"):
                        decoded_prediction = self.label_encoder.inverse_transform([prediction_encoded])[0]
                    else:
                        # If label_encoder is a raw classes array/list, try indexing or matching
                        if isinstance(self.label_encoder, (list, tuple)) or (hasattr(self.label_encoder, "__array__") and not hasattr(self.label_encoder, "inverse_transform")):
                            classes = list(self.label_encoder)
                            try:
                                decoded_prediction = classes[int(prediction_encoded)]
                            except Exception:
                                decoded_prediction = prediction_encoded if prediction_encoded in classes else prediction_encoded
                        else:
                            decoded_prediction = prediction_encoded
                except Exception as _e:
                    self.logger.warning(f"Could not inverse_transform prediction ({_e}); falling back to raw encoded value.")
                    decoded_prediction = prediction_encoded

                # Map decoded_prediction to numeric float (as before)
                try:
                    prediction = float(decoded_prediction)
                except (ValueError, TypeError):
                    # fallback string->numeric mapping
                    prediction_map = {'Bad': 4.0, 'Average': 5.0, 'Good': 7.0, 'Excellent': 8.0}
                    if isinstance(decoded_prediction, str):
                        prediction = float(prediction_map.get(decoded_prediction, 4.0))
                    else:
                        prediction = 4.0
                
                # Get confidence from probabilities
                confidence = float(max(probabilities))
                
                # For multi-class, calculate probability of good quality (>=6)
                try:
                    if self.label_encoder is not None and hasattr(self.label_encoder, "classes_"):
                        good_indices = [i for i, label in enumerate(self.label_encoder.classes_) 
                                     if (isinstance(label, (int, float)) and float(label) >= 6) or
                                        (isinstance(label, str) and label in ['Good', 'Excellent'])]
                    else:
                        good_indices = [i for i in range(len(probabilities)) if i >= 6]
                    probability_good = float(sum(probabilities[i] for i in good_indices))
                except (ValueError, TypeError):
                    # Fallback for categorical labels
                    probability_good = float(probabilities[-1]) if len(probabilities) > 1 else 0.0
            
            # Create quality label based on prediction
            if prediction >= 8:
                quality_label = "Excellent"
            elif prediction >= 6.5:
                quality_label = "Above Average"
            elif prediction >= 5:
                quality_label = "Average"
            else:
                quality_label = "Below Average"
            
            result = {
                "prediction": prediction,
                "confidence": confidence,
                "probability_good": probability_good,
                "quality_label": quality_label,
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
            
            # Convert features to DataFrame - ensure order consistent with training
            expected_features = [
                'fixed acidity', 'volatile acidity', 'citric acid',
                'residual sugar', 'chlorides', 'free sulfur dioxide',
                'total sulfur dioxide', 'density', 'pH', 'sulphates', 'alcohol'
            ]
            feature_values = [model_features.get(feat, 0.0) for feat in expected_features]
            feature_df = pd.DataFrame([feature_values], columns=expected_features)
            
            # Scale features (defensive)
            if self.scaler is None:
                raise ValueError("Scaler not loaded")
            if isinstance(self.scaler, np.ndarray):
                self.logger.warning(
                    "Scaler appears to be a numpy.ndarray (likely saved incorrectly). "
                    "Skipping scaler.transform and using raw feature_df for predictions."
                )
                scaled_features = feature_df
            else:
                scaled_features = self.scaler.transform(feature_df)
            
            for model_name, model in self.all_models.items():
                try:
                    # Make prediction
                    prediction_encoded = model.predict(scaled_features)[0]
                    probabilities = model.predict_proba(scaled_features)[0]
                    
                    # Decode prediction (defensive)
                    try:
                        if self.label_encoder is not None and hasattr(self.label_encoder, "inverse_transform"):
                            prediction = self.label_encoder.inverse_transform([prediction_encoded])[0]
                        else:
                            classes = list(self.label_encoder) if self.label_encoder is not None else None
                            if classes:
                                try:
                                    prediction = classes[int(prediction_encoded)]
                                except Exception:
                                    prediction = prediction_encoded if prediction_encoded in classes else prediction_encoded
                            else:
                                prediction = prediction_encoded
                    except Exception as e:
                        self.logger.warning(f"Error decoding label for model {model_name}: {e}")
                        prediction = "Unknown"
                    
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
        ...
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


def run_model_and_get_raw(input_json: dict) -> dict:
    """
    Run the model on the provided input and return raw internal outputs for debugging.

    This function is defensive: it catches exceptions and returns them as strings so
    it never raises and never crashes the API.
    """
    import numpy as np
    results: dict = {}
    try:
        predictor = get_ml_predictor()

        results['model_info'] = {
            'best_model_loaded': predictor.best_model is not None,
            'scaler_loaded': predictor.scaler is not None,
            'label_encoder_loaded': predictor.label_encoder is not None
        }

        # Prepare input like predict()
        model_features = predictor._convert_feature_names(input_json)
        expected_features = [
            'fixed acidity', 'volatile acidity', 'citric acid',
            'residual sugar', 'chlorides', 'free sulfur dioxide',
            'total sulfur dioxide', 'density', 'pH', 'sulphates', 'alcohol'
        ]
        feature_values = [model_features.get(feat, 0.0) for feat in expected_features]
        feature_df = __import__('pandas').DataFrame([feature_values], columns=expected_features)

        model = predictor.best_model
        if model is None:
            results['error'] = 'No model loaded'
            return results

        is_pipeline = hasattr(model, 'steps')
        has_preprocessor = hasattr(model, 'named_steps') and any(
            step for step in getattr(model, 'named_steps', {}).keys()
            if 'preprocessor' in step or 'scaler' in step
        )

        results['is_pipeline'] = bool(is_pipeline)
        results['has_preprocessor'] = bool(has_preprocessor)

        # Preprocess features with same defensive logic
        try:
            if is_pipeline and has_preprocessor:
                processed = feature_df
            else:
                if predictor.scaler is None:
                    raise ValueError('Scaler not loaded')
                if isinstance(predictor.scaler, np.ndarray):
                    predictor.logger.warning("Scaler is ndarray in debug_raw; skipping transform.")
                    processed = feature_df
                else:
                    processed = predictor.scaler.transform(feature_df)
            results['processed_shape'] = getattr(processed, 'shape', None)
        except Exception as e:
            results['preprocessing_error'] = str(e)
            processed = feature_df

        # Final estimator
        try:
            final_estimator = model.named_steps['classifier'] if is_pipeline else model
        except Exception:
            final_estimator = model

        results['final_estimator_type'] = type(final_estimator).__name__

        # Try regressor predict
        try:
            reg_pred = model.predict(processed)
            results['regressor_prediction'] = [float(x) for x in np.atleast_1d(reg_pred)]
        except Exception as e:
            results['regressor_prediction_error'] = str(e)

        # Try classifier predict/proba
        clf_pred = None
        proba = None
        try:
            clf_pred = model.predict(processed)
            results['classifier_prediction_encoded'] = [str(x) for x in np.atleast_1d(clf_pred)]
        except Exception as e:
            results['classifier_prediction_error'] = str(e)

        try:
            proba_raw = model.predict_proba(processed)
            # convert to list of lists
            results['probabilities'] = [list(map(float, row)) for row in np.atleast_2d(proba_raw)]
            proba = np.atleast_2d(proba_raw)
        except Exception as e:
            results['probabilities_error'] = str(e)

        # Label encoder info and decoded labels
        try:
            le = predictor.label_encoder
            if le is not None and hasattr(le, 'classes_'):
                try:
                    results['label_encoder_classes'] = list(getattr(le, 'classes_'))
                except Exception as e:
                    results['label_encoder_classes_error'] = str(e)
            else:
                results['label_encoder_classes'] = None
        except Exception as e:
            results['label_encoder_error'] = str(e)

        try:
            decoded = []
            if 'classifier_prediction_encoded' in results and results['classifier_prediction_encoded'] is not None:
                for p in results['classifier_prediction_encoded']:
                    try:
                        if predictor.label_encoder is not None and hasattr(predictor.label_encoder, "inverse_transform"):
                            decoded_val = predictor.label_encoder.inverse_transform([p])[0]
                        else:
                            # fallback if label_encoder is array/list
                            classes = list(predictor.label_encoder) if predictor.label_encoder is not None else None
                            if classes:
                                try:
                                    decoded_val = classes[int(p)]
                                except Exception:
                                    decoded_val = p if p in classes else p
                            else:
                                decoded_val = p
                        decoded.append(decoded_val)
                    except Exception:
                        decoded.append(str(p))
            results['decoded_labels'] = decoded
        except Exception as e:
            results['decoded_labels_error'] = str(e)

        # Mapped numeric to return (attempt to mirror predict() mapping)
        try:
            mapped = None
            # If classifier prediction present, map it
            if 'classifier_prediction_encoded' in results and results['classifier_prediction_encoded']:
                # take first prediction / probability row
                enc = results['classifier_prediction_encoded'][0]
                # try numeric
                try:
                    mapped = float(enc)
                except Exception:
                    # string mapping
                    mapping = {'Bad': 4.0, 'Average': 5.0, 'Good': 7.0, 'Excellent': 8.0}
                    mapped = mapping.get(str(enc), 4.0)
            elif 'regressor_prediction' in results and results['regressor_prediction']:
                # round and clamp like predict()
                val = float(results['regressor_prediction'][0])
                mapped = max(3, min(9, round(val)))
            results['mapped_numeric_to_return'] = mapped
        except Exception as e:
            results['mapped_numeric_error'] = str(e)

        results['input_sample'] = input_json

    except Exception as e:
        results['error'] = str(e)

    logger.debug(f"DEBUG RAW OUTPUT: {results}")
    return results
