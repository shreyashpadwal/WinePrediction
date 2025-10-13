import React from 'react'
import { motion } from 'framer-motion'

const LoadingAnimation: React.FC = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-[200px]">
      <motion.div
        className="relative w-20 h-20"
        animate={{ rotate: 360 }}
        transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
      >
        {/* Wine Bottle */}
        <motion.div
          className="absolute top-0 left-1/2 transform -translate-x-1/2 w-8 h-16 bg-gradient-to-b from-amber-200 to-amber-800 rounded-t-lg"
          animate={{ 
            scaleY: [1, 0.8, 1],
          }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        />
        
        {/* Wine Pouring */}
        <motion.div
          className="absolute top-4 left-1/2 transform -translate-x-1/2 w-1 h-8 bg-gradient-to-b from-red-400 to-red-600 rounded-full"
          animate={{ 
            scaleY: [0, 1, 0],
            opacity: [0, 1, 0],
          }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
        />
        
        {/* Wine Glass */}
        <motion.div
          className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-12 h-12 border-2 border-white/30 rounded-b-full"
          animate={{ 
            scale: [1, 1.05, 1],
          }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        />
        
        {/* Wine in Glass */}
        <motion.div
          className="absolute bottom-1 left-1/2 transform -translate-x-1/2 w-10 h-10 bg-gradient-to-t from-red-600 to-red-400 rounded-b-full"
          animate={{ 
            scaleY: [0, 0.3, 0.6, 0.8, 1],
          }}
          transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
        />
      </motion.div>
      
      <motion.p
        className="text-white/80 mt-4 text-sm"
        animate={{ opacity: [0.5, 1, 0.5] }}
        transition={{ duration: 2, repeat: Infinity }}
      >
        Analyzing wine composition...
      </motion.p>
    </div>
  )
}

export default LoadingAnimation
