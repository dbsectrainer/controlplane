export default {
  testEnvironment: "node",
  testMatch: ["**/tests/integration/**/*.test.js"],
  transform: {},
  globalSetup: "./tests/integration/setup.js",
  globalTeardown: "./tests/integration/teardown.js",
  setupFilesAfterEnv: ["./tests/integration/setupTests.js"],
  testTimeout: 30000,
  coverageDirectory: "coverage/integration",
};
