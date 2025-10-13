/**
 * Application constants
 */

export const API_CONFIG = {
  BASE_URL: 'http://localhost:8000/api/v1',
  TIMEOUT: 30000,
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 1000,
} as const

export const WINE_FEATURES = {
  FIXED_ACIDITY: {
    name: 'fixed_acidity',
    label: 'Fixed Acidity',
    unit: 'g/dm³',
    min: 3.0,
    max: 16.0,
    step: 0.1,
    description: 'Fixed acidity contributes to the wine\'s tartness and freshness.',
  },
  VOLATILE_ACIDITY: {
    name: 'volatile_acidity',
    label: 'Volatile Acidity',
    unit: 'g/dm³',
    min: 0.0,
    max: 2.0,
    step: 0.01,
    description: 'Volatile acidity can indicate wine faults. Lower values are generally better.',
  },
  CITRIC_ACID: {
    name: 'citric_acid',
    label: 'Citric Acid',
    unit: 'g/dm³',
    min: 0.0,
    max: 2.0,
    step: 0.01,
    description: 'Citric acid adds freshness and can help prevent wine spoilage.',
  },
  RESIDUAL_SUGAR: {
    name: 'residual_sugar',
    label: 'Residual Sugar',
    unit: 'g/dm³',
    min: 0.0,
    max: 70.0,
    step: 0.1,
    description: 'Residual sugar affects sweetness. Higher values make wine sweeter.',
  },
  CHLORIDES: {
    name: 'chlorides',
    label: 'Chlorides',
    unit: 'g/dm³',
    min: 0.0,
    max: 1.0,
    step: 0.001,
    description: 'Chlorides contribute to saltiness. Moderate levels are normal.',
  },
  FREE_SULFUR_DIOXIDE: {
    name: 'free_sulfur_dioxide',
    label: 'Free Sulfur Dioxide',
    unit: 'mg/dm³',
    min: 0.0,
    max: 300.0,
    step: 1.0,
    description: 'Free SO2 acts as a preservative and antioxidant.',
  },
  TOTAL_SULFUR_DIOXIDE: {
    name: 'total_sulfur_dioxide',
    label: 'Total Sulfur Dioxide',
    unit: 'mg/dm³',
    min: 0.0,
    max: 500.0,
    step: 1.0,
    description: 'Total SO2 includes both free and bound sulfur dioxide.',
  },
  DENSITY: {
    name: 'density',
    label: 'Density',
    unit: 'g/cm³',
    min: 0.98,
    max: 1.05,
    step: 0.0001,
    description: 'Density is related to alcohol and sugar content.',
  },
  PH: {
    name: 'ph',
    label: 'pH',
    unit: 'pH units',
    min: 2.5,
    max: 4.5,
    step: 0.01,
    description: 'pH affects wine stability and microbial growth.',
  },
  SULPHATES: {
    name: 'sulphates',
    label: 'Sulphates',
    unit: 'g/dm³',
    min: 0.0,
    max: 3.0,
    step: 0.01,
    description: 'Sulphates can affect wine aroma and flavor.',
  },
  ALCOHOL: {
    name: 'alcohol',
    label: 'Alcohol Content',
    unit: '% vol',
    min: 8.0,
    max: 16.0,
    step: 0.1,
    description: 'Alcohol content affects body, sweetness perception, and balance.',
  },
} as const

export const SAMPLE_WINES = [
  {
    name: 'High Quality Red',
    description: 'Premium wine with excellent balance',
    data: {
      fixed_acidity: 8.1,
      volatile_acidity: 0.6,
      citric_acid: 0.1,
      residual_sugar: 2.1,
      chlorides: 0.092,
      free_sulfur_dioxide: 15.0,
      total_sulfur_dioxide: 40.0,
      density: 0.9985,
      ph: 3.25,
      sulphates: 0.65,
      alcohol: 10.2,
    }
  },
  {
    name: 'Medium Quality Red',
    description: 'Good wine with balanced characteristics',
    data: {
      fixed_acidity: 7.4,
      volatile_acidity: 0.7,
      citric_acid: 0.0,
      residual_sugar: 1.9,
      chlorides: 0.076,
      free_sulfur_dioxide: 11.0,
      total_sulfur_dioxide: 34.0,
      density: 0.9978,
      ph: 3.51,
      sulphates: 0.56,
      alcohol: 9.4,
    }
  },
  {
    name: 'Low Quality Red',
    description: 'Basic wine with simple profile',
    data: {
      fixed_acidity: 6.8,
      volatile_acidity: 0.8,
      citric_acid: 0.0,
      residual_sugar: 1.4,
      chlorides: 0.045,
      free_sulfur_dioxide: 8.0,
      total_sulfur_dioxide: 28.0,
      density: 0.9965,
      ph: 3.35,
      sulphates: 0.45,
      alcohol: 8.8,
    }
  }
] as const

export const ANIMATION_DURATIONS = {
  FAST: 0.2,
  NORMAL: 0.3,
  SLOW: 0.6,
  VERY_SLOW: 1.0,
} as const

export const TOAST_DURATIONS = {
  SHORT: 2000,
  NORMAL: 4000,
  LONG: 6000,
} as const

export const QUALITY_THRESHOLDS = {
  EXCELLENT: 0.8,
  GOOD: 0.6,
  FAIR: 0.4,
  POOR: 0.2,
} as const
