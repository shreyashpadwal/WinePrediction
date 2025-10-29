"""
FastAPI routes for wine quality prediction endpoints.
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import Dict, Any
import logging
from datetime import datetime
import numpy as np  # added for type checks

from ..utils.validators import (
    WineFeatures, 
    PredictionResponse, 
    ComparisonResponse, 
    HealthResponse,
    ErrorResponse
)
from ..services.ml_service import get_ml_predictor, MLPredictor
from ..services.gemini_service import get_gemini_service, GeminiService
from ..utils.logger import get_logger
from ..services.ml_service import run_model_and_get_raw

logger = get_logger(__name__)

# Create router
router = APIRouter(prefix="/prediction", tags=["prediction"])


def _find_transformer(predictor) -> tuple:
    """
    Try to find a transformer (scaler/preprocessor/pipeline) inside the predictor object.

    Returns:
        (transformer_obj, attribute_name) if found else (None, None)
    """
    candidate_names = ["scaler", "preprocessor", "pipeline", "transformer", "preprocess"]
    for name in candidate_names:
        obj = getattr(predictor, name, None)
        if obj is not None:
            if hasattr(obj, "transform"):
                return obj, name
            # if it's an ndarray, return it to let caller produce a better error
            if isinstance(obj, np.ndarray):
                return obj, name

    # fallback: scan attributes for anything with a transform method
    for attr in dir(predictor):
        if attr.startswith("_"):
            continue
        try:
            obj = getattr(predictor, attr)
            if hasattr(obj, "transform"):
                return obj, attr
        except Exception:
            continue

    # nothing found
    return None, None


@router.post("/predict", response_model=PredictionResponse)
async def predict_wine_quality(
    wine_features: WineFeatures,
    request: Request
) -> PredictionResponse:
    """
    Predict wine quality based on chemical features.
    
    Args:
        wine_features: Wine chemical composition features
        request: FastAPI request object
        
    Returns:
        Prediction result with confidence and AI explanation
    """
    try:
        logger.info(f"Prediction request received: {id(request)}")
        
        # Get services
        ml_predictor = get_ml_predictor()
        gemini_service = get_gemini_service()
        
        # Convert Pydantic model to dict
        features_dict = wine_features.dict()
        logger.debug(f"Features: {features_dict}")
        
        # Validate features
        is_valid, error_msg = ml_predictor.validate_features(features_dict)
        if not is_valid:
            logger.warning(f"Invalid features provided: {error_msg}")
            raise HTTPException(status_code=400, detail=error_msg)

        # Defensive check: ensure the predictor has a transformer with transform()
        transformer, attr_name = _find_transformer(ml_predictor)
        if transformer is None:
            logger.error("No transformer (scaler/preprocessor/pipeline) found on ml_predictor. "
                         "This typically means the scaler was not loaded or was accidentally saved as a numpy array.")
            # Provide actionable message to user/dev
            raise HTTPException(
                status_code=500,
                detail=("Server configuration error: preprocessor/scaler not found. "
                        "Check that the scaler was saved with pickle/joblib and loaded correctly in ml_service.")
            )

        # If transformer exists but is ndarray, produce explicit error
        if isinstance(transformer, np.ndarray):
            logger.error("Transformer attribute '%s' is a numpy.ndarray (shape=%s). "
                         "Expected a transformer object with a .transform() method (e.g., sklearn StandardScaler).",
                         attr_name, getattr(transformer, "shape", "unknown"))
            raise HTTPException(
                status_code=500,
                detail=(f"Server error: transformer '{attr_name}' is loaded as a numpy.ndarray. "
                        "This happens when the transformer was saved incorrectly (e.g. using np.save). "
                        "Re-save the scaler with pickle.dump or joblib.dump and restart the server.")
            )

        # Log the transformer info for debugging
        logger.debug("Using transformer '%s' of type %s for preprocessing", attr_name, type(transformer))

        # Make prediction
        prediction_result = ml_predictor.predict(features_dict)
        logger.debug(f"Prediction result: {prediction_result}")
        
        # Get AI explanation
        gemini_insight = None
        try:
            gemini_insight = gemini_service.get_wine_explanation(
                features_dict,
                prediction_result["prediction"],
                prediction_result["confidence"]
            )
        except Exception as e:
            logger.warning(f"Failed to get Gemini explanation: {str(e)}")
            # Continue without AI explanation
        
        # Create response
        response = PredictionResponse(
            prediction=str(prediction_result["prediction"]),  # Always string
            confidence=prediction_result["confidence"],
            probability_good=prediction_result["probability_good"],
            quality_label=prediction_result["quality_label"],
            gemini_insight=gemini_insight,
            timestamp=datetime.utcnow().isoformat() + "Z",
            model_used=prediction_result["model_used"]
        )
        
        # Log prediction
        logger.info(
            f"Prediction made: {prediction_result['prediction']} "
            f"(confidence: {prediction_result['confidence']:.3f}) "
            f"for request {id(request)}"
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in prediction endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error during prediction: {str(e)}")


@router.post("/debug-raw")
async def prediction_debug_raw(wine_features: WineFeatures):
    """Return raw model outputs for debugging (no Pydantic output validation)."""
    try:
        body = wine_features.dict()
        result = run_model_and_get_raw(body)
        return result
    except Exception as e:
        # Never raise - return error string for debugging
        return {"error": str(e)}


@router.post("/predict/compare", response_model=ComparisonResponse)
async def compare_models_prediction(
    wine_features: WineFeatures,
    request: Request
) -> ComparisonResponse:
    """
    Get predictions from all available models for comparison.
    
    Args:
        wine_features: Wine chemical composition features
        request: FastAPI request object
        
    Returns:
        Comparison of predictions from all models
    """
    try:
        logger.info(f"Model comparison request received: {id(request)}")
        
        # Get ML predictor
        ml_predictor = get_ml_predictor()
        
        # Convert Pydantic model to dict
        features_dict = wine_features.dict()
        logger.debug(f"Features: {features_dict}")
        
        # Validate features
        is_valid, error_msg = ml_predictor.validate_features(features_dict)
        if not is_valid:
            logger.warning(f"Invalid features provided: {error_msg}")
            raise HTTPException(status_code=400, detail=error_msg)

        # Defensive check: ensure the predictor has a transformer with transform()
        transformer, attr_name = _find_transformer(ml_predictor)
        if transformer is None:
            logger.error("No transformer (scaler/preprocessor/pipeline) found on ml_predictor for comparison endpoint.")
            raise HTTPException(
                status_code=500,
                detail=("Server configuration error: preprocessor/scaler not found for comparison endpoint. "
                        "Check that the scaler was saved with pickle/joblib and loaded correctly in ml_service.")
            )

        if isinstance(transformer, np.ndarray):
            logger.error("Transformer attribute '%s' is a numpy.ndarray (shape=%s) in comparison endpoint.",
                         attr_name, getattr(transformer, "shape", "unknown"))
            raise HTTPException(
                status_code=500,
                detail=(f"Server error: transformer '{attr_name}' is loaded as a numpy.ndarray for comparison endpoint. "
                        "Re-save the scaler with pickle.dump or joblib.dump and restart the server.")
            )

        logger.debug("Using transformer '%s' of type %s for preprocessing (comparison endpoint)", attr_name, type(transformer))
        
        # Get predictions from all models
        all_predictions = ml_predictor.get_all_predictions(features_dict)
        logger.debug(f"Got {len(all_predictions)} model predictions")
        
        if not all_predictions:
            raise HTTPException(status_code=500, detail="No model predictions available")
        
        # Calculate consensus
        predictions = [p.prediction for p in all_predictions if p.prediction != "Unknown"]
        if not predictions:
            consensus = "Unknown"
            agreement_count = 0
        else:
            # Find most common prediction
            from collections import Counter
            prediction_counts = Counter(predictions)
            consensus = prediction_counts.most_common(1)[0][0]
            agreement_count = prediction_counts[consensus]
        
        # Create response
        response = ComparisonResponse(
            all_models_results=all_predictions,
            consensus=consensus,
            agreement_count=agreement_count,
            total_models=len(all_predictions),
            timestamp=datetime.utcnow().isoformat() + "Z"
        )
        
        # Log comparison
        logger.info(
            f"Model comparison completed: {consensus} consensus "
            f"({agreement_count}/{len(all_predictions)} models) "
            f"for request {id(request)}"
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in model comparison endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error during model comparison: {str(e)}")


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    Check the health status of the prediction service.
    
    Returns:
        Health status and model information
    """
    try:
        logger.info("Health check requested")
        
        # Get ML predictor
        ml_predictor = get_ml_predictor()
        
        # Get model info
        model_info = ml_predictor.get_model_info()
        logger.debug(f"Model info: {model_info}")
        
        # Determine status
        if model_info.get("best_model_loaded", False):
            status = "healthy"
        else:
            status = "unhealthy"
        
        # Create response
        response = HealthResponse(
            status=status,
            model_loaded=model_info.get("best_model_loaded", False),
            model_info=model_info,
            timestamp=datetime.utcnow().isoformat() + "Z"
        )
        
        logger.info(f"Health check: {status}")
        return response
        
    except Exception as e:
        logger.error(f"Error in health check: {str(e)}", exc_info=True)
        return HealthResponse(
            status="unhealthy",
            model_loaded=False,
            model_info={"error": str(e)},
            timestamp=datetime.utcnow().isoformat() + "Z"
        )


