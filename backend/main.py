"""
FastAPI main application for Wine Quality Prediction API.
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.openapi.utils import get_openapi
import logging
import os
from datetime import datetime
from contextlib import asynccontextmanager

from .utils.logger import get_logger, setup_logging
from .services.ml_service import initialize_ml_predictor
from .services.gemini_service import initialize_gemini_service
from .routes.prediction import router as prediction_router

# Setup logging
setup_logging(os.getenv("LOG_LEVEL", "INFO"))
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager for startup and shutdown events.
    """
    # Startup
    logger.info("Starting Wine Quality Prediction API...")
    
    # Initialize ML predictor - FIX: Don't raise error if it fails
    ml_success = initialize_ml_predictor()
    if not ml_success:
        logger.error("Failed to initialize ML predictor - API will run with limited functionality")
        # Don't raise - let the API start anyway
    else:
        logger.info("ML predictor initialized successfully")
    
    # Initialize Gemini service
    gemini_success = initialize_gemini_service()
    if not gemini_success:
        logger.warning("Gemini service initialization failed - AI explanations will use fallback")
    
    # Test services - FIX: Don't crash if services fail
    try:
        from .services.ml_service import get_ml_predictor
        from .services.gemini_service import get_gemini_service
        
        ml_predictor = get_ml_predictor()
        if ml_predictor:
            model_info = ml_predictor.get_model_info()
            logger.info(f"ML predictor ready: {model_info}")
        
        gemini_service = get_gemini_service()
        if gemini_service:
            gemini_test = gemini_service.test_connection()
            logger.info(f"Gemini service status: {gemini_test}")
        
    except Exception as e:
        logger.error(f"Service testing failed: {str(e)}")
        # Don't raise - let the API start anyway
    
    logger.info("Wine Quality Prediction API started successfully!")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Wine Quality Prediction API...")


# Create FastAPI app
app = FastAPI(
    title="🍷 Wine Quality Prediction API",
    description="""
    A machine learning API for predicting wine quality based on chemical composition.
    
    ## Features
    
    * **Wine Quality Prediction**: Predict wine quality (Good/Bad) based on 11 chemical features
    * **Model Comparison**: Compare predictions across multiple ML models
    * **AI Explanations**: Get AI-generated explanations using Google's Gemini API
    * **Health Monitoring**: Check API and model status
    
    ## Wine Features
    
    The API accepts 11 chemical features:
    - Fixed Acidity, Volatile Acidity, Citric Acid
    - Residual Sugar, Chlorides
    - Free Sulfur Dioxide, Total Sulfur Dioxide
    - Density, pH, Sulphates, Alcohol Content
    
    ## Models
    
    The API uses multiple machine learning models including:
    - Random Forest (Best Model)
    - Logistic Regression
    - XGBoost
    - Support Vector Machine
    - And more...
    """,
    version="1.0.0",
    contact={
        "name": "Wine Quality Prediction API",
        "email": "support@wineprediction.com",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    lifespan=lifespan
)

# FIX: Add CORS middleware BEFORE including routers
# This ensures CORS headers are added to ALL responses including errors
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],  # Specific origins
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Include routers AFTER CORS middleware
app.include_router(prediction_router, prefix="/api/v1")


@app.get("/", tags=["root"])
async def root():
    """
    Root endpoint with API information.
    """
    return {
        "message": "🍷 Welcome to Wine Quality Prediction API",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "endpoints": {
            "docs": "/docs",
            "redoc": "/redoc",
            "health": "/api/v1/prediction/health",
            "predict": "/api/v1/prediction/predict",
            "compare": "/api/v1/prediction/predict/compare"
        },
        "features": [
            "Wine quality prediction",
            "Model comparison",
            "AI explanations",
            "Health monitoring"
        ]
    }


@app.get("/health", tags=["health"])
async def health():
    """
    Simple health check endpoint.
    """
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "service": "Wine Quality Prediction API"
    }


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """
    Global HTTP exception handler.
    FIX: Ensure CORS headers are included in error responses
    """
    logger.warning(f"HTTP {exc.status_code} error: {exc.detail} for {request.url}")
    
    response = JSONResponse(
        status_code=exc.status_code,
        content={
            "error": "HTTPException",
            "message": exc.detail,
            "status_code": exc.status_code,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "path": str(request.url)
        }
    )
    
    # FIX: Manually add CORS headers to error responses
    response.headers["Access-Control-Allow-Origin"] = request.headers.get("origin", "http://localhost:3000")
    response.headers["Access-Control-Allow-Credentials"] = "true"
    
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Global exception handler for unhandled exceptions.
    FIX: Ensure CORS headers are included in error responses
    """
    logger.error(f"Unhandled exception: {str(exc)} for {request.url}", exc_info=True)
    
    response = JSONResponse(
        status_code=500,
        content={
            "error": "InternalServerError",
            "message": "An internal server error occurred. Check server logs for details.",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "path": str(request.url),
            "details": str(exc) if os.getenv("ENVIRONMENT") == "development" else None
        }
    )
    
    # FIX: Manually add CORS headers to error responses
    response.headers["Access-Control-Allow-Origin"] = request.headers.get("origin", "http://localhost:3000")
    response.headers["Access-Control-Allow-Credentials"] = "true"
    
    return response


def custom_openapi():
    """
    Custom OpenAPI schema with additional information.
    """
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="🍷 Wine Quality Prediction API",
        version="1.0.0",
        description=app.description,
        routes=app.routes,
    )
    
    # Add custom information
    openapi_schema["info"]["x-logo"] = {
        "url": "https://fastapi.tiangolo.com/img/logo-margin/logo-teal.png"
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi


if __name__ == "__main__":
    import uvicorn
    
    # Get configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    reload = os.getenv("ENVIRONMENT", "development") == "development"
    
    logger.info(f"Starting server on {host}:{port}")
    
    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info"
    )