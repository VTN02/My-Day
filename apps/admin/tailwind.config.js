/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './lib/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#EFF6FF',
          100: '#DBEAFE',
          200: '#BFDBFE',
          300: '#93C5FD',
          400: '#60A5FA',
          500: '#3B82F6',
          600: '#2563EB', // Primary Royal Blue
          700: '#1D4ED8', // Primary Hover
          800: '#1E40AF', // Primary Dark
          900: '#1E3A8A',
        },
        admin: {
          bg: '#F6F8FC',
          sidebar: '#FFFFFF',
          card: '#FFFFFF',
          border: '#E2E8F0',
          text: '#1E293B',
          muted: '#64748B',
          success: '#16A34A',
          warning: '#D97706',
          error: '#DC2626',
          info: '#0284C7',
        },
      },
    },
  },
  plugins: [],
};
