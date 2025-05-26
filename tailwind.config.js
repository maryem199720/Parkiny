/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],
  theme: {
    extend: {
      colors: {
        primary: "#6A1B9A",
        'primary-purple': '#6A1B9A',
        secondary: "#D4AF37",
        dark: "#1E0D2B",
        'dark-purple': '#1E0D2B',
        gold: {
          100: "#F9F3D6",
          200: "#F5E7B8",
          300: "#F0DB9A",
          400: "#EBD07C",
          500: "#D4AF37",
          600: "#B8972E",
          700: "#9C7F25",
          800: "#80671C",
          900: "#644F13",
        },
        blue: {
          500: "#3498db",
        },
        green: {
          500: "#2ecc71",
        },
        orange: {
          500: "#f39c12",
        },
        red: {
          500: "#e74c3c",
        },
        gray: {
          800: "#2c3e50",
          600: "#7f8c8d",
          200: "#ecf0f1",
          100: "#f8f9fa",
        },
      },
      borderRadius: {
        none: "0px",
        sm: "4px",
        DEFAULT: "8px",
        md: "12px",
        lg: "16px",
        xl: "20px",
        "2xl": "24px",
        "3xl": "32px",
        full: "9999px",
        button: "8px",
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        display: ['Poppins', 'sans-serif'],
        roboto: ['Roboto', 'sans-serif'],
      },
      boxShadow: {
        'reservation': '0 8px 30px rgba(0, 0, 0, 0.08)',
        'confirmation': '0 5px 20px rgba(0, 0, 0, 0.1)',
      },
    },
  },
  plugins: [],
};