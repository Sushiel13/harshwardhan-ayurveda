import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        forest: { 50: '#EEF4F1', 100: '#D5E5DD', 300: '#7FA593', 500: '#2F5E4C', 700: '#183D31', 800: '#11302A', 900: '#0B211C', 950: '#071612' },
        ivory: { DEFAULT: '#F8F4EB', 50: '#FCFAF5', 100: '#F8F4EB', 200: '#EFE7D6' },
        brass: { 300: '#E2C48A', 400: '#D2AA62', 500: '#B8893B', 600: '#966C2A', 700: '#73521F' },
        clay: { 500: '#B5603F' },
        ink: { DEFAULT: '#1C2420', soft: '#4B5650', mute: '#7A847F' },
      },
      fontFamily: {
        display: ['"Fraunces"', 'Georgia', 'serif'],
        sans: ['"Manrope"', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        soft: '0 1px 2px rgba(11,33,28,.04), 0 8px 24px -8px rgba(11,33,28,.12)',
        lift: '0 2px 4px rgba(11,33,28,.05), 0 24px 48px -16px rgba(11,33,28,.22)',
      },
      borderRadius: { xl2: '1.25rem' },
    },
  },
  plugins: [],
};
export default config;
