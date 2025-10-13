#!/usr/bin/env node

/**
 * Frontend Setup Verification Script
 * Checks if all required files and configurations are in place
 */

const fs = require('fs')
const path = require('path')

console.log('🍷 Wine Quality Predictor - Frontend Setup Verification')
console.log('=' .repeat(60))

const requiredFiles = [
  'package.json',
  'vite.config.ts',
  'tsconfig.json',
  'tailwind.config.js',
  'index.html',
  'src/main.tsx',
  'src/App.tsx',
  'src/components/Layout.tsx',
  'src/components/WineQualityForm.tsx',
  'src/components/ResultsDisplay.tsx',
  'src/components/ComparisonTable.tsx',
  'src/services/api.ts',
  'src/types/wine.ts',
  'src/styles/index.css',
  'src/utils/constants.ts',
  'src/utils/errorMessages.ts',
]

const requiredDirs = [
  'src',
  'src/components',
  'src/services',
  'src/types',
  'src/styles',
  'src/utils',
  'src/__tests__',
  'src/test',
]

let allGood = true

// Check directories
console.log('\n📁 Checking directories...')
requiredDirs.forEach(dir => {
  if (fs.existsSync(dir)) {
    console.log(`✅ ${dir}`)
  } else {
    console.log(`❌ ${dir} - MISSING`)
    allGood = false
  }
})

// Check files
console.log('\n📄 Checking files...')
requiredFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file}`)
  } else {
    console.log(`❌ ${file} - MISSING`)
    allGood = false
  }
})

// Check package.json dependencies
console.log('\n📦 Checking dependencies...')
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'))
  const requiredDeps = [
    'react',
    'react-dom',
    'typescript',
    'vite',
    'tailwindcss',
    'framer-motion',
    'axios',
    'react-hook-form',
    'lucide-react',
    'react-hot-toast'
  ]
  
  const deps = { ...packageJson.dependencies, ...packageJson.devDependencies }
  
  requiredDeps.forEach(dep => {
    if (deps[dep]) {
      console.log(`✅ ${dep} (${deps[dep]})`)
    } else {
      console.log(`❌ ${dep} - MISSING`)
      allGood = false
    }
  })
} catch (error) {
  console.log('❌ Error reading package.json')
  allGood = false
}

// Check TypeScript configuration
console.log('\n🔧 Checking TypeScript configuration...')
try {
  const tsconfig = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'))
  if (tsconfig.compilerOptions?.jsx === 'react-jsx') {
    console.log('✅ React JSX configured')
  } else {
    console.log('❌ React JSX not configured')
    allGood = false
  }
} catch (error) {
  console.log('❌ Error reading tsconfig.json')
  allGood = false
}

// Check Tailwind configuration
console.log('\n🎨 Checking Tailwind configuration...')
try {
  const tailwindConfig = fs.readFileSync('tailwind.config.js', 'utf8')
  if (tailwindConfig.includes('wine-gradient') && tailwindConfig.includes('glassmorphism')) {
    console.log('✅ Custom wine theme configured')
  } else {
    console.log('❌ Custom wine theme not configured')
    allGood = false
  }
} catch (error) {
  console.log('❌ Error reading tailwind.config.js')
  allGood = false
}

console.log('\n' + '=' .repeat(60))
console.log('📊 VERIFICATION SUMMARY:')

if (allGood) {
  console.log('🎉 ALL CHECKS PASSED!')
  console.log('\n🚀 Frontend setup is complete!')
  console.log('\n📋 Next steps:')
  console.log('1. Install dependencies: npm install')
  console.log('2. Start development server: npm run dev')
  console.log('3. Open http://localhost:3000 in your browser')
  console.log('4. Make sure the backend is running on http://localhost:8000')
  console.log('\n✨ Your wine quality predictor frontend is ready!')
} else {
  console.log('❌ SOME CHECKS FAILED!')
  console.log('Please fix the issues above before proceeding.')
}

console.log('\n🍷 Cheers to great wine predictions!')
