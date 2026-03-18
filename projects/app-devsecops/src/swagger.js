import swaggerJsdoc from "swagger-jsdoc";

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Node.js DevSecOps API",
      version: "1.0.0",
      description: "API documentation for the Node.js DevSecOps Pipeline",
      license: {
        name: "MIT",
        url: "https://opensource.org/licenses/MIT",
      },
    },
    servers: [
      {
        url: "http://localhost:3000",
        description: "Development server",
      },
    ],
  },
  apis: ["./src/**/*.js"], // Path to the API docs
};

export const specs = swaggerJsdoc(options);
