#!/bin/sh
# vault-init.sh — Seeds Vault dev instance with policies and secrets
set -e

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"

echo "[vault-init] Waiting for Vault to be ready..."
until vault status -address="$VAULT_ADDR" > /dev/null 2>&1; do
  sleep 2
done
echo "[vault-init] Vault is ready."

export VAULT_ADDR VAULT_TOKEN

# Enable KV secrets engine v2
vault secrets enable -version=2 kv 2>/dev/null || echo "[vault-init] kv already enabled"

# Write demo application secrets
vault kv put kv/demo-app/config \
  db_password="demo-db-pass" \
  api_key="demo-api-key-$(date +%s)" \
  jwt_secret="demo-jwt-secret"

vault kv put kv/demo-app/keycloak \
  client_secret="demo-app-secret" \
  realm="zero-trust"

# Write Vault policies
vault policy write admin /vault/policies/admin-policy.hcl
vault policy write developer /vault/policies/developer-policy.hcl
vault policy write auditor /vault/policies/auditor-policy.hcl

# Enable userpass auth for demo logins
vault auth enable userpass 2>/dev/null || echo "[vault-init] userpass already enabled"
vault write auth/userpass/users/admin-user password="Admin@1234" policies="admin"
vault write auth/userpass/users/dev-user password="Dev@1234" policies="developer"
vault write auth/userpass/users/auditor-user password="Audit@1234" policies="auditor"

echo "[vault-init] Vault initialization complete."
echo "[vault-init] Secrets written: kv/demo-app/config, kv/demo-app/keycloak"
echo "[vault-init] Policies loaded: admin, developer, auditor"
