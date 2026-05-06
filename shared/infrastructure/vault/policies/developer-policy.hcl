# Developer Policy - Restricted access for development teams
# This policy grants limited access to specific secrets and tools needed for development

# Read health status
path "sys/health" {
  capabilities = ["read"]
}

# List available secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}

# Manage application secrets in specific paths
path "secret/data/apps/${identity.entity.metadata.team}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List application secrets
path "secret/metadata/apps/${identity.entity.metadata.team}/*" {
  capabilities = ["list"]
}

# Access to development-specific KV store
path "secret/data/development/${identity.entity.metadata.team}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List development secrets
path "secret/metadata/development/${identity.entity.metadata.team}/*" {
  capabilities = ["list"]
}

# Access to shared development resources
path "secret/data/shared/development/*" {
  capabilities = ["read", "list"]
}

# Access to development certificates
path "pki/issue/development" {
  capabilities = ["create", "update"]
}

# Read development certificate configuration
path "pki/config/urls" {
  capabilities = ["read"]
}

# Generate dynamic database credentials
path "database/creds/${identity.entity.metadata.team}-${identity.entity.metadata.environment}" {
  capabilities = ["read"]
}

# Read database connection configuration
path "database/config" {
  capabilities = ["read"]
}

# Use the transit secrets engine for encryption operations
path "transit/encrypt/${identity.entity.metadata.team}/*" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/${identity.entity.metadata.team}/*" {
  capabilities = ["create", "update"]
}

# Allow developers to create short-lived tokens for CI/CD
path "auth/token/create/development" {
  capabilities = ["create", "update"]
}

# View own token information
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Renew own tokens
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Revoke own tokens
path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# Access to AWS dynamic credentials
path "aws/creds/${identity.entity.metadata.team}-${identity.entity.metadata.environment}" {
  capabilities = ["read"]
}

# Access to Azure dynamic credentials
path "azure/creds/${identity.entity.metadata.team}-${identity.entity.metadata.environment}" {
  capabilities = ["read"]
}

# Access to GCP dynamic credentials
path "gcp/token/${identity.entity.metadata.team}-${identity.entity.metadata.environment}" {
  capabilities = ["read"]
}

# Access to Kubernetes service account tokens
path "kubernetes/creds/${identity.entity.metadata.team}-${identity.entity.metadata.environment}" {
  capabilities = ["read"]
}

# Allow developers to use the tools endpoint for hash/random/wrap operations
path "sys/tools/hash" {
  capabilities = ["update"]
}

path "sys/tools/random" {
  capabilities = ["update"]
}

path "sys/wrapping/wrap" {
  capabilities = ["update"]
}

path "sys/wrapping/unwrap" {
  capabilities = ["update"]
}

# Allow developers to view their own entity information
path "identity/entity/id/${identity.entity.id}" {
  capabilities = ["read"]
}

# Allow developers to view their own groups
path "identity/group/id/*" {
  capabilities = ["read"]
}

# Deny access to system configuration
path "sys/config/*" {
  capabilities = ["deny"]
}

# Deny access to audit logs
path "sys/audit*" {
  capabilities = ["deny"]
}

# Deny access to policy management
path "sys/policies/*" {
  capabilities = ["deny"]
}
