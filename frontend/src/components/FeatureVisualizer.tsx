import React from 'react'
import { motion } from 'framer-motion'
import { WineFeatures } from '../types/wine'

interface FeatureVisualizerProps {
  features: WineFeatures
}

const FeatureVisualizer: React.FC<FeatureVisualizerProps> = ({ features }) => {
  const featureData = [
    { key: 'fixed_acidity', label: 'Fixed Acidity', color: 'from-red-400 to-red-600' },
    { key: 'volatile_acidity', label: 'Volatile Acidity', color: 'from-orange-400 to-orange-600' },
    { key: 'citric_acid', label: 'Citric Acid', color: 'from-yellow-400 to-yellow-600' },
    { key: 'residual_sugar', label: 'Residual Sugar', color: 'from-green-400 to-green-600' },
    { key: 'chlorides', label: 'Chlorides', color: 'from-blue-400 to-blue-600' },
    { key: 'free_sulfur_dioxide', label: 'Free SO2', color: 'from-indigo-400 to-indigo-600' },
    { key: 'total_sulfur_dioxide', label: 'Total SO2', color: 'from-purple-400 to-purple-600' },
    { key: 'density', label: 'Density', color: 'from-pink-400 to-pink-600' },
    { key: 'ph', label: 'pH', color: 'from-rose-400 to-rose-600' },
    { key: 'sulphates', label: 'Sulphates', color: 'from-amber-400 to-amber-600' },
    { key: 'alcohol', label: 'Alcohol', color: 'from-emerald-400 to-emerald-600' },
  ]

  const getNormalizedValue = (value: number, min: number, max: number) => {
    return Math.max(0, Math.min(1, (value - min) / (max - min)))
  }

  const getRanges = (key: string) => {
    const ranges: Record<string, { min: number; max: number }> = {
      fixed_acidity: { min: 3.0, max: 16.0 },
      volatile_acidity: { min: 0.0, max: 2.0 },
      citric_acid: { min: 0.0, max: 2.0 },
      residual_sugar: { min: 0.0, max: 70.0 },
      chlorides: { min: 0.0, max: 1.0 },
      free_sulfur_dioxide: { min: 0.0, max: 300.0 },
      total_sulfur_dioxide: { min: 0.0, max: 500.0 },
      density: { min: 0.98, max: 1.05 },
      ph: { min: 2.5, max: 4.5 },
      sulphates: { min: 0.0, max: 3.0 },
      alcohol: { min: 8.0, max: 16.0 },
    }
    return ranges[key] || { min: 0, max: 1 }
  }

  return (
    <motion.div
      className="card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
    >
      <h3 className="text-lg font-bold text-white mb-4">Feature Overview</h3>
      <div className="space-y-3">
        {featureData.map((feature, index) => {
          const value = features[feature.key as keyof WineFeatures]
          const range = getRanges(feature.key)
          const normalizedValue = getNormalizedValue(value, range.min, range.max)
          
          return (
            <motion.div
              key={feature.key}
              className="space-y-1"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <div className="flex justify-between items-center">
                <span className="text-white/80 text-sm font-medium">
                  {feature.label}
                </span>
                <span className="text-white/60 text-xs">
                  {value.toFixed(3)}
                </span>
              </div>
              
              <div className="h-2 bg-white/20 rounded-full overflow-hidden">
                <motion.div
                  className={`h-full bg-gradient-to-r ${feature.color} rounded-full`}
                  initial={{ width: 0 }}
                  animate={{ width: `${normalizedValue * 100}%` }}
                  transition={{ duration: 0.8, delay: index * 0.05 }}
                />
              </div>
              
              <div className="flex justify-between text-xs text-white/50">
                <span>{range.min}</span>
                <span>{range.max}</span>
              </div>
            </motion.div>
          )
        })}
      </div>
    </motion.div>
  )
}

export default FeatureVisualizer
