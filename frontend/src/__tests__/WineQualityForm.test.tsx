import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import WineQualityForm from '../components/WineQualityForm'

// Mock the form submission
const mockOnSubmit = vi.fn()

describe('WineQualityForm', () => {
  beforeEach(() => {
    mockOnSubmit.mockClear()
  })

  it('renders all wine feature inputs', () => {
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    // Check that all 11 wine features are present
    expect(screen.getByLabelText(/fixed acidity/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/volatile acidity/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/citric acid/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/residual sugar/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/chlorides/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/free sulfur dioxide/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/total sulfur dioxide/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/density/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/ph/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/sulphates/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/alcohol content/i)).toBeInTheDocument()
  })

  it('displays sample data buttons', () => {
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    expect(screen.getByText(/high quality red/i)).toBeInTheDocument()
    expect(screen.getByText(/medium quality red/i)).toBeInTheDocument()
    expect(screen.getByText(/low quality red/i)).toBeInTheDocument()
  })

  it('loads sample data when button is clicked', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    const highQualityButton = screen.getByText(/high quality red/i)
    await user.click(highQualityButton)
    
    // Check that values have been updated
    const fixedAcidityInput = screen.getByLabelText(/fixed acidity/i)
    expect(fixedAcidityInput).toHaveValue(8.1)
  })

  it('validates required fields', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    // Clear a required field
    const fixedAcidityInput = screen.getByLabelText(/fixed acidity/i)
    await user.clear(fixedAcidityInput)
    
    // Try to submit
    const submitButton = screen.getByText(/predict wine quality/i)
    await user.click(submitButton)
    
    // Should show validation error
    await waitFor(() => {
      expect(screen.getByText(/fixed acidity is required/i)).toBeInTheDocument()
    })
  })

  it('validates numeric input', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    const fixedAcidityInput = screen.getByLabelText(/fixed acidity/i)
    await user.clear(fixedAcidityInput)
    await user.type(fixedAcidityInput, 'not a number')
    
    const submitButton = screen.getByText(/predict wine quality/i)
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/must be numeric/i)).toBeInTheDocument()
    })
  })

  it('validates min/max values', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    const fixedAcidityInput = screen.getByLabelText(/fixed acidity/i)
    await user.clear(fixedAcidityInput)
    await user.type(fixedAcidityInput, '20') // Above max value of 16
    
    const submitButton = screen.getByText(/predict wine quality/i)
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/maximum value is 16/i)).toBeInTheDocument()
    })
  })

  it('submits form with valid data', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    const submitButton = screen.getByText(/predict wine quality/i)
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith({
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
      })
    })
  })

  it('shows loading state when isLoading is true', () => {
    render(<WineQualityForm onSubmit={mockOnSubmit} isLoading={true} />)
    
    expect(screen.getByText(/analyzing wine/i)).toBeInTheDocument()
    expect(screen.getByText(/predict wine quality/i)).toBeDisabled()
  })

  it('resets form when reset button is clicked', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    // Change a value
    const fixedAcidityInput = screen.getByLabelText(/fixed acidity/i)
    await user.clear(fixedAcidityInput)
    await user.type(fixedAcidityInput, '10')
    
    // Click reset
    const resetButton = screen.getByText(/reset form/i)
    await user.click(resetButton)
    
    // Value should be back to default
    expect(fixedAcidityInput).toHaveValue(7.4)
  })

  it('shows tooltips on hover', async () => {
    const user = userEvent.setup()
    render(<WineQualityForm onSubmit={mockOnSubmit} />)
    
    const infoIcon = screen.getAllByRole('button')[0] // First info icon
    await user.hover(infoIcon)
    
    await waitFor(() => {
      expect(screen.getByText(/fixed acidity contributes/i)).toBeInTheDocument()
    })
  })
})
