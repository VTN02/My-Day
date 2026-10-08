/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          indigo: '#4F46E5',
          violet: '#7C3AED',
          cyan: '#06B6D4',
        },
        mint: '#10B981',
        coral: '#F97373',
        surface: {
          light: '#F7F8FC',
          card: '#FFFFFF',
          dark: '#0B1020',
          darkCard: '#151B2E',
        },
      },
    },
  },
  plugins: [],
};
