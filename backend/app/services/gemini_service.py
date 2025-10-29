"""
Gemini AI Service for Wine Quality Prediction.
Provides AI-generated explanations for wine quality predictions.
"""

import os
import time
from typing import Dict, Optional, Any
import logging
from datetime import datetime

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logging.warning("google-generativeai not available. Gemini service will be disabled.")

from ..utils.logger import get_logger, log_errors, LoggerMixin

logger = get_logger(__name__)


class GeminiService(LoggerMixin):
    """
    Service for generating AI explanations using Google's Gemini API.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Gemini service.
        
        Args:
            api_key: Gemini API key. If None, will try to get from environment.
        """
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        self.model = None
        self.is_available = False
        
        if GEMINI_AVAILABLE and self.api_key:
            self._initialize_gemini()
        else:
            if not GEMINI_AVAILABLE:
                self.logger.warning("Gemini library not available. Install with: pip install google-generativeai")
            if not self.api_key:
                self.logger.warning("GEMINI_API_KEY not found in environment variables")
    
    @log_errors
    def _initialize_gemini(self) -> None:
        """Initialize Gemini API client."""
        try:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel('gemini-2.5-flash')
            
            # Test the connection
            test_response = self.model.generate_content("Hello")
            if test_response and test_response.text:
                self.is_available = True
                self.logger.info("Gemini API initialized successfully")
            else:
                self.logger.error("Gemini API test failed")
                
        except Exception as e:
            self.logger.error(f"Failed to initialize Gemini API: {str(e)}")
            self.is_available = False
    
    @log_errors
    def get_wine_explanation(
        self, 
        wine_features: Dict[str, float], 
        prediction: str, 
        confidence: float
    ) -> str:
        """
        Generate AI explanation for wine quality prediction.
        
        Args:
            wine_features: Dictionary of wine features
            prediction: Predicted quality (Good/Bad)
            confidence: Prediction confidence score
            
        Returns:
            AI-generated explanation text
        """
        if not self.is_available:
            return self._get_fallback_explanation(wine_features, prediction, confidence)
        
        try:
            # Create feature description
            feature_desc = self._format_features(wine_features)
            
            # Create prompt
            prompt = self._create_explanation_prompt(feature_desc, prediction, confidence)
            
            # Generate response with retry logic
            response = self._generate_with_retry(prompt)
            
            if response and response.text:
                explanation = response.text.strip()
                self.logger.info("Gemini explanation generated successfully")
                return explanation
            else:
                self.logger.warning("Empty response from Gemini API")
                return self._get_fallback_explanation(wine_features, prediction, confidence)
                
        except Exception as e:
            self.logger.error(f"Error generating Gemini explanation: {str(e)}")
            return self._get_fallback_explanation(wine_features, prediction, confidence)
    
    @log_errors
    def _generate_with_retry(self, prompt: str, max_retries: int = 3) -> Optional[Any]:
        """
        Generate content with retry logic and exponential backoff.
        
        Args:
            prompt: Input prompt
            max_retries: Maximum number of retry attempts
            
        Returns:
            Generated response or None
        """
        for attempt in range(max_retries):
            try:
                response = self.model.generate_content(prompt)
                return response
                
            except Exception as e:
                self.logger.warning(f"Gemini API attempt {attempt + 1} failed: {str(e)}")
                
                if attempt < max_retries - 1:
                    # Exponential backoff
                    wait_time = 2 ** attempt
                    time.sleep(wait_time)
                else:
                    self.logger.error(f"All {max_retries} Gemini API attempts failed")
                    raise
        
        return None
    
    def _format_features(self, wine_features: Dict[str, float]) -> str:
        """
        Format wine features for the prompt.
        
        Args:
            wine_features: Dictionary of wine features
            
        Returns:
            Formatted feature string
        """
        feature_descriptions = {
            'fixed_acidity': 'Fixed Acidity',
            'volatile_acidity': 'Volatile Acidity', 
            'citric_acid': 'Citric Acid',
            'residual_sugar': 'Residual Sugar',
            'chlorides': 'Chlorides',
            'free_sulfur_dioxide': 'Free Sulfur Dioxide',
            'total_sulfur_dioxide': 'Total Sulfur Dioxide',
            'density': 'Density',
            'ph': 'pH',
            'sulphates': 'Sulphates',
            'alcohol': 'Alcohol Content'
        }
        
        formatted_features = []
        for feature, value in wine_features.items():
            display_name = feature_descriptions.get(feature, feature.replace('_', ' ').title())
            formatted_features.append(f"{display_name}: {value}")
        
        return ", ".join(formatted_features)
    
    def _create_explanation_prompt(
        self, 
        feature_desc: str, 
        prediction: str, 
        confidence: float
    ) -> str:
        """
        Create the prompt for Gemini explanation.
        
        Args:
            feature_desc: Formatted feature description
            prediction: Predicted quality
            confidence: Confidence score
            
        Returns:
            Formatted prompt string
        """
        confidence_percent = int(confidence * 100)
        
        prompt = f"""
        You are a wine expert analyzing wine quality based on chemical composition. 
        Wine Features: {feature_desc}
        Predicted Quality: {prediction}
        Confidence: {confidence_percent}%
        
        Please provide a brief, professional explanation (3-4 sentences) about this wine's quality prediction. 
        Focus on:
        1. The key chemical factors that influenced this prediction
        2. What these values mean for wine quality
        3. General characteristics of wines with this quality level
        
        Keep the explanation accessible to wine enthusiasts, not just experts.
        """
        
        return prompt.strip()
    
    def _get_fallback_explanation(
        self, 
        wine_features: Dict[str, float], 
        prediction: str, 
        confidence: float
    ) -> str:
        """
        Generate a fallback explanation when Gemini API is not available.
        
        Args:
            wine_features: Dictionary of wine features
            prediction: Predicted quality
            confidence: Confidence score
            
        Returns:
            Fallback explanation text
        """
        confidence_percent = int(confidence * 100)
        
        acidity = wine_features.get('fixed_acidity', 0)
        alcohol = wine_features.get('alcohol', 0)
        ph = wine_features.get('ph', 0)
        
        # Convert prediction to string if it's a float
        pred_str = str(prediction)
        is_good = False
        try:
            # Try to convert to float and compare
            pred_float = float(pred_str)
            is_good = pred_float >= 6.0
        except ValueError:
            # If it's already a string like 'good' or 'bad'
            is_good = pred_str.lower() == 'good'
        
        if is_good:
            quality_desc = "high-quality"
            alcohol_note = "good alcohol content" if alcohol > 12 else "moderate alcohol content"
        else:
            quality_desc = "lower-quality"
            alcohol_note = "low alcohol content" if alcohol < 10 else "moderate alcohol content"
        
        explanation = (
            f"Based on the chemical analysis, this wine is predicted to be of {quality_desc} "
            f"with {confidence_percent}% confidence. The wine shows {alcohol_note} "
            f"and typical acidity levels. {quality_desc.title()} wines generally exhibit "
            f"balanced chemical composition and are well-suited for consumption."
        )
        
        self.logger.info("Using fallback explanation (Gemini API not available)")
        return explanation
    
    @log_errors
    def test_connection(self) -> Dict[str, Any]:
        """
        Test Gemini API connection.
        
        Returns:
            Dictionary with connection status and info
        """
        if not GEMINI_AVAILABLE:
            return {
                "available": False,
                "error": "Gemini library not installed",
                "message": "Install with: pip install google-generativeai"
            }
        
        if not self.api_key:
            return {
                "available": False,
                "error": "API key not configured",
                "message": "Set GEMINI_API_KEY environment variable"
            }
        
        if not self.is_available:
            return {
                "available": False,
                "error": "API initialization failed",
                "message": "Check API key and network connection"
            }
        
        try:
            test_response = self.model.generate_content("Say hello")
            if test_response and test_response.text:
                return {
                    "available": True,
                    "message": "Gemini API connection successful",
                    "test_response": test_response.text[:100] + "..." if len(test_response.text) > 100 else test_response.text
                }
            else:
                return {
                    "available": False,
                    "error": "Empty response from API",
                    "message": "API may be experiencing issues"
                }
                
        except Exception as e:
            return {
                "available": False,
                "error": str(e),
                "message": "API test failed"
            }


# Global instance
gemini_service = None


def get_gemini_service() -> GeminiService:
    global gemini_service
    if gemini_service is None:
        gemini_service = GeminiService()
    return gemini_service


def initialize_gemini_service() -> bool:
    try:
        global gemini_service
        gemini_service = GeminiService()
        logger.info("Gemini service initialized")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize Gemini service: {str(e)}")
        return False