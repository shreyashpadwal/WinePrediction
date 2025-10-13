"""
Custom exception classes and error handlers for the Wine Quality Prediction API.
"""

from typing import Any, Dict, Optional
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class WinePredictionError(Exception):
    """Base exception for wine prediction errors."""
    
    def __init__(self, message: str, error_code: str = "WINE_PREDICTION_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(self.message)


class ModelNotLoadedError(WinePredictionError):
    """Raised when ML model is not loaded."""
    
    def __init__(self, message: str = "ML model is not loaded"):
        super().__init__(message, "MODEL_NOT_LOADED")


class InvalidWineDataError(WinePredictionError):
    """Raised when wine data is invalid."""
    
    def __init__(self, message: str = "Invalid wine data provided"):
        super().__init__(message, "INVALID_WINE_DATA")


class GeminiAPIError(WinePredictionError):
    """Raised when Gemini API fails."""
    
    def __init__(self, message: str = "Gemini API error"):
        super().__init__(message, "GEMINI_API_ERROR")


class ValidationError(WinePredictionError):
    """Raised when validation fails."""
    
    def __init__(self, message: str = "Validation error"):
        super().__init__(message, "VALIDATION_ERROR")


def create_error_response(
    error: Exception,
    status_code: int = 500,
    request_id: Optional[str] = None
) -> JSONResponse:
    """
    Create standardized error response.
    
    Args:
        error: Exception instance
        status_code: HTTP status code
        request_id: Optional request ID for tracking
        
    Returns:
        JSONResponse with error details
    """
    error_data = {
        "error": error.__class__.__name__,
        "message": str(error),
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "status_code": status_code
    }
    
    if request_id:
        error_data["request_id"] = request_id
    
    if hasattr(error, 'error_code'):
        error_data["error_code"] = error.error_code
    
    return JSONResponse(
        status_code=status_code,
        content=error_data
    )


async def wine_prediction_error_handler(request: Request, exc: WinePredictionError) -> JSONResponse:
    """Handle custom wine prediction errors."""
    logger.error(f"Wine prediction error: {exc.message}", extra={
        "error_code": exc.error_code,
        "path": str(request.url),
        "method": request.method
    })
    
    status_code = 400
    if isinstance(exc, ModelNotLoadedError):
        status_code = 503
    elif isinstance(exc, GeminiAPIError):
        status_code = 502
    
    return create_error_response(exc, status_code)


async def validation_error_handler(request: Request, exc: ValidationError) -> JSONResponse:
    """Handle validation errors."""
    logger.warning(f"Validation error: {exc.message}", extra={
        "path": str(request.url),
        "method": request.method
    })
    
    return create_error_response(exc, 422)


async def generic_error_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle generic exceptions."""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True, extra={
        "path": str(request.url),
        "method": request.method
    })
    
    return create_error_response(exc, 500)


def handle_model_loading_error(error: Exception) -> None:
    """Handle model loading errors with proper logging."""
    logger.error(f"Model loading failed: {str(error)}", exc_info=True)
    raise ModelNotLoadedError(f"Failed to load ML model: {str(error)}")


def handle_prediction_error(error: Exception) -> None:
    """Handle prediction errors with proper logging."""
    logger.error(f"Prediction failed: {str(error)}", exc_info=True)
    raise WinePredictionError(f"Prediction failed: {str(error)}")


def handle_gemini_error(error: Exception) -> None:
    """Handle Gemini API errors with proper logging."""
    logger.warning(f"Gemini API error: {str(error)}")
    raise GeminiAPIError(f"AI explanation unavailable: {str(error)}")


def validate_wine_features(features: Dict[str, Any]) -> None:
    """
    Validate wine features with detailed error messages.
    
    Args:
        features: Dictionary of wine features
        
    Raises:
        ValidationError: If validation fails
    """
    required_features = [
        'fixed_acidity', 'volatile_acidity', 'citric_acid', 'residual_sugar',
        'chlorides', 'free_sulfur_dioxide', 'total_sulfur_dioxide',
        'density', 'ph', 'sulphates', 'alcohol'
    ]
    
    # Check for missing features
    missing_features = [f for f in required_features if f not in features]
    if missing_features:
        raise ValidationError(f"Missing required features: {', '.join(missing_features)}")
    
    # Check for extra features
    extra_features = [f for f in features.keys() if f not in required_features]
    if extra_features:
        raise ValidationError(f"Unexpected features: {', '.join(extra_features)}")
    
    # Validate feature values
    for feature, value in features.items():
        if not isinstance(value, (int, float)):
            raise ValidationError(f"Feature '{feature}' must be numeric, got {type(value).__name__}")
        
        if value is None:
            raise ValidationError(f"Feature '{feature}' cannot be null")
        
        # Check for NaN or infinite values
        try:
            if float(value) != float(value):  # NaN check
                raise ValidationError(f"Feature '{feature}' has invalid value (NaN)")
            if abs(float(value)) == float('inf'):
                raise ValidationError(f"Feature '{feature}' has infinite value")
        except (ValueError, TypeError):
            raise ValidationError(f"Feature '{feature}' has invalid numeric value: {value}")


def check_so2_relationship(features: Dict[str, Any]) -> None:
    """
    Check SO2 relationship (total >= free).
    
    Args:
        features: Dictionary of wine features
        
    Raises:
        ValidationError: If SO2 relationship is invalid
    """
    free_so2 = features.get('free_sulfur_dioxide', 0)
    total_so2 = features.get('total_sulfur_dioxide', 0)
    
    if total_so2 < free_so2:
        raise ValidationError(
            f"Total sulfur dioxide ({total_so2}) must be >= free sulfur dioxide ({free_so2})"
        )
