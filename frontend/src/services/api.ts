import axios, { AxiosInstance, AxiosResponse } from 'axios'
import { WineFeatures, PredictionResponse, ComparisonResponse, HealthResponse } from '../types/wine'

class ApiService {
  private api: AxiosInstance

  constructor() {
    this.api = axios.create({
      baseURL: 'http://localhost:8000/api/v1',
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
      withCredentials: false,
    })

    // Request interceptor
    this.api.interceptors.request.use(
      (config) => {
        console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`)
        if (config.data) {
          console.log('📦 Request Data:', JSON.stringify(config.data, null, 2))
        }
        return config
      },
      (error) => {
        console.error('❌ Request Error:', error)
        return Promise.reject(error)
      }
    )

    // Response interceptor
    this.api.interceptors.response.use(
      (response: AxiosResponse) => {
        console.log(`✅ API Response: ${response.status} ${response.config.url}`)
        return response
      },
      (error) => {
        // Better error logging
        if (error.response) {
          console.error('❌ Response Error Details:', {
            status: error.response.status,
            statusText: error.response.statusText,
            data: error.response.data,
            url: error.config?.url,
            method: error.config?.method,
            requestData: error.config?.data
          })
        } else if (error.request) {
          console.error('❌ No Response Received:', error.request)
        } else {
          console.error('❌ Request Setup Error:', error.message)
        }
        
        // Handle different error types
        if (error.response?.status === 422) {
          const validationErrors = error.response?.data?.detail || []
          console.error('🔍 Validation Errors:', validationErrors)
          
          if (Array.isArray(validationErrors) && validationErrors.length > 0) {
            const errorMessages = validationErrors.map((err: any) => 
              `${err.loc?.join('.') || 'Field'}: ${err.msg}`
            ).join(', ')
            throw new Error(`Validation Error: ${errorMessages}`)
          }
          throw new Error('Invalid wine data provided. Please check your inputs.')
        } else if (error.response?.status === 500) {
          const serverMessage = error.response?.data?.message || error.response?.data?.detail || 'Server error occurred'
          throw new Error(`Server Error: ${serverMessage}`)
        } else if (error.response?.status === 404) {
          throw new Error('Endpoint not found. Please check the API configuration.')
        } else if (error.code === 'ECONNABORTED') {
          throw new Error('Request timeout. Please check your connection.')
        } else if (error.code === 'ERR_NETWORK') {
          throw new Error('Network error. Please ensure the backend server is running on http://localhost:8000')
        } else if (!error.response) {
          throw new Error('Unable to connect to server. Please ensure the backend is running.')
        } else {
          throw new Error(error.response?.data?.message || error.response?.data?.detail || 'An unexpected error occurred.')
        }
      }
    )
  }

  /**
   * Transform frontend data to backend format
   * Backend expects lowercase 'ph', frontend uses 'pH'
   */
  private transformToBackendFormat(wineData: WineFeatures): any {
    return {
      fixed_acidity: Number(wineData.fixed_acidity),
      volatile_acidity: Number(wineData.volatile_acidity),
      citric_acid: Number(wineData.citric_acid),
      residual_sugar: Number(wineData.residual_sugar),
      chlorides: Number(wineData.chlorides),
      free_sulfur_dioxide: Number(wineData.free_sulfur_dioxide),
      total_sulfur_dioxide: Number(wineData.total_sulfur_dioxide),
      density: Number(wineData.density),
      ph: Number(wineData.pH),  // ✅ Transform pH to ph for backend
      sulphates: Number(wineData.sulphates),
      alcohol: Number(wineData.alcohol)
    }
  }

  /**
   * Validate wine data before sending
   */
  private validateWineData(wineData: WineFeatures): void {
    const requiredFields: (keyof WineFeatures)[] = [
      'fixed_acidity',
      'volatile_acidity',
      'citric_acid',
      'residual_sugar',
      'chlorides',
      'free_sulfur_dioxide',
      'total_sulfur_dioxide',
      'density',
      'pH',
      'sulphates',
      'alcohol'
    ]

    const missingFields = requiredFields.filter(field => {
      const value = wineData[field]
      return value === undefined || value === null || isNaN(Number(value))
    })

    if (missingFields.length > 0) {
      throw new Error(`Missing or invalid fields: ${missingFields.join(', ')}`)
    }
  }

  /**
   * Predict wine quality
   */
  async predictWineQuality(wineData: WineFeatures): Promise<PredictionResponse> {
    try {
      // Validate data
      this.validateWineData(wineData)
      
      // Transform to backend format (pH -> ph)
      const backendData = this.transformToBackendFormat(wineData)
      
      console.log('🍷 Sending wine data for prediction:', backendData)
      
      const response = await this.api.post<PredictionResponse>(
        '/prediction/predict',
        backendData
      )
      
      console.log('✨ Prediction response:', response.data)
      return response.data
    } catch (error: any) {
      console.error('❌ Error predicting wine quality:', error.message)
      throw error
    }
  }

  /**
   * Compare predictions from all models
   */
  async compareModels(wineData: WineFeatures): Promise<ComparisonResponse> {
    try {
      // Validate data
      this.validateWineData(wineData)
      
      // Transform to backend format (pH -> ph)
      const backendData = this.transformToBackendFormat(wineData)
      
      console.log('📊 Sending wine data for comparison:', backendData)
      
      const response = await this.api.post<ComparisonResponse>(
        '/prediction/predict/compare',
        backendData
      )
      
      console.log('✨ Comparison response:', response.data)
      return response.data
    } catch (error: any) {
      console.error('❌ Error comparing models:', error.message)
      throw error
    }
  }

  /**
   * Check API health
   */
  async checkHealth(): Promise<HealthResponse> {
    try {
      const response = await this.api.get<HealthResponse>('/prediction/health')
      return response.data
    } catch (error) {
      console.error('Error checking health:', error)
      throw error
    }
  }

  /**
   * Get model information
   */
  async getModelInfo(): Promise<any> {
    try {
      const response = await this.api.get('/prediction/models/info')
      return response.data
    } catch (error) {
      console.error('Error getting model info:', error)
      throw error
    }
  }

  /**
   * Get feature information
   */
  async getFeatureInfo(): Promise<any> {
    try {
      const response = await this.api.get('/prediction/features/info')
      return response.data
    } catch (error) {
      console.error('Error getting feature info:', error)
      throw error
    }
  }

  /**
   * Test API connection
   */
  async testConnection(): Promise<boolean> {
    try {
      await this.checkHealth()
      console.log('✅ API connection test successful')
      return true
    } catch (error) {
      console.error('❌ API connection test failed:', error)
      return false
    }
  }
}

// Create singleton instance
const apiService = new ApiService()

export default apiService

// Export individual functions for convenience
export const {
  predictWineQuality,
  compareModels,
  checkHealth,
  getModelInfo,
  getFeatureInfo,
  testConnection
} = apiService