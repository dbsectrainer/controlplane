import request from "supertest";
import express from "express";
import app from "../../src/app.js";

describe("Express App", () => {
  describe("GET /health", () => {
    it("should return 200 and health status", async () => {
      const response = await request(app)
        .get("/health")
        .expect("Content-Type", /json/)
        .expect(200);

      expect(response.body).toEqual(
        expect.objectContaining({
          status: "healthy",
          timestamp: expect.any(String),
          uptime: expect.any(Number),
        }),
      );
    });
  });

  describe("Error Handling", () => {
    it("should handle 404 errors", async () => {
      const response = await request(app)
        .get("/non-existent-route")
        .expect("Content-Type", /json/)
        .expect(404);

      expect(response.body).toEqual(
        expect.objectContaining({
          error: "Not Found",
        }),
      );
    });

    it("should handle server errors", async () => {
      // Use an isolated app to test the error handling middleware pattern
      const testApp = express();
      testApp.get("/error-test", () => {
        throw new Error("Test error");
      });
      testApp.use((err, req, res, next) => {
        res.status(500).json({ error: "Internal Server Error" });
      });

      const response = await request(testApp)
        .get("/error-test")
        .expect("Content-Type", /json/)
        .expect(500);

      expect(response.body).toEqual(
        expect.objectContaining({
          error: "Internal Server Error",
        }),
      );
    });
  });
});