@router.get("/models/info")
async def get_models_info() -> Dict[str, Any]:
    """
    Get detailed information about available models.
    
    Returns:
        Detailed model information
    """
    try:
        logger.info("Model info requested")
        
        # Get ML predictor
        ml_predictor = get_ml_predictor()
        
        # Get model info
        model_info = ml_predictor.get_model_info()
        
        return model_info
        
    except Exception as e:
        logger.error(f"Error getting model info: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error retrieving model information: {str(e)}")


@router.get("/features/info")
async def get_features_info() -> Dict[str, Any]:
    """
    Get information about wine features and their expected ranges.
    
    Returns:
        Feature information and validation ranges
    """
    try:
        logger.info("Feature info requested")
        
        feature_info = {
            "features": [
                {
                    "name": "fixed_acidity",
                    "display_name": "Fixed Acidity",
                    "unit": "g/dm³",
                    "min": 3.0,
                    "max": 16.0,
                    "description": "Fixed acidity in g/dm³"
                },
                {
                    "name": "volatile_acidity",
                    "display_name": "Volatile Acidity",
                    "unit": "g/dm³",
                    "min": 0.0,
                    "max": 2.0,
                    "description": "Volatile acidity in g/dm³"
                },
                {
                    "name": "citric_acid",
                    "display_name": "Citric Acid",
                    "unit": "g/dm³",
                    "min": 0.0,
                    "max": 2.0,
                    "description": "Citric acid in g/dm³"
                },
                {
                    "name": "residual_sugar",
                    "display_name": "Residual Sugar",
                    "unit": "g/dm³",
                    "min": 0.0,
                    "max": 70.0,
                    "description": "Residual sugar in g/dm³"
                },
                {
                    "name": "chlorides",
                    "display_name": "Chlorides",
                    "unit": "g/dm³",
                    "min": 0.0,
                    "max": 1.0,
                    "description": "Chlorides in g/dm³"
                },
                {
                    "name": "free_sulfur_dioxide",
                    "display_name": "Free Sulfur Dioxide",
                    "unit": "mg/dm³",
                    "min": 0.0,
                    "max": 300.0,
                    "description": "Free sulfur dioxide in mg/dm³"
                },
                {
                    "name": "total_sulfur_dioxide",
                    "display_name": "Total Sulfur Dioxide",
                    "unit": "mg/dm³",
                    "min": 0.0,
                    "max": 500.0,
                    "description": "Total sulfur dioxide in mg/dm³"
                },
                {
                    "name": "density",
                    "display_name": "Density",
                    "unit": "g/cm³",
                    "min": 0.98,
                    "max": 1.05,
                    "description": "Density in g/cm³"
                },
                {
                    "name": "pH",
                    "display_name": "pH",
                    "unit": "pH units",
                    "min": 2.5,
                    "max": 4.5,
                    "description": "pH value"
                },
                {
                    "name": "sulphates",
                    "display_name": "Sulphates",
                    "unit": "g/dm³",
                    "min": 0.0,
                    "max": 3.0,
                    "description": "Sulphates in g/dm³"
                },
                {
                    "name": "alcohol",
                    "display_name": "Alcohol Content",
                    "unit": "% vol",
                    "min": 8.0,
                    "max": 16.0,
                    "description": "Alcohol content in % vol"
                }
            ],
            "total_features": 11,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        return feature_info
        
    except Exception as e:
        logger.error(f"Error getting feature info: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error retrieving feature information: {str(e)}")
