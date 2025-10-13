/**
 * User-friendly error messages for different error scenarios
 */

export const ERROR_MESSAGES = {
  // Network errors
  NETWORK_ERROR: 'Unable to connect to the server. Please check your internet connection.',
  TIMEOUT_ERROR: 'Request timed out. Please try again.',
  CONNECTION_REFUSED: 'Server is not responding. Please check if the backend is running.',
  
  // API errors
  INVALID_DATA: 'Invalid wine data provided. Please check your inputs.',
  SERVER_ERROR: 'Server error occurred. Please try again later.',
  VALIDATION_ERROR: 'Please check your input values and try again.',
  
  // Model errors
  MODEL_NOT_LOADED: 'Machine learning model is not available. Please try again later.',
  PREDICTION_FAILED: 'Failed to generate prediction. Please try again.',
  
  // Gemini AI errors
  GEMINI_UNAVAILABLE: 'AI insights are temporarily unavailable. Prediction completed without explanation.',
  GEMINI_RATE_LIMIT: 'AI service is busy. Please try again in a moment.',
  
  // Generic errors
  UNKNOWN_ERROR: 'An unexpected error occurred. Please try again.',
  RETRY_SUGGESTION: 'Something went wrong. Please try again.',
} as const

export const getErrorMessage = (error: any): string => {
  if (typeof error === 'string') {
    return error
  }
  
  if (error?.message) {
    const message = error.message.toLowerCase()
    
    // Network errors
    if (message.includes('network') || message.includes('connection')) {
      return ERROR_MESSAGES.NETWORK_ERROR
    }
    
    if (message.includes('timeout')) {
      return ERROR_MESSAGES.TIMEOUT_ERROR
    }
    
    if (message.includes('connection refused') || message.includes('econnrefused')) {
      return ERROR_MESSAGES.CONNECTION_REFUSED
    }
    
    // Validation errors
    if (message.includes('validation') || message.includes('invalid')) {
      return ERROR_MESSAGES.VALIDATION_ERROR
    }
    
    // Server errors
    if (message.includes('server') || message.includes('500')) {
      return ERROR_MESSAGES.SERVER_ERROR
    }
    
    // Model errors
    if (message.includes('model') || message.includes('prediction')) {
      return ERROR_MESSAGES.PREDICTION_FAILED
    }
    
    // Gemini errors
    if (message.includes('gemini') || message.includes('ai')) {
      return ERROR_MESSAGES.GEMINI_UNAVAILABLE
    }
    
    return error.message
  }
  
  return ERROR_MESSAGES.UNKNOWN_ERROR
}

export const getRetryMessage = (error: any): string => {
  const message = getErrorMessage(error)
  
  if (message.includes('connection') || message.includes('network')) {
    return 'Check your internet connection and try again.'
  }
  
  if (message.includes('server') || message.includes('timeout')) {
    return 'The server might be busy. Please try again in a moment.'
  }
  
  if (message.includes('validation') || message.includes('invalid')) {
    return 'Please review your input values and try again.'
  }
  
  return 'Please try again.'
}
