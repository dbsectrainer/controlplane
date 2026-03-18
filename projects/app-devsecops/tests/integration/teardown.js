// Global teardown for integration tests
export default async () => {
  // Clean up any resources (e.g., close database connections)
  delete global.__TEST_SERVER__;
};
