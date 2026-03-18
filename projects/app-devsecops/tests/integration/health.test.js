import axios from "axios";

describe("Health Check Integration", () => {
  let baseUrl;

  beforeAll(() => {
    baseUrl = global.__TEST_SERVER__;
  });

  describe("Health Endpoint", () => {
    it("should be available and return correct data structure", async () => {
      const response = await axios.get(`${baseUrl}/health`);

      expect(response.status).toBe(200);
      expect(response.data).toEqual(
        expect.objectContaining({
          status: "healthy",
          timestamp: expect.any(String),
          uptime: expect.any(Number),
        }),
      );
    });

    it("should return proper timestamp format", async () => {
      const response = await axios.get(`${baseUrl}/health`);

      // Verify timestamp is valid ISO string
      expect(() => new Date(response.data.timestamp)).not.toThrow();
      expect(response.data.timestamp).toMatch(
        /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/,
      );
    });
  });

  describe("Error Handling", () => {
    it("should handle non-existent routes", async () => {
      try {
        await axios.get(`${baseUrl}/non-existent`);
        fail("Should have thrown an error");
      } catch (error) {
        expect(error.response.status).toBe(404);
        expect(error.response.data).toEqual(
          expect.objectContaining({
            error: "Not Found",
          }),
        );
      }
    });

    it("should maintain CORS headers", async () => {
      const response = await axios.get(`${baseUrl}/health`, {
        validateStatus: () => true,
      });

      expect(response.headers["access-control-allow-origin"]).toBeDefined();
    });

    it("should include security headers", async () => {
      const response = await axios.get(`${baseUrl}/health`);

      // Check for essential security headers
      expect(response.headers).toEqual(
        expect.objectContaining({
          "x-dns-prefetch-control": expect.any(String),
          "x-frame-options": expect.any(String),
          "strict-transport-security": expect.any(String),
          "x-download-options": expect.any(String),
          "x-content-type-options": expect.any(String),
          "x-xss-protection": expect.any(String),
        }),
      );
    });
  });

  describe("Performance", () => {
    it("should respond to health check within 200ms", async () => {
      const start = Date.now();
      await axios.get(`${baseUrl}/health`);
      const duration = Date.now() - start;

      expect(duration).toBeLessThan(200);
    });
  });
});
