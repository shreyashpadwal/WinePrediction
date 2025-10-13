// Wine feature input types (matching backend snake_case)
export interface WineFeatures {
  fixed_acidity: number
  volatile_acidity: number
  citric_acid: number
  residual_sugar: number
  chlorides: number
  free_sulfur_dioxide: number
  total_sulfur_dioxide: number
  density: number
  pH: number  // ✅ Capital H
  sulphates: number
  alcohol: number
}

// Prediction response from backend
export interface PredictionResponse {
  quality: number
  confidence: number
  model_used: string
  timestamp: string
  input_features?: WineFeatures
}

// Individual model prediction
export interface ModelPrediction {
  model_name: string
  quality: number
  confidence: number
  execution_time: number
}

// Comparison response from backend
export interface ComparisonResponse {
  predictions: ModelPrediction[]
  best_model: string
  average_quality: number
  quality_range: {
    min: number
    max: number
  }
  timestamp: string
}

// Health check response
export interface HealthResponse {
  status: string
  message: string
  timestamp: string
  models_loaded?: boolean
}

// Form validation ranges
export const wineFeatureRanges = {
  fixed_acidity: { min: 4.6, max: 12.35, step: 0.01, default: 7.4 },
  volatile_acidity: { min: 0.12, max: 1.015, step: 0.001, default: 0.7 },
  citric_acid: { min: 0.0, max: 0.94, step: 0.001, default: 0.0 },
  residual_sugar: { min: 0.9, max: 3.65, step: 0.01, default: 2.5 },
  chlorides: { min: 0.039, max: 0.122, step: 0.001, default: 0.087 },
  free_sulfur_dioxide: { min: 1, max: 42, step: 1, default: 15 },
  total_sulfur_dioxide: { min: 6, max: 124.5, step: 1, default: 46 },
  density: { min: 0.992, max: 1.001, step: 0.0001, default: 0.9968 },
  pH: { min: 2.925, max: 3.685, step: 0.001, default: 3.31 },
  sulphates: { min: 0.33, max: 1.0, step: 0.01, default: 0.66 },
  alcohol: { min: 8.4, max: 13.5, step: 0.1, default: 10.4 },
}

// Feature labels for display
export const featureLabels: Record<keyof WineFeatures, string> = {
  fixed_acidity: 'Fixed Acidity',
  volatile_acidity: 'Volatile Acidity',
  citric_acid: 'Citric Acid',
  residual_sugar: 'Residual Sugar',
  chlorides: 'Chlorides',
  free_sulfur_dioxide: 'Free Sulfur Dioxide',
  total_sulfur_dioxide: 'Total Sulfur Dioxide',
  density: 'Density',
  pH: 'pH',
  sulphates: 'Sulphates',
  alcohol: 'Alcohol',
}

// Feature descriptions
export const featureDescriptions: Record<keyof WineFeatures, string> = {
  fixed_acidity: 'Most acids involved with wine (tartaric acid)',
  volatile_acidity: 'Amount of acetic acid (high levels lead to vinegar taste)',
  citric_acid: 'Adds freshness and flavor to wines',
  residual_sugar: 'Amount of sugar remaining after fermentation',
  chlorides: 'Amount of salt in the wine',
  free_sulfur_dioxide: 'Prevents microbial growth and oxidation',
  total_sulfur_dioxide: 'Total amount of SO2 (free + bound forms)',
  density: 'Density of wine (depends on alcohol and sugar content)',
  pH: 'Describes acidity/basicity (0-14 scale)',
  sulphates: 'Wine additive contributing to SO2 levels',
  alcohol: 'Percent alcohol content of the wine',
}