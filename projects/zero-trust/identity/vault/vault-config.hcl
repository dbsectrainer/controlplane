# Vault Server Configuration

# Storage Backend - Using Kubernetes
storage "kubernetes" {
  path = "/vault/data"
  service_account = "vault"
}

# Listener Configuration
listener "tcp" {
  address = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_cert_file = "/vault/tls/tls.crt"
  tls_key_file  = "/vault/tls/tls.key"
  tls_min_version = "tls12"
  
  # Enable CORS
  cors_enabled = true
  cors_allowed_origins = ["https://*.example.com"]
  cors_allowed_headers = ["Content-Type", "X-Requested-With", "X-Vault-Token", "Authorization"]
}

# Telemetry Configuration
telemetry {
  prometheus_retention_time = "24h"
  disable_hostname = true
}

# Enable UI
ui = true

# API Configuration
api_addr = "https://vault.example.com"
cluster_addr = "https://vault.example.com:8201"

# Enable Auditing
audit "file" {
  path = "/vault/logs/audit.log"
  log_raw = false
}

# Seal Configuration (using AWS KMS)
seal "awskms" {
  region = "us-east-1"
  kms_key_id = "alias/vault-key"
}

# Plugin Configuration
plugin_directory = "/vault/plugins"

# Service Registration
service_registration "kubernetes" {
  namespace = "security"
}

# Enable Auto-Auth
auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role = "vault-auth"
    }
  }
}

# Cache Configuration
cache {
  use_auto_auth_token = true
}

# Rate Limiting
rate_limit {
  enable = true
  # 500 requests per second
  rate = 500
}
