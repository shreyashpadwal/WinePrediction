import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Toaster, toast } from 'react-hot-toast'
import Layout from './components/Layout'
import WineQualityForm from './components/WineQualityForm'
import ResultsDisplay from './components/ResultsDisplay'
import { WineFeatures, PredictionResponse, ComparisonResponse } from './types/wine'
import apiService from './services/api'

type AppState = 'form' | 'loading' | 'results' | 'error'

const App: React.FC = () => {
  const [appState, setAppState] = useState<AppState>('form')
  const [prediction, setPrediction] = useState<PredictionResponse | null>(null)
  const [comparison, setComparison] = useState<ComparisonResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isDarkMode, setIsDarkMode] = useState(true)
  const [apiConnected, setApiConnected] = useState<boolean | null>(null)

  // Check API connection on mount
  useEffect(() => {
    const checkConnection = async () => {
      try {
        const connected = await apiService.testConnection()
        setApiConnected(connected)
        
        if (connected) {
          toast.success('Connected to Wine Quality API!', {
            icon: '🍷',
            duration: 3000,
          })
        } else {
          toast.error('Unable to connect to API. Please check if the backend is running.', {
            duration: 5000,
          })
        }
      } catch (error) {
        setApiConnected(false)
        toast.error('API connection failed. Please check your connection.', {
          duration: 5000,
        })
      }
    }

    checkConnection()
  }, [])

  const handleFormSubmit = async (wineData: WineFeatures) => {
    setAppState('loading')
    setError(null)
    setPrediction(null)
    setComparison(null)

    try {
      toast.loading('Analyzing wine quality...', {
        id: 'prediction',
        duration: 0,
      })

      // Make both API calls in parallel
      const [predictionResult, comparisonResult] = await Promise.allSettled([
        apiService.predictWineQuality(wineData),
        apiService.compareModels(wineData)
      ])

      // Handle prediction result
      if (predictionResult.status === 'fulfilled') {
        setPrediction(predictionResult.value)
        toast.success('Wine quality predicted successfully!', {
          id: 'prediction',
          icon: '🍷',
          duration: 3000,
        })
      } else {
        throw predictionResult.reason
      }

      // Handle comparison result (optional)
      if (comparisonResult.status === 'fulfilled') {
        setComparison(comparisonResult.value)
      } else {
        console.warn('Model comparison failed:', comparisonResult.reason)
        // Don't throw error for comparison failure, just log it
      }

      setAppState('results')
    } catch (error: any) {
      console.error('Prediction error:', error)
      setError(error.message || 'An unexpected error occurred')
      setAppState('error')
      
      toast.error(error.message || 'Failed to predict wine quality', {
        id: 'prediction',
        duration: 5000,
      })
    }
  }

  const handlePredictAnother = () => {
    setAppState('form')
    setPrediction(null)
    setComparison(null)
    setError(null)
  }

  const handleRetry = () => {
    setAppState('form')
    setError(null)
  }

  const toggleDarkMode = () => {
    setIsDarkMode(!isDarkMode)
  }

  return (
    <Layout>
      <div className="min-h-screen py-8 px-4">
        <div className="max-w-6xl mx-auto">
          {/* API Status Indicator */}
          {apiConnected !== null && (
            <motion.div
              className="mb-6"
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <div className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-medium ${
                apiConnected 
                  ? 'bg-green-500/20 text-green-400 border border-green-500/30' 
                  : 'bg-red-500/20 text-red-400 border border-red-500/30'
              }`}>
                <div className={`w-2 h-2 rounded-full mr-2 ${
                  apiConnected ? 'bg-green-400' : 'bg-red-400'
                }`} />
                {apiConnected ? 'API Connected' : 'API Disconnected'}
              </div>
            </motion.div>
          )}

          {/* Main Content */}
          <AnimatePresence mode="wait">
            {appState === 'form' && (
              <motion.div
                key="form"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.3 }}
              >
                <WineQualityForm
                  onSubmit={handleFormSubmit}
                  isLoading={false}
                />
              </motion.div>
            )}

            {appState === 'loading' && (
              <motion.div
                key="loading"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                transition={{ duration: 0.3 }}
                className="flex flex-col items-center justify-center min-h-[400px]"
              >
                <div className="card-strong text-center max-w-md">
                  <motion.div
                    className="w-20 h-20 wine-gradient rounded-2xl flex items-center justify-center mx-auto mb-6"
                    animate={{ 
                      rotate: [0, 10, -10, 0],
                      scale: [1, 1.1, 1]
                    }}
                    transition={{ 
                      duration: 2,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  >
                    <span className="text-3xl">🍷</span>
                  </motion.div>
                  
                  <h2 className="text-2xl font-bold text-white mb-4">
                    Analyzing Your Wine
                  </h2>
                  
                  <p className="text-white/80 mb-6">
                    Our AI is examining the chemical composition and comparing it across multiple machine learning models...
                  </p>
                  
                  <div className="flex items-center justify-center space-x-2">
                    <motion.div
                      className="w-3 h-3 bg-burgundy-400 rounded-full"
                      animate={{ scale: [1, 1.2, 1] }}
                      transition={{ duration: 0.6, repeat: Infinity, delay: 0 }}
                    />
                    <motion.div
                      className="w-3 h-3 bg-rose-400 rounded-full"
                      animate={{ scale: [1, 1.2, 1] }}
                      transition={{ duration: 0.6, repeat: Infinity, delay: 0.2 }}
                    />
                    <motion.div
                      className="w-3 h-3 bg-gold-400 rounded-full"
                      animate={{ scale: [1, 1.2, 1] }}
                      transition={{ duration: 0.6, repeat: Infinity, delay: 0.4 }}
                    />
                  </div>
                </div>
              </motion.div>
            )}

            {appState === 'results' && prediction && (
              <motion.div
                key="results"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.3 }}
              >
                <ResultsDisplay
                  prediction={prediction}
                  comparison={comparison || undefined}
                  onPredictAnother={handlePredictAnother}
                />
              </motion.div>
            )}

            {appState === 'error' && (
              <motion.div
                key="error"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                transition={{ duration: 0.3 }}
                className="flex flex-col items-center justify-center min-h-[400px]"
              >
                <div className="card-strong text-center max-w-md">
                  <motion.div
                    className="w-20 h-20 bg-red-500/20 rounded-2xl flex items-center justify-center mx-auto mb-6"
                    animate={{ 
                      scale: [1, 1.05, 1],
                    }}
                    transition={{ 
                      duration: 2,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  >
                    <span className="text-3xl">❌</span>
                  </motion.div>
                  
                  <h2 className="text-2xl font-bold text-white mb-4">
                    Prediction Failed
                  </h2>
                  
                  <p className="text-white/80 mb-6">
                    {error || 'An unexpected error occurred while analyzing your wine.'}
                  </p>
                  
                  <div className="flex flex-col sm:flex-row gap-4 justify-center">
                    <motion.button
                      onClick={handleRetry}
                      className="btn-primary"
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      Try Again
                    </motion.button>
                    
                    <motion.button
                      onClick={handlePredictAnother}
                      className="btn-secondary"
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      New Prediction
                    </motion.button>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Features Section */}
          {appState === 'form' && (
            <motion.div
              className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
            >
              <div className="card text-center">
                <div className="w-12 h-12 wine-gradient rounded-xl flex items-center justify-center mx-auto mb-4">
                  <span className="text-2xl">🤖</span>
                </div>
                <h3 className="text-xl font-bold text-white mb-2">AI-Powered Analysis</h3>
                <p className="text-white/70">
                  Advanced machine learning models trained on thousands of wine samples
                </p>
              </div>
              
              <div className="card text-center">
                <div className="w-12 h-12 wine-gradient rounded-xl flex items-center justify-center mx-auto mb-4">
                  <span className="text-2xl">🧠</span>
                </div>
                <h3 className="text-xl font-bold text-white mb-2">Gemini AI Insights</h3>
                <p className="text-white/70">
                  Get detailed explanations about wine characteristics and quality factors
                </p>
              </div>
              
              <div className="card text-center">
                <div className="w-12 h-12 wine-gradient rounded-xl flex items-center justify-center mx-auto mb-4">
                  <span className="text-2xl">📊</span>
                </div>
                <h3 className="text-xl font-bold text-white mb-2">Model Comparison</h3>
                <p className="text-white/70">
                  Compare predictions across multiple algorithms for comprehensive analysis
                </p>
              </div>
            </motion.div>
          )}
        </div>
      </div>
    </Layout>
  )
}

export default App
