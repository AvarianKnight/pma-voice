/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        'gray-pma': "rgb(148, 150, 151);",
        'gray-talking': "rgba(255, 255, 255, 0.822)",
      },
      textShadow: {
        black: '1.25px 0 0 #000, 0 -1.25px 0 #000, 0 1.25px 0 #000, -1.25px 0 0 #000',
      },
    },
  },
  plugins: [
    require('tailwindcss-textshadow'),
  ],
};
