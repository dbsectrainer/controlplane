module.exports = {
  env: { es2022: true, node: true, jest: true },
  extends: ["airbnb-base"],
  plugins: ["import"],
  parserOptions: { ecmaVersion: 2022, sourceType: "module" },
  rules: {
    "no-console": "warn",
    "import/extensions": ["error", "ignorePackages", { js: "always" }],
    "import/prefer-default-export": "off",
  },
  ignorePatterns: ["node_modules/", "coverage/"],
};
