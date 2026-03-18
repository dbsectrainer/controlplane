# Vault Local Development Configuration
# NOTE: This is for local demo use only. Do NOT use in production.
# For production config, see vault-config-prod.hcl

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true

  cors_enabled         = true
  cors_allowed_origins = ["*"]
  cors_allowed_headers = ["Content-Type", "X-Requested-With", "X-Vault-Token", "Authorization"]
}

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = true
}

ui          = true
api_addr    = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"
