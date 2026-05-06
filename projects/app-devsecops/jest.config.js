export default {
  testEnvironment: "node",
  testMatch: ["**/tests/unit/**/*.test.js"],
  transform: {},
  coverageDirectory: "coverage/unit",
  collectCoverageFrom: ["src/**/*.js"],
};
