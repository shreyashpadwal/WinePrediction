"""
Pydantic models and validators for Wine Quality Prediction API.
Provides input validation and response models with realistic wine chemistry ranges.
"""

from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field, validator
import logging

logger = logging.getLogger(__name__)


class WineFeatures(BaseModel):
    """
    Pydantic model for wine feature validation.
    Includes realistic ranges for wine chemistry parameters.
    """
    fixed_acidity: float = Field(
        ..., 
        ge=3.0, 
        le=16.0, 
        description="Fixed acidity in g/dm³ (typical range: 3.0-16.0)"
    )
    volatile_acidity: float = Field(
        ..., 
        ge=0.0, 
        le=2.0, 
        description="Volatile acidity in g/dm³ (typical range: 0.0-2.0)"
    )
    citric_acid: float = Field(
        ..., 
        ge=0.0, 
        le=2.0, 
        description="Citric acid in g/dm³ (typical range: 0.0-2.0)"
    )
    residual_sugar: float = Field(
        ..., 
        ge=0.0, 
        le=70.0, 
        description="Residual sugar in g/dm³ (typical range: 0.0-70.0)"
    )
    chlorides: float = Field(
        ..., 
        ge=0.0, 
        le=1.0, 
        description="Chlorides in g/dm³ (typical range: 0.0-1.0)"
    )
    free_sulfur_dioxide: float = Field(
        ..., 
        ge=0.0, 
        le=300.0, 
        description="Free sulfur dioxide in mg/dm³ (typical range: 0.0-300.0)"
    )
    total_sulfur_dioxide: float = Field(
        ..., 
        ge=0.0, 
        le=500.0, 
        description="Total sulfur dioxide in mg/dm³ (typical range: 0.0-500.0)"
    )
    density: float = Field(
        ..., 
        ge=0.98, 
        le=1.05, 
        description="Density in g/cm³ (typical range: 0.98-1.05)"
    )
    ph: float = Field(
        ..., 
        ge=2.5, 
        le=4.5, 
        description="pH value (typical range: 2.5-4.5)"
    )
    sulphates: float = Field(
        ..., 
        ge=0.0, 
        le=3.0, 
        description="Sulphates in g/dm³ (typical range: 0.0-3.0)"
    )
    alcohol: float = Field(
        ..., 
        ge=8.0, 
        le=16.0, 
        description="Alcohol content in % vol (typical range: 8.0-16.0)"
    )

    @validator('total_sulfur_dioxide')
    def validate_total_so2(cls, v, values):
        """Validate that total SO2 is greater than or equal to free SO2."""
        if 'free_sulfur_dioxide' in values and v < values['free_sulfur_dioxide']:
            raise ValueError('Total sulfur dioxide must be >= free sulfur dioxide')
        return v

    @validator('ph')
    def validate_ph_realistic(cls, v):
        """Validate pH is within realistic wine range."""
        if v < 2.5 or v > 4.5:
            logger.warning(f"pH value {v} is outside typical wine range (2.5-4.5)")
        return v

    @validator('alcohol')
    def validate_alcohol_content(cls, v):
        """Validate alcohol content is realistic for wine."""
        if v < 8.0 or v > 16.0:
            logger.warning(f"Alcohol content {v}% is outside typical wine range (8-16%)")
        return v

    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
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
        }


class ModelPrediction(BaseModel):
    """Model prediction result."""
    model_name: str = Field(..., description="Name of the ML model")
    prediction: str = Field(..., description="Predicted quality (Good/Bad)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Prediction confidence score")
    probability_good: float = Field(..., ge=0.0, le=1.0, description="Probability of good quality")


class PredictionResponse(BaseModel):
    """Response model for wine quality prediction."""
    prediction: str = Field(..., description="Predicted wine quality (Good/Bad)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Prediction confidence score")
    probability_good: float = Field(..., ge=0.0, le=1.0, description="Probability of good quality")
    gemini_insight: Optional[str] = Field(None, description="AI-generated explanation")
    timestamp: str = Field(..., description="Prediction timestamp")
    model_used: str = Field(..., description="Name of the model used for prediction")
    
    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "prediction": "Good",
                "confidence": 0.85,
                "probability_good": 0.85,
                "gemini_insight": "This wine shows excellent balance with moderate acidity and good alcohol content...",
                "timestamp": "2024-01-15T10:30:00Z",
                "model_used": "Random Forest (Tuned)"
            }
        }


class ComparisonResponse(BaseModel):
    """Response model for model comparison prediction."""
    all_models_results: List[ModelPrediction] = Field(..., description="Predictions from all models")
    consensus: str = Field(..., description="Consensus prediction (Good/Bad/Mixed)")
    agreement_count: int = Field(..., ge=0, description="Number of models agreeing with consensus")
    total_models: int = Field(..., ge=1, description="Total number of models")
    timestamp: str = Field(..., description="Prediction timestamp")
    
    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "all_models_results": [
                    {
                        "model_name": "Random Forest",
                        "prediction": "Good",
                        "confidence": 0.85,
                        "probability_good": 0.85
                    }
                ],
                "consensus": "Good",
                "agreement_count": 4,
                "total_models": 6,
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }


class HealthResponse(BaseModel):
    """Response model for health check endpoint."""
    status: str = Field(..., description="Service status")
    model_loaded: bool = Field(..., description="Whether ML model is loaded")
    model_info: Optional[Dict[str, Any]] = Field(None, description="Model information")
    timestamp: str = Field(..., description="Health check timestamp")
    
    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "status": "healthy",
                "model_loaded": True,
                "model_info": {
                    "model_name": "Random Forest (Tuned)",
                    "accuracy": 0.85,
                    "features_count": 11
                },
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }


class ErrorResponse(BaseModel):
    """Response model for error cases."""
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Error message")
    timestamp: str = Field(..., description="Error timestamp")
    request_id: Optional[str] = Field(None, description="Request ID for tracking")
    
    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "error": "ValidationError",
                "message": "Invalid wine feature values provided",
                "timestamp": "2024-01-15T10:30:00Z",
                "request_id": "req_123456"
            }
        }
