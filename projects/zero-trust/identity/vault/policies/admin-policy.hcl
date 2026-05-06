# Admin Policy - Highest level of access
# This policy grants administrative access to manage Vault's core configuration

# Allow managing auth methods broadly across Vault
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth" {
  capabilities = ["read"]
}

# List existing policies
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}

# Read health checks
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Manage key/value secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage PKI secrets engine
path "pki*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage transit secrets engine
path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage token creation
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system configuration
path "sys/config/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system leases
path "sys/leases/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage audit devices
path "sys/audit*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# View audit logs
path "sys/audit-hash/*" {
  capabilities = ["read"]
}

# Manage system capabilities
path "sys/capabilities*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system plugins
path "sys/plugins/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system tools
path "sys/tools/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system internal counters
path "sys/internal/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system wrapping
path "sys/wrapping/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage system replication
path "sys/replication/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
