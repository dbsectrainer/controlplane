// Global setup for integration tests
export default async () => {
  // Set environment variables for testing
  process.env.NODE_ENV = "test";
  process.env.PORT = 3001;

  // Add any other setup needed (e.g., database connections)
  global.__TEST_SERVER__ = `http://localhost:${process.env.PORT}`;
};
