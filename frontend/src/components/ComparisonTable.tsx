import React from 'react'
import { motion } from 'framer-motion'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { ModelPrediction } from '../types/wine'

interface ComparisonTableProps {
  predictions: ModelPrediction[]
  consensus: string
  agreementCount: number
  totalModels: number
}

const ComparisonTable: React.FC<ComparisonTableProps> = ({
  predictions,
  consensus,
  agreementCount,
  totalModels
}) => {
  const sortedPredictions = [...predictions].sort((a, b) => b.confidence - a.confidence)

  const getTrendIcon = (prediction: string, consensus: string) => {
    if (prediction.toLowerCase() === consensus.toLowerCase()) {
      return <TrendingUp className="w-4 h-4 text-green-400" />
    } else {
      return <TrendingDown className="w-4 h-4 text-red-400" />
    }
  }

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return 'text-green-400'
    if (confidence >= 0.6) return 'text-yellow-400'
    return 'text-red-400'
  }

  const getPredictionColor = (prediction: string) => {
    return prediction.toLowerCase() === 'good' 
      ? 'bg-green-500/20 text-green-400 border-green-500/30' 
      : 'bg-red-500/20 text-red-400 border-red-500/30'
  }

  return (
    <motion.div
      className="card-strong"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
    >
      <div className="mb-6">
        <h3 className="text-2xl font-bold text-white mb-2">Model Comparison</h3>
        <p className="text-white/70">
          Detailed analysis from all trained models
        </p>
      </div>

      {/* Consensus Summary */}
      <div className="glassmorphism rounded-xl p-4 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-lg font-semibold text-white mb-1">Consensus</h4>
            <p className="text-white/60 text-sm">
              {agreementCount} out of {totalModels} models agree
            </p>
          </div>
          <div className={`px-4 py-2 rounded-lg border ${getPredictionColor(consensus)}`}>
            <span className="font-semibold">{consensus}</span>
          </div>
        </div>
      </div>

      {/* Models Table */}
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-white/20">
              <th className="text-left py-3 px-4 text-white/80 font-medium">Model</th>
              <th className="text-left py-3 px-4 text-white/80 font-medium">Prediction</th>
              <th className="text-left py-3 px-4 text-white/80 font-medium">Confidence</th>
              <th className="text-left py-3 px-4 text-white/80 font-medium">Agreement</th>
            </tr>
          </thead>
          <tbody>
            {sortedPredictions.map((model, index) => (
              <motion.tr
                key={model.model_name}
                className="border-b border-white/10 hover:bg-white/5 transition-colors"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
              >
                <td className="py-4 px-4">
                  <div className="flex items-center">
                    <div className={`w-3 h-3 rounded-full mr-3 ${
                      model.prediction.toLowerCase() === 'good' 
                        ? 'bg-green-400' 
                        : 'bg-red-400'
                    }`} />
                    <span className="text-white font-medium">{model.model_name}</span>
                  </div>
                </td>
                <td className="py-4 px-4">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${getPredictionColor(model.prediction)}`}>
                    {model.prediction}
                  </span>
                </td>
                <td className="py-4 px-4">
                  <div className="flex items-center">
                    <span className={`font-semibold ${getConfidenceColor(model.confidence)}`}>
                      {Math.round(model.confidence * 100)}%
                    </span>
                    <div className="ml-3 w-20 h-2 bg-white/20 rounded-full overflow-hidden">
                      <motion.div
                        className={`h-full ${
                          model.confidence >= 0.8 
                            ? 'bg-gradient-to-r from-green-400 to-green-600'
                            : model.confidence >= 0.6
                            ? 'bg-gradient-to-r from-yellow-400 to-yellow-600'
                            : 'bg-gradient-to-r from-red-400 to-red-600'
                        }`}
                        initial={{ width: 0 }}
                        animate={{ width: `${model.confidence * 100}%` }}
                        transition={{ duration: 0.8, delay: index * 0.1 }}
                      />
                    </div>
                  </div>
                </td>
                <td className="py-4 px-4">
                  <div className="flex items-center">
                    {getTrendIcon(model.prediction, consensus)}
                    <span className="ml-2 text-white/60 text-sm">
                      {model.prediction.toLowerCase() === consensus.toLowerCase() ? 'Agrees' : 'Disagrees'}
                    </span>
                  </div>
                </td>
              </motion.tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Summary Stats */}
      <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="glassmorphism rounded-xl p-4 text-center">
          <div className="text-2xl font-bold text-white">
            {Math.round((agreementCount / totalModels) * 100)}%
          </div>
          <div className="text-white/60 text-sm">Agreement Rate</div>
        </div>
        
        <div className="glassmorphism rounded-xl p-4 text-center">
          <div className="text-2xl font-bold text-white">
            {Math.round(sortedPredictions.reduce((acc, model) => acc + model.confidence, 0) / sortedPredictions.length * 100)}%
          </div>
          <div className="text-white/60 text-sm">Average Confidence</div>
        </div>
        
        <div className="glassmorphism rounded-xl p-4 text-center">
          <div className="text-2xl font-bold text-white">
            {sortedPredictions.length}
          </div>
          <div className="text-white/60 text-sm">Models Analyzed</div>
        </div>
      </div>
    </motion.div>
  )
}

export default ComparisonTable
