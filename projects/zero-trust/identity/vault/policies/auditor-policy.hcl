# Auditor Policy - Read-only access for security auditing
# This policy grants access to audit logs, monitoring, and compliance verification

# Read health status
path "sys/health"
{
  capabilities = ["read"]
}

# Read audit logs
path "sys/audit"
{
  capabilities = ["read"]
}

path "sys/audit/*"
{
  capabilities = ["read"]
}

# Read audit hash values
path "sys/audit-hash/*"
{
  capabilities = ["read"]
}

# List and read all policies
path "sys/policies/acl"
{
  capabilities = ["read", "list"]
}

path "sys/policies/acl/*"
{
  capabilities = ["read"]
}

# List and read auth methods
path "sys/auth"
{
  capabilities = ["read", "list"]
}

path "sys/auth/*"
{
  capabilities = ["read"]
}

# List and read secrets engines configuration
path "sys/mounts"
{
  capabilities = ["read", "list"]
}

path "sys/mounts/*"
{
  capabilities = ["read"]
}

# Read seal status
path "sys/seal-status"
{
  capabilities = ["read"]
}

# Read license status
path "sys/license/status"
{
  capabilities = ["read"]
}

# Read metrics
path "sys/metrics"
{
  capabilities = ["read"]
}

# Read internal counters
path "sys/internal/counters/*"
{
  capabilities = ["read"]
}

# List and read leases
path "sys/leases/lookup/*"
{
  capabilities = ["read", "list"]
}

# Read capabilities
path "sys/capabilities-self"
{
  capabilities = ["read"]
}

# Read identity information
path "identity/entity/id/*"
{
  capabilities = ["read"]
}

path "identity/entity/name/*"
{
  capabilities = ["read"]
}

path "identity/group/id/*"
{
  capabilities = ["read"]
}

path "identity/group/name/*"
{
  capabilities = ["read"]
}

# Read authentication configuration
path "auth/*/config"
{
  capabilities = ["read"]
}

# Read token configuration
path "auth/token/accessors"
{
  capabilities = ["read", "list"]
}

path "auth/token/roles/*"
{
  capabilities = ["read"]
}

# Read PKI configuration
path "pki/config/*"
{
  capabilities = ["read"]
}

path "pki/certs"
{
  capabilities = ["read", "list"]
}

# Read AWS configuration
path "aws/config/*"
{
  capabilities = ["read"]
}

path "aws/roles/*"
{
  capabilities = ["read"]
}

# Read Azure configuration
path "azure/config"
{
  capabilities = ["read"]
}

path "azure/roles/*"
{
  capabilities = ["read"]
}

# Read GCP configuration
path "gcp/config"
{
  capabilities = ["read"]
}

path "gcp/roles/*"
{
  capabilities = ["read"]
}

# Read Kubernetes configuration
path "kubernetes/config"
{
  capabilities = ["read"]
}

path "kubernetes/roles/*"
{
  capabilities = ["read"]
}

# Read database configuration
path "database/config/*"
{
  capabilities = ["read"]
}

path "database/roles/*"
{
  capabilities = ["read"]
}

# Read transit configuration
path "transit/keys/*"
{
  capabilities = ["read"]
}

# Read encryption key configuration
path "encryption/keys/*"
{
  capabilities = ["read"]
}

# Read secret metadata (but not actual secrets)
path "secret/metadata/*"
{
  capabilities = ["read", "list"]
}

# Generate audit reports
path "sys/audit-report/*"
{
  capabilities = ["read"]
}

# Read replication status
path "sys/replication/status"
{
  capabilities = ["read"]
}

# Read performance metrics
path "sys/storage/raft/snapshot-auto/config"
{
  capabilities = ["read"]
}

# Deny all write operations
path "+/+/+/+"
{
  capabilities = ["deny"]
  permissions = ["create", "update", "delete", "sudo"]
}
