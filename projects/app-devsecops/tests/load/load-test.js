import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 20 }, // Ramp up to 20 users
    { duration: "3m", target: 20 }, // Stay at 20 users
    { duration: "1m", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests must complete below 500ms
    http_req_failed: ["rate<0.01"], // Less than 1% of requests can fail
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  // Test root endpoint
  const rootResponse = http.get(`${BASE_URL}/`);
  check(rootResponse, {
    "root status is 200": (r) => r.status === 200,
    "root has correct message": (r) =>
      r.json().message === "Welcome to the DevOps Pipeline Demo",
  });

  // Test health endpoint
  const healthResponse = http.get(`${BASE_URL}/health`);
  check(healthResponse, {
    "health status is 200": (r) => r.status === 200,
    "health check returns healthy": (r) => r.json().status === "healthy",
  });

  // Test tasks API
  const tasksResponse = http.get(`${BASE_URL}/api/tasks`);
  check(tasksResponse, {
    "tasks status is 200": (r) => r.status === 200,
    "tasks returns array": (r) => Array.isArray(r.json()),
  });

  // Create a new task
  const createTaskResponse = http.post(
    `${BASE_URL}/api/tasks`,
    JSON.stringify({
      title: "Load Test Task",
    }),
    {
      headers: { "Content-Type": "application/json" },
    },
  );
  check(createTaskResponse, {
    "create task status is 201": (r) => r.status === 201,
    "created task has title": (r) => r.json().title === "Load Test Task",
  });

  sleep(1);
}

export function handleSummary(data) {
  return {
    stdout: JSON.stringify(data, null, 2),
    "summary.json": JSON.stringify(data),
    "summary.html": generateHtmlReport(data),
  };
}

function generateHtmlReport(data) {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <title>Load Test Report</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
          th { background-color: #f2f2f2; }
          .metric-good { color: green; }
          .metric-bad { color: red; }
        </style>
      </head>
      <body>
        <h1>Load Test Results</h1>
        <h2>Summary</h2>
        <table>
          <tr>
            <th>Metric</th>
            <th>Value</th>
          </tr>
          <tr>
            <td>Total Requests</td>
            <td>${data.metrics.http_reqs.count}</td>
          </tr>
          <tr>
            <td>Failed Requests</td>
            <td class="${data.metrics.http_req_failed.rate > 0.01 ? "metric-bad" : "metric-good"}">
              ${(data.metrics.http_req_failed.rate * 100).toFixed(2)}%
            </td>
          </tr>
          <tr>
            <td>95th Percentile Response Time</td>
            <td class="${data.metrics.http_req_duration.p95 > 500 ? "metric-bad" : "metric-good"}">
              ${data.metrics.http_req_duration.p95.toFixed(2)}ms
            </td>
          </tr>
        </table>
      </body>
    </html>
  `;
}
