# 🍷 Wine Quality Predictor - Frontend

A beautiful, modern React frontend for the Wine Quality Prediction application built with TypeScript, Tailwind CSS, and Framer Motion.

## ✨ Features

- **🎨 Beautiful UI**: Wine-themed design with glassmorphism effects
- **📱 Responsive**: Mobile-first design that works on all devices
- **⚡ Fast**: Built with Vite for lightning-fast development and builds
- **🎭 Animations**: Smooth animations powered by Framer Motion
- **🔍 Form Validation**: Real-time validation with React Hook Form
- **🤖 AI Integration**: Seamless integration with Gemini AI for insights
- **📊 Model Comparison**: Visual comparison of multiple ML models
- **🌙 Dark Mode**: Elegant dark theme optimized for wine aesthetics

## 🛠️ Tech Stack

- **React 18** - Modern React with hooks
- **TypeScript** - Type-safe development
- **Vite** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **Framer Motion** - Production-ready motion library
- **React Hook Form** - Performant forms with easy validation
- **Axios** - HTTP client for API communication
- **Lucide React** - Beautiful icons
- **React Hot Toast** - Elegant notifications

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Backend API running on `http://localhost:8000`

### Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start development server:**
   ```bash
   npm run dev
   ```

3. **Open your browser:**
   Navigate to `http://localhost:3000`

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm test` - Run tests

## 🎨 Design System

### Colors

The app uses a custom wine-themed color palette:

- **Burgundy**: Primary wine color (#ec4899)
- **Rose**: Secondary wine color (#f43f5e) 
- **Gold**: Accent color (#f59e0b)
- **Wine**: Neutral tones for backgrounds

### Components

- **Layout**: Main app layout with header and footer
- **WineQualityForm**: Interactive form with 11 wine parameters
- **ResultsDisplay**: Beautiful results with AI insights
- **ComparisonTable**: Model comparison visualization

### Animations

- **Page Transitions**: Smooth transitions between states
- **Form Animations**: Staggered input animations
- **Loading States**: Wine pouring animation
- **Results**: Scale and fade animations
- **Confetti**: Celebration effect for good predictions

## 📱 Responsive Design

The app is built mobile-first and includes:

- **Mobile**: Single column layout, touch-friendly inputs
- **Tablet**: Two-column form layout
- **Desktop**: Full layout with sidebar navigation
- **Large Screens**: Optimized spacing and typography

## 🔧 Configuration

### Environment Variables

Create a `.env.local` file:

```env
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_APP_NAME=Wine Quality Predictor
```

### API Integration

The frontend connects to the FastAPI backend:

- **Base URL**: `http://localhost:8000/api/v1`
- **Endpoints**: 
  - `POST /prediction/predict` - Single prediction
  - `POST /prediction/predict/compare` - Model comparison
  - `GET /prediction/health` - Health check

## 🎯 Key Features

### Wine Quality Form

- **11 Input Fields**: All wine chemical parameters
- **Real-time Validation**: Instant feedback on input values
- **Visual Sliders**: Color-coded value indicators
- **Sample Data**: Pre-filled examples for testing
- **Tooltips**: Detailed explanations for each parameter

### Results Display

- **Quality Prediction**: Clear good/bad classification
- **Confidence Score**: Circular progress indicator
- **AI Insights**: Typewriter effect for Gemini explanations
- **Model Comparison**: Collapsible comparison table
- **Download Report**: Export results as JSON

### Error Handling

- **Network Errors**: User-friendly error messages
- **Validation Errors**: Field-specific error display
- **Retry Logic**: Automatic retry for failed requests
- **Fallback States**: Graceful degradation when services fail

## 🧪 Testing

The app includes comprehensive testing:

```bash
# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

## 📦 Build & Deployment

### Production Build

```bash
npm run build
```

This creates a `dist` folder with optimized assets.

### Deployment Options

- **Vercel**: Zero-config deployment
- **Netlify**: Drag and drop deployment
- **GitHub Pages**: Static site hosting
- **Docker**: Containerized deployment

### Docker Deployment

```dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

If you encounter any issues:

1. Check the browser console for errors
2. Verify the backend API is running
3. Check network connectivity
4. Review the API documentation

## 🔮 Future Enhancements

- **Wine Database**: Integration with wine databases
- **User Accounts**: Save and manage predictions
- **Advanced Analytics**: Historical prediction trends
- **Mobile App**: React Native version
- **Offline Support**: PWA capabilities
- **Multi-language**: Internationalization support
