import React, { useState, useEffect } from 'react'
import { 
  Wine, 
  CheckCircle, 
  XCircle, 
  Brain, 
  TrendingUp, 
  Download, 
  RotateCcw,
  ChevronDown,
  ChevronUp,
  Sparkles,
  Award,
  BarChart3,
  AlertCircle
} from 'lucide-react'

interface ModelResult {
  model_name: string
  prediction: string
  confidence: number
}

interface ComparisonResponse {
  consensus: string
  agreement_count: number
  total_models: number
  all_models_results: ModelResult[]
}

interface PredictionResponse {
  prediction: string
  confidence: number
  model_used: string
  timestamp: string
  gemini_insight?: string
}

interface ResultsDisplayProps {
  prediction: PredictionResponse
  comparison?: ComparisonResponse
  onPredictAnother: () => void
}

const ResultsDisplay: React.FC<ResultsDisplayProps> = ({ 
  prediction, 
  comparison, 
  onPredictAnother 
}) => {
  const [showComparison, setShowComparison] = useState(false)
  const [typewriterText, setTypewriterText] = useState('')
  const [showConfetti, setShowConfetti] = useState(false)
  const [confettiParticles, setConfettiParticles] = useState<Array<{x: number, delay: number}>>([])

  // ✅ NEW: Convert prediction to quality category
  const getQualityCategory = (pred: string): { label: string, score: number } => {
    // Try to parse as number first
    const numScore = parseFloat(pred)
    
    if (!isNaN(numScore)) {
      // Numeric score (3-8 scale)
      if (numScore >= 7) return { label: 'Excellent', score: numScore }
      if (numScore >= 5) return { label: 'Good', score: numScore }
      return { label: 'Below Average', score: numScore }
    } else {
      // Text prediction
      const predLower = pred.toLowerCase()
      if (['excellent', 'very good', 'great'].includes(predLower)) {
        return { label: 'Excellent', score: 7.5 }
      }
      if (['good', 'average', 'medium'].includes(predLower)) {
        return { label: 'Good', score: 6 }
      }
      return { label: 'Below Average', score: 4 }
    }
  }

  const qualityData = getQualityCategory(prediction.prediction)
  const qualityLabel = qualityData.label
  const qualityScore = qualityData.score
  const isGoodQuality = qualityLabel === 'Good' || qualityLabel === 'Excellent'
  const confidencePercent = Math.round(prediction.confidence * 100)

  // Typewriter effect for AI insights
  useEffect(() => {
    if (prediction.gemini_insight) {
      let index = 0
      const text = prediction.gemini_insight
      setTypewriterText('')
      
      const timer = setInterval(() => {
        if (index < text.length) {
          setTypewriterText(text.slice(0, index + 1))
          index++
        } else {
          clearInterval(timer)
        }
      }, 30)

      return () => clearInterval(timer)
    }
  }, [prediction.gemini_insight])

  // Confetti effect for excellent quality
  useEffect(() => {
    if (qualityLabel === 'Excellent' && confidencePercent > 80) {
      const particles = Array.from({ length: 50 }, () => ({
        x: Math.random() * 100,
        delay: Math.random() * 2
      }))
      setConfettiParticles(particles)
      setShowConfetti(true)
      
      const timer = setTimeout(() => setShowConfetti(false), 3000)
      return () => clearTimeout(timer)
    }
  }, [qualityLabel, confidencePercent])

  const getQualityColor = () => {
    switch (qualityLabel) {
      case 'Excellent':
        return 'from-green-400 to-emerald-600'
      case 'Good':
        return 'from-yellow-400 to-amber-500'
      case 'Below Average':
        return 'from-red-400 to-red-600'
      default:
        return 'from-gray-400 to-gray-600'
    }
  }

  const getQualityIcon = () => {
    switch (qualityLabel) {
      case 'Excellent':
        return <CheckCircle className="w-16 h-16 text-green-400" />
      case 'Good':
        return <Wine className="w-16 h-16 text-yellow-400" />
      case 'Below Average':
        return <AlertCircle className="w-16 h-16 text-red-400" />
      default:
        return <XCircle className="w-16 h-16 text-gray-400" />
    }
  }

  const getQualityMessage = () => {
    switch (qualityLabel) {
      case 'Excellent':
        return 'Excellent Quality Wine!'
      case 'Good':
        return 'Good Quality Wine'
      case 'Below Average':
        return 'Below Average Quality'
      default:
        return 'Unknown Quality'
    }
  }

  const getQualityDescription = () => {
    switch (qualityLabel) {
      case 'Excellent':
        return `Outstanding wine with a quality score of ${qualityScore.toFixed(1)}. This wine exhibits exceptional characteristics.`
      case 'Good':
        return `Solid wine with a quality score of ${qualityScore.toFixed(1)}. This wine shows good balance and pleasant characteristics.`
      case 'Below Average':
        return `Basic wine with a quality score of ${qualityScore.toFixed(1)}. This wine may have some unbalanced characteristics.`
      default:
        return 'Quality assessment unavailable.'
    }
  }

  const downloadReport = () => {
    const report = {
      prediction: prediction.prediction,
      quality_label: qualityLabel,
      quality_score: qualityScore,
      confidence: prediction.confidence,
      model_used: prediction.model_used,
      timestamp: prediction.timestamp,
      gemini_insight: prediction.gemini_insight,
      comparison: comparison
    }
    
    const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `wine-prediction-${new Date().toISOString().split('T')[0]}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-red-900 to-pink-900 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Confetti Effect */}
        {showConfetti && (
          <div className="fixed inset-0 pointer-events-none z-50 overflow-hidden">
            {confettiParticles.map((particle, i) => (
              <div
                key={i}
                className="absolute w-2 h-2 bg-gradient-to-r from-yellow-400 to-pink-500 rounded-full animate-confetti"
                style={{
                  left: `${particle.x}%`,
                  bottom: '0',
                  animationDelay: `${particle.delay}s`
                }}
              />
            ))}
          </div>
        )}

        {/* Main Result Card */}
        <div className="bg-white/10 backdrop-blur-lg rounded-3xl p-8 shadow-2xl border border-white/20 text-center">
          <div className="mb-6 flex justify-center">
            {getQualityIcon()}
          </div>

          <h2 className={`text-4xl font-bold mb-4 bg-gradient-to-r ${getQualityColor()} bg-clip-text text-transparent`}>
            {getQualityMessage()}
          </h2>

          {/* Quality Score Badge */}
          <div className="mb-6">
            <div className={`inline-flex items-center px-6 py-3 rounded-full ${
              qualityLabel === 'Excellent' 
                ? 'bg-green-500/20 border-green-400/50' 
                : qualityLabel === 'Good'
                ? 'bg-yellow-500/20 border-yellow-400/50'
                : 'bg-red-500/20 border-red-400/50'
            } border-2`}>
              <span className="text-2xl font-bold text-white mr-2">
                {qualityScore.toFixed(1)}
              </span>
              <span className="text-white/80 text-sm">/ 10</span>
            </div>
            <p className="text-white/70 mt-3 max-w-md mx-auto">
              {getQualityDescription()}
            </p>
          </div>

          {/* Confidence Score */}
          <div className="mb-6">
            <div className="relative w-32 h-32 mx-auto">
              <svg className="w-32 h-32 transform -rotate-90" viewBox="0 0 36 36">
                <path
                  className="text-white/20"
                  stroke="currentColor"
                  strokeWidth="3"
                  fill="none"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
                <path
                  className={`${
                    qualityLabel === 'Excellent' 
                      ? 'text-green-400' 
                      : qualityLabel === 'Good'
                      ? 'text-yellow-400'
                      : 'text-red-400'
                  } transition-all duration-1000`}
                  stroke="currentColor"
                  strokeWidth="3"
                  fill="none"
                  strokeLinecap="round"
                  strokeDasharray={`${confidencePercent}, 100`}
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <span className="text-2xl font-bold text-white">
                  {confidencePercent}%
                </span>
              </div>
            </div>
            <p className="text-white/80 mt-2">Confidence Score</p>
          </div>

          {/* Model Info */}
          <div className="flex items-center justify-center space-x-2 text-white/60 text-sm">
            <Award className="w-4 h-4" />
            <span>Predicted by {prediction.model_used}</span>
          </div>

          {/* Quality Scale Reference */}
          <div className="mt-8 p-4 bg-white/5 rounded-xl border border-white/10">
            <h4 className="text-white font-medium mb-3 text-sm">Quality Scale Reference</h4>
            <div className="grid grid-cols-3 gap-3 text-xs">
              <div className="text-center">
                <div className="w-full h-2 bg-gradient-to-r from-red-400 to-red-600 rounded-full mb-2"></div>
                <div className="text-red-400 font-medium">3-4</div>
                <div className="text-white/60">Below Average</div>
              </div>
              <div className="text-center">
                <div className="w-full h-2 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-full mb-2"></div>
                <div className="text-yellow-400 font-medium">5-6</div>
                <div className="text-white/60">Good</div>
              </div>
              <div className="text-center">
                <div className="w-full h-2 bg-gradient-to-r from-green-400 to-emerald-600 rounded-full mb-2"></div>
                <div className="text-green-400 font-medium">7-8</div>
                <div className="text-white/60">Excellent</div>
              </div>
            </div>
          </div>
        </div>

        {/* AI Insights */}
        {prediction.gemini_insight && (
          <div className="bg-white/10 backdrop-blur-lg rounded-3xl p-8 shadow-2xl border border-white/20">
            <div className="flex items-center mb-4">
              <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mr-3">
                <Brain className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-xl font-bold text-white">AI Analysis</h3>
            </div>
            
            <div className="bg-white/5 backdrop-blur-sm rounded-xl p-4 min-h-[100px] border border-white/10">
              <p className="text-white/90 leading-relaxed">
                {typewriterText}
                <span className="inline-block w-0.5 h-5 bg-white/80 ml-1 animate-pulse" />
              </p>
            </div>
          </div>
        )}

        {/* Model Comparison */}
        {comparison && (
          <div className="bg-white/10 backdrop-blur-lg rounded-3xl p-8 shadow-2xl border border-white/20">
            <button
              onClick={() => setShowComparison(!showComparison)}
              className="flex items-center justify-between w-full text-left"
            >
              <div className="flex items-center">
                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mr-3">
                  <BarChart3 className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl font-bold text-white">Model Comparison</h3>
              </div>
              {showComparison ? (
                <ChevronUp className="w-6 h-6 text-white/60" />
              ) : (
                <ChevronDown className="w-6 h-6 text-white/60" />
              )}
            </button>

            {showComparison && (
              <div className="mt-4 space-y-3">
                <div className="bg-white/5 backdrop-blur-sm rounded-xl p-4 border border-white/10">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-white font-medium">Consensus</span>
                    <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                      getQualityCategory(comparison.consensus).label === 'Excellent'
                        ? 'bg-green-500/20 text-green-400'
                        : getQualityCategory(comparison.consensus).label === 'Good'
                        ? 'bg-yellow-500/20 text-yellow-400'
                        : 'bg-red-500/20 text-red-400'
                    }`}>
                      {getQualityCategory(comparison.consensus).label}
                    </span>
                  </div>
                  <p className="text-white/60 text-sm">
                    {comparison.agreement_count} out of {comparison.total_models} models agree
                  </p>
                </div>

                {comparison.all_models_results.map((model) => {
                  const modelQuality = getQualityCategory(model.prediction)
                  return (
                    <div
                      key={model.model_name}
                      className="bg-white/5 backdrop-blur-sm rounded-xl p-4 border border-white/10"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className={`w-3 h-3 rounded-full mr-3 ${
                            modelQuality.label === 'Excellent'
                              ? 'bg-green-400'
                              : modelQuality.label === 'Good'
                              ? 'bg-yellow-400'
                              : 'bg-red-400'
                          }`} />
                          <span className="text-white font-medium">{model.model_name}</span>
                        </div>
                        <div className="text-right">
                          <div className={`text-sm font-medium ${
                            modelQuality.label === 'Excellent'
                              ? 'text-green-400'
                              : modelQuality.label === 'Good'
                              ? 'text-yellow-400'
                              : 'text-red-400'
                          }`}>
                            {modelQuality.label} ({modelQuality.score.toFixed(1)})
                          </div>
                          <div className="text-white/60 text-xs">
                            {Math.round(model.confidence * 100)}% confidence
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <button
            onClick={onPredictAnother}
            className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white px-8 py-4 rounded-2xl transition-all duration-200 flex items-center justify-center shadow-lg"
          >
            <RotateCcw className="w-5 h-5 mr-2" />
            Predict Another Wine
          </button>

          <button
            onClick={downloadReport}
            className="bg-white/20 hover:bg-white/30 text-white px-8 py-4 rounded-2xl transition-all duration-200 flex items-center justify-center backdrop-blur-sm border border-white/30 shadow-lg"
          >
            <Download className="w-5 h-5 mr-2" />
            Download Report
          </button>
        </div>
      </div>

      <style>{`
        @keyframes confetti {
          0% {
            transform: translateY(100vh) rotate(0deg);
            opacity: 1;
          }
          100% {
            transform: translateY(-10vh) rotate(360deg);
            opacity: 0;
          }
        }
        
        .animate-confetti {
          animation: confetti 3s ease-out forwards;
        }
      `}</style>
    </div>
  )
}

export default ResultsDisplay