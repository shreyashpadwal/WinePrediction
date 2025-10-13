import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Info } from 'lucide-react'

interface InfoTooltipProps {
  content: string
  title?: string
  example?: string
  children?: React.ReactNode
}

const InfoTooltip: React.FC<InfoTooltipProps> = ({ 
  content, 
  title, 
  example, 
  children 
}) => {
  const [isVisible, setIsVisible] = useState(false)

  return (
    <div className="relative inline-block">
      <div
        onMouseEnter={() => setIsVisible(true)}
        onMouseLeave={() => setIsVisible(false)}
        className="cursor-help"
      >
        {children || (
          <Info className="w-4 h-4 text-white/60 hover:text-white transition-colors" />
        )}
      </div>
      
      <AnimatePresence>
        {isVisible && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.8, y: 10 }}
            transition={{ duration: 0.2 }}
            className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 w-64 p-3 glassmorphism-strong rounded-lg text-xs text-white z-50 pointer-events-none"
          >
            {title && (
              <div className="font-semibold mb-1 text-white">{title}</div>
            )}
            <div className="text-white/90 mb-2 leading-relaxed">{content}</div>
            {example && (
              <div className="text-white/60 italic">Example: {example}</div>
            )}
            <div className="absolute top-full left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-transparent border-t-white/20"></div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default InfoTooltip
