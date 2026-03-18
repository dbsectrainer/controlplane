// Setup for each test file
import { jest } from "@jest/globals";
import { server, startServer } from "../../src/app.js";

beforeAll(async () => {
  await startServer();
  console.info(`Test server running on port ${process.env.PORT}`);
});

afterAll(async () => {
  // Close the server after tests
  await new Promise((resolve) => {
    server.close(() => {
      console.info("Test server closed");
      resolve();
    });
  });
});

beforeEach(() => {
  // Setup before each test
  jest.setTimeout(30000);
});

afterEach(() => {
  // Cleanup after each test
  jest.clearAllMocks();
});
