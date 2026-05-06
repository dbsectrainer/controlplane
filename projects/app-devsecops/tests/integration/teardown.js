// Global teardown for integration tests
export default async () => {
  // Clean up any resources (e.g., close database connections)
  // eslint-disable-next-line no-underscore-dangle
  delete global.__TEST_SERVER__;
};
