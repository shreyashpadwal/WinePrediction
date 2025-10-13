import React from 'react'
import { motion } from 'framer-motion'
import { Wine, Sparkles } from 'lucide-react'

interface LayoutProps {
  children: React.ReactNode
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Animated Background */}
      <div className="absolute inset-0 bg-gradient-to-br from-purple-900 via-pink-800 to-orange-600">
        {/* Floating Wine Elements */}
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute text-white/10"
              initial={{ 
                x: Math.random() * window.innerWidth,
                y: Math.random() * window.innerHeight,
                rotate: Math.random() * 360
              }}
              animate={{
                y: [0, -30, 0],
                rotate: [0, 10, -10, 0],
              }}
              transition={{
                duration: 4 + Math.random() * 2,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
            >
              <Wine size={40 + Math.random() * 20} />
            </motion.div>
          ))}
        </div>

        {/* Sparkle Effects */}
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(20)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute text-white/20"
              initial={{ 
                x: Math.random() * window.innerWidth,
                y: Math.random() * window.innerHeight,
              }}
              animate={{
                scale: [0, 1, 0],
                opacity: [0, 1, 0],
              }}
              transition={{
                duration: 2 + Math.random() * 2,
                repeat: Infinity,
                delay: Math.random() * 3,
              }}
            >
              <Sparkles size={8 + Math.random() * 8} />
            </motion.div>
          ))}
        </div>
      </div>

      {/* Main Content */}
      <div className="relative z-10">
        {/* Header */}
        <motion.header
          className="glassmorphism-strong border-b border-white/20"
          initial={{ y: -100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between h-16">
              {/* Logo */}
              <motion.div
                className="flex items-center space-x-3"
                whileHover={{ scale: 1.05 }}
                transition={{ type: "spring", stiffness: 300 }}
              >
                <div className="w-10 h-10 wine-gradient rounded-xl flex items-center justify-center">
                  <Wine className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h1 className="text-xl font-bold text-white text-shadow">
                    🍷 Wine Quality Predictor
                  </h1>
                  <p className="text-xs text-white/70">
                    Powered by AI & Machine Learning
                  </p>
                </div>
              </motion.div>

              {/* Navigation */}
              <nav className="hidden md:flex items-center space-x-6">
                <motion.a
                  href="#predict"
                  className="text-white/80 hover:text-white transition-colors duration-200"
                  whileHover={{ scale: 1.05 }}
                >
                  Predict
                </motion.a>
                <motion.a
                  href="#about"
                  className="text-white/80 hover:text-white transition-colors duration-200"
                  whileHover={{ scale: 1.05 }}
                >
                  About
                </motion.a>
                <motion.a
                  href="#features"
                  className="text-white/80 hover:text-white transition-colors duration-200"
                  whileHover={{ scale: 1.05 }}
                >
                  Features
                </motion.a>
              </nav>

              {/* Mobile Menu Button */}
              <motion.button
                className="md:hidden text-white/80 hover:text-white"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              </motion.button>
            </div>
          </div>
        </motion.header>

        {/* Main Content Area */}
        <main className="min-h-[calc(100vh-4rem)]">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            {children}
          </motion.div>
        </main>

        {/* Footer */}
        <motion.footer
          className="glassmorphism-strong border-t border-white/20 mt-16"
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div className="flex flex-col md:flex-row items-center justify-between">
              <div className="flex items-center space-x-3 mb-4 md:mb-0">
                <div className="w-8 h-8 wine-gradient rounded-lg flex items-center justify-center">
                  <Wine className="w-5 h-5 text-white" />
                </div>
                <span className="text-white/80 text-sm">
                  🍷 Wine Quality Predictor
                </span>
              </div>
              
              <div className="text-center md:text-right">
                <p className="text-white/60 text-sm mb-2">
                  Powered by Random Forest & Gemini AI
                </p>
                <p className="text-white/40 text-xs">
                  © 2024 Wine Quality Prediction. Built with React & FastAPI.
                </p>
              </div>
            </div>
          </div>
        </motion.footer>
      </div>
    </div>
  )
}

export default Layout
