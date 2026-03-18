import vault from "node-vault";
import logger from "../middleware/logger.js";

class VaultService {
  constructor() {
    this.client = vault({
      apiVersion: "v1",
      endpoint: process.env.VAULT_ADDR || "http://vault:8200",
      token: process.env.VAULT_TOKEN,
    });

    this.initialized = false;
  }

  async initialize() {
    try {
      if (this.initialized) return;

      // Check Vault status
      const health = await this.client.health();
      if (!health.initialized) {
        throw new Error("Vault is not initialized");
      }

      // Set up default configuration
      await this.setupSecretEngine();

      this.initialized = true;
      logger.info("Vault service initialized successfully");
    } catch (error) {
      logger.error("Failed to initialize Vault service:", error);
      throw error;
    }
  }

  async setupSecretEngine() {
    try {
      // Mount the KV secrets engine if not already mounted
      await this.client.mounts().then(async (mounts) => {
        if (!mounts["secret/"]) {
          await this.client.mount({
            mount_point: "secret",
            type: "kv",
            options: {
              version: "2",
            },
          });
        }
      });
    } catch (error) {
      logger.error("Failed to setup secret engine:", error);
      throw error;
    }
  }

  async getSecret(path) {
    try {
      const result = await this.client.read(`secret/data/${path}`);
      return result.data.data;
    } catch (error) {
      logger.error(`Failed to get secret at path ${path}:`, error);
      throw error;
    }
  }

  async setSecret(path, data) {
    try {
      await this.client.write(`secret/data/${path}`, { data });
      logger.info(`Secret successfully written to ${path}`);
    } catch (error) {
      logger.error(`Failed to set secret at path ${path}:`, error);
      throw error;
    }
  }

  async deleteSecret(path) {
    try {
      await this.client.delete(`secret/data/${path}`);
      logger.info(`Secret successfully deleted at ${path}`);
    } catch (error) {
      logger.error(`Failed to delete secret at path ${path}:`, error);
      throw error;
    }
  }

  async rotateSecret(path, generateNew) {
    try {
      // Get current secret
      const current = await this.getSecret(path);

      // Generate new secret value
      const newSecret = await generateNew(current);

      // Store new secret
      await this.setSecret(path, newSecret);

      // Return new secret data
      return newSecret;
    } catch (error) {
      logger.error(`Failed to rotate secret at path ${path}:`, error);
      throw error;
    }
  }

  async listSecrets(path) {
    try {
      const result = await this.client.list(`secret/metadata/${path}`);
      return result.data.keys;
    } catch (error) {
      logger.error(`Failed to list secrets at path ${path}:`, error);
      throw error;
    }
  }
}

// Create singleton instance
const vaultService = new VaultService();

export default vaultService;
