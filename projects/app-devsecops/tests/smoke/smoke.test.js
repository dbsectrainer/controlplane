import axios from "axios";

describe("Smoke Tests", () => {
  const baseUrl = process.env.TEST_URL || "http://localhost:3000";

  test("Server is running and health endpoint responds", async () => {
    const response = await axios.get(`${baseUrl}/health`);
    expect(response.status).toBe(200);
    expect(response.data.status).toBe("healthy");
  });

  test("Application responds with correct headers", async () => {
    const response = await axios.get(baseUrl);
    expect(response.headers["x-content-type-options"]).toBe("nosniff");
    expect(response.headers["x-frame-options"]).toBe("DENY");
    expect(response.headers["strict-transport-security"]).toBeDefined();
  });

  test("Non-existent endpoint returns 404", async () => {
    try {
      await axios.get(`${baseUrl}/non-existent-path-${Date.now()}`);
    } catch (error) {
      expect(error.response.status).toBe(404);
    }
  });

  // Add more smoke tests based on critical application functionality
  // For example:
  // - Authentication endpoints
  // - Critical business workflows
  // - API versioning
  // - Rate limiting
});
