import { createServer } from "http";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import swaggerUi from "swagger-ui-express";
import { specs } from "./swagger.js";
import { metricsMiddleware, metricsHandler } from "./middleware/metrics.js";
import { requestLogger, errorLogger } from "./middleware/logger.js";
import tasksRouter from "./routes/tasks.js";
import vaultService from "./services/vault.js";
import logger from "./middleware/logger.js";

// Load environment variables
dotenv.config();

const app = express();

// Initialize Vault (optional - app runs without it)
vaultService.initialize().catch((error) => {
  logger.warn(
    "Vault unavailable, continuing without Vault integration:",
    error.message,
  );
});

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(requestLogger); // Structured request logging
app.use(express.json()); // Parse JSON bodies
app.use(metricsMiddleware); // Prometheus metrics

// Routes
app.use("/api/tasks", tasksRouter);

// API Documentation
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(specs));

// Metrics endpoint
app.get("/metrics", metricsHandler);

/**
 * @openapi
 * /:
 *   get:
 *     summary: Root endpoint
 *     description: Returns basic API information
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 version:
 *                   type: string
 *                 endpoints:
 *                   type: object
 */
app.get("/", (req, res) => {
  res.json({
    message: "Welcome to the DevOps Pipeline Demo",
    version: "1.0.0",
    endpoints: {
      health: "/health",
    },
  });
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// 404 handler - after all routes, before error handler
app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

// Error logging middleware
app.use(errorLogger);

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error("Unhandled error:", err);
  res.status(500).json({
    error: "Internal Server Error",
    message: process.env.NODE_ENV === "development" ? err.message : undefined,
  });
});

const PORT = process.env.PORT || 3000;
const server = createServer(app);

export function startServer() {
  return new Promise((resolve) => {
    server.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
      resolve(server);
    });
  });
}

// Only auto-start when not in test mode
if (process.env.NODE_ENV !== "test") {
  startServer();
}

export { app as default, server };
