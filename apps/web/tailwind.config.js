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
          DEFAULT: '#1565C0',
          blue: '#1565C0',
          indigo: '#1565C0',
          secondary: '#0288D1',
          cyan: '#4DD0E1',
        },
        secondary: '#0288D1',
        accent: '#4DD0E1',
        mint: '#10B981',
        coral: '#F97373',
        surface: {
          light: '#F5F9FC',
          card: '#FFFFFF',
          dark: '#0D1B2A',
          darkCard: '#1B263B',
        },
        brandText: {
          DEFAULT: '#172B4D',
          light: '#172B4D',
          dark: '#F1F5F9',
        },
      },
    },
  },
  plugins: [],
};
