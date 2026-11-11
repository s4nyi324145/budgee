const { colors } = require('./src/theme/colors');
const { spacing } = require('./src/theme/spacing');
const { radii } = require('./src/theme/radii');
const { fontSize } = require('./src/theme/typography');

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{ts,tsx}', './src/**/*.{ts,tsx}'],
  presets: [require('nativewind/preset')],
  // Follow the OS light/dark setting. Components use `dark:` variants with the *-dark tokens.
  darkMode: 'media',
  theme: {
    extend: {
      colors,
      spacing,
      borderRadius: radii,
      fontSize,
    },
  },
  plugins: [],
};
