import React, { useState } from 'react'
import { Info, Wine, Sparkles, RotateCcw } from 'lucide-react'

interface WineFeatures {
  fixed_acidity: number
  volatile_acidity: number
  citric_acid: number
  residual_sugar: number
  chlorides: number
  free_sulfur_dioxide: number
  total_sulfur_dioxide: number
  density: number
  pH: number  // ✅ FIXED: Changed from 'ph' to 'pH'
  sulphates: number
  alcohol: number
}

interface WineQualityFormProps {
  onSubmit: (data: WineFeatures) => void
  isLoading?: boolean
}

interface FormData {
  fixed_acidity: string
  volatile_acidity: string
  citric_acid: string
  residual_sugar: string
  chlorides: string
  free_sulfur_dioxide: string
  total_sulfur_dioxide: string
  density: string
  pH: string  // ✅ FIXED: Changed from 'ph' to 'pH'
  sulphates: string
  alcohol: string
}

const WineQualityForm: React.FC<WineQualityFormProps> = ({ onSubmit, isLoading = false }) => {
  const [showTooltip, setShowTooltip] = useState<string | null>(null)
  const [errors, setErrors] = useState<Partial<Record<keyof FormData, string>>>({})

  const fieldConfigs = [
    { name: 'fixed_acidity' as const, label: 'Fixed Acidity', unit: 'g/dm³', min: 4.6, max: 12.35, step: 0.01 },
    { name: 'volatile_acidity' as const, label: 'Volatile Acidity', unit: 'g/dm³', min: 0.12, max: 1.015, step: 0.001 },
    { name: 'citric_acid' as const, label: 'Citric Acid', unit: 'g/dm³', min: 0.0, max: 0.94, step: 0.001 },
    { name: 'residual_sugar' as const, label: 'Residual Sugar', unit: 'g/dm³', min: 0.9, max: 3.65, step: 0.01 },
    { name: 'chlorides' as const, label: 'Chlorides', unit: 'g/dm³', min: 0.039, max: 0.122, step: 0.001 },
    { name: 'free_sulfur_dioxide' as const, label: 'Free Sulfur Dioxide', unit: 'mg/dm³', min: 1, max: 42, step: 1 },
    { name: 'total_sulfur_dioxide' as const, label: 'Total Sulfur Dioxide', unit: 'mg/dm³', min: 6, max: 124.5, step: 1 },
    { name: 'density' as const, label: 'Density', unit: 'g/cm³', min: 0.992, max: 1.001, step: 0.0001 },
    { name: 'pH' as const, label: 'pH', unit: 'pH units', min: 2.925, max: 3.685, step: 0.001 },  // ✅ FIXED
    { name: 'sulphates' as const, label: 'Sulphates', unit: 'g/dm³', min: 0.33, max: 1.0, step: 0.01 },
    { name: 'alcohol' as const, label: 'Alcohol Content', unit: '% vol', min: 8.4, max: 13.5, step: 0.1 },
  ]

  const initialFormData: FormData = {
    fixed_acidity: '',
    volatile_acidity: '',
    citric_acid: '',
    residual_sugar: '',
    chlorides: '',
    free_sulfur_dioxide: '',
    total_sulfur_dioxide: '',
    density: '',
    pH: '',  // ✅ FIXED
    sulphates: '',
    alcohol: '',
  }

  const [formData, setFormData] = useState<FormData>(initialFormData)

  const sampleWines = [
    {
      name: 'High Quality Red',
      data: {
        fixed_acidity: '8.1',
        volatile_acidity: '0.6',
        citric_acid: '0.1',
        residual_sugar: '2.1',
        chlorides: '0.092',
        free_sulfur_dioxide: '15',
        total_sulfur_dioxide: '40',
        density: '0.9985',
        pH: '3.25',  // ✅ FIXED
        sulphates: '0.65',
        alcohol: '10.2',
      }
    },
    {
      name: 'Medium Quality Red',
      data: {
        fixed_acidity: '7.4',
        volatile_acidity: '0.7',
        citric_acid: '0.0',
        residual_sugar: '1.9',
        chlorides: '0.076',
        free_sulfur_dioxide: '11',
        total_sulfur_dioxide: '34',
        density: '0.9978',
        pH: '3.51',  // ✅ FIXED
        sulphates: '0.56',
        alcohol: '9.4',
      }
    },
    {
      name: 'Low Quality Red',
      data: {
        fixed_acidity: '6.8',
        volatile_acidity: '0.8',
        citric_acid: '0.0',
        residual_sugar: '1.4',
        chlorides: '0.045',
        free_sulfur_dioxide: '8',
        total_sulfur_dioxide: '28',
        density: '0.9965',
        pH: '3.35',  // ✅ FIXED
        sulphates: '0.45',
        alcohol: '8.8',
      }
    }
  ]

  const loadSampleData = (sampleData: FormData) => {
    setFormData(sampleData)
    setErrors({})
  }

  const handleChange = (name: keyof FormData, value: string) => {
    setFormData(prev => ({ ...prev, [name]: value }))
    if (errors[name]) {
      setErrors(prev => {
        const newErrors = { ...prev }
        delete newErrors[name]
        return newErrors
      })
    }
  }

  const validateForm = (): boolean => {
    const newErrors: Partial<Record<keyof FormData, string>> = {}
    
    fieldConfigs.forEach(field => {
      const value = formData[field.name]
      const numValue = parseFloat(value)
      
      if (!value || value.trim() === '') {
        newErrors[field.name] = `${field.label} is required`
      } else if (isNaN(numValue)) {
        newErrors[field.name] = `${field.label} must be a number`
      } else if (numValue < field.min) {
        newErrors[field.name] = `Minimum value is ${field.min}`
      } else if (numValue > field.max) {
        newErrors[field.name] = `Maximum value is ${field.max}`
      }
    })
    
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = () => {
    if (validateForm()) {
      const numericData: WineFeatures = {
        fixed_acidity: parseFloat(formData.fixed_acidity),
        volatile_acidity: parseFloat(formData.volatile_acidity),
        citric_acid: parseFloat(formData.citric_acid),
        residual_sugar: parseFloat(formData.residual_sugar),
        chlorides: parseFloat(formData.chlorides),
        free_sulfur_dioxide: parseFloat(formData.free_sulfur_dioxide),
        total_sulfur_dioxide: parseFloat(formData.total_sulfur_dioxide),
        density: parseFloat(formData.density),
        pH: parseFloat(formData.pH),  // ✅ FIXED
        sulphates: parseFloat(formData.sulphates),
        alcohol: parseFloat(formData.alcohol),
      }
      
      console.log('📤 Form submitting data:', numericData)  // Debug log
      onSubmit(numericData)
    }
  }

  const handleReset = () => {
    setFormData(initialFormData)
    setErrors({})
  }

  const getSliderColor = (value: number, min: number, max: number) => {
    const percentage = ((value - min) / (max - min)) * 100
    if (percentage < 30) return 'from-red-400 to-red-600'
    if (percentage < 70) return 'from-yellow-400 to-yellow-600'
    return 'from-green-400 to-green-600'
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-red-900 to-pink-900 p-6">
      <div className="max-w-4xl mx-auto bg-white/10 backdrop-blur-lg rounded-3xl p-8 shadow-2xl border border-white/20">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl mb-4">
            <Wine className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-3xl font-bold text-white mb-2">
            Wine Quality Analysis
          </h2>
          <p className="text-white/80">
            Enter the chemical composition to predict wine quality
          </p>
        </div>

        <div className="space-y-6">
          {/* Sample Data Buttons */}
          <div className="flex flex-wrap gap-3 justify-center mb-8">
            {sampleWines.map((wine) => (
              <button
                key={wine.name}
                type="button"
                onClick={() => loadSampleData(wine.data)}
                className="bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-all duration-200 flex items-center backdrop-blur-sm border border-white/30"
              >
                <Sparkles className="w-4 h-4 mr-2" />
                {wine.name}
              </button>
            ))}
          </div>

          {/* Form Fields */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {fieldConfigs.map((field) => {
              const value = formData[field.name]
              const numericValue = parseFloat(value) || field.min
              const widthPercent = ((numericValue - field.min) / (field.max - field.min)) * 100
              const error = errors[field.name]

              return (
                <div key={field.name} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <label className="flex items-center text-white font-medium">
                      {field.label}
                      <div className="relative ml-2">
                        <button
                          type="button"
                          onMouseEnter={() => setShowTooltip(field.name)}
                          onMouseLeave={() => setShowTooltip(null)}
                          className="text-white/60 hover:text-white transition-colors"
                        >
                          <Info className="w-4 h-4" />
                        </button>

                        {showTooltip === field.name && (
                          <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 w-64 p-3 bg-black/80 backdrop-blur-md rounded-lg text-xs text-white z-10">
                            <div className="font-medium mb-1">{field.label}</div>
                            <div className="text-white/80 mb-2">
                              Enter a value between {field.min} and {field.max} {field.unit}
                            </div>
                          </div>
                        )}
                      </div>
                    </label>
                    <span className="text-white/60 text-sm">{field.unit}</span>
                  </div>

                  <div className="relative">
                    <input
                      type="number"
                      step={field.step}
                      min={field.min}
                      max={field.max}
                      value={value}
                      onChange={(e) => handleChange(field.name, e.target.value)}
                      className={`w-full px-4 py-3 bg-white/10 backdrop-blur-sm rounded-xl text-white placeholder-white/50 border ${
                        error ? 'border-red-400' : 'border-white/20'
                      } focus:border-white/40 focus:outline-none transition-colors`}
                      placeholder={`${field.min} - ${field.max}`}
                    />

                    {/* Visual Slider */}
                    <div className="mt-2 h-2 bg-white/20 rounded-full overflow-hidden">
                      <div
                        className={`h-full bg-gradient-to-r ${getSliderColor(numericValue, field.min, field.max)} rounded-full transition-all duration-300`}
                        style={{ width: `${widthPercent}%` }}
                      />
                    </div>

                    {/* Range Display */}
                    <div className="text-right text-white/60 text-sm mt-1">
                      Range: {field.min} – {field.max} {field.unit}
                    </div>
                  </div>

                  {error && (
                    <p className="text-red-400 text-sm">{error}</p>
                  )}
                </div>
              )
            })}
          </div>

          {/* Submit Button */}
          <div className="flex justify-center pt-6">
            <button
              type="button"
              onClick={handleSubmit}
              disabled={isLoading}
              className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white text-lg px-12 py-4 rounded-2xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg"
            >
              {isLoading ? (
                <div className="flex items-center">
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full mr-3 animate-spin" />
                  Analyzing Wine...
                </div>
              ) : (
                <div className="flex items-center">
                  <Wine className="w-5 h-5 mr-3" />
                  Predict Wine Quality
                  <Sparkles className="w-5 h-5 ml-3" />
                </div>
              )}
            </button>
          </div>

          {/* Reset Button */}
          <div className="flex justify-center">
            <button
              type="button"
              onClick={handleReset}
              className="text-white/60 hover:text-white transition-colors text-sm flex items-center"
            >
              <RotateCcw className="w-4 h-4 mr-2" />
              Reset Form
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default WineQualityForm