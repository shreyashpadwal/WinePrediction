import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from '../App'

// Mock the API service
vi.mock('../services/api', () => ({
  default: {
    testConnection: vi.fn().mockResolvedValue(true),
    predictWineQuality: vi.fn(),
    compareModels: vi.fn(),
  }
}))

describe('App', () => {
  it('renders without crashing', () => {
    render(<App />)
    expect(screen.getByText('🍷 Wine Quality Predictor')).toBeInTheDocument()
  })

  it('displays the main form initially', () => {
    render(<App />)
    expect(screen.getByText('Wine Quality Analysis')).toBeInTheDocument()
  })

  it('shows API connection status', () => {
    render(<App />)
    // The API connection status should be displayed
    expect(screen.getByText(/API Connected|API Disconnected/)).toBeInTheDocument()
  })
})
