# Zero Trust Security Pipeline

Identity-first security architecture implementing NIST SP 800-207 Zero Trust. Every request is authenticated, authorized, and logged — no implicit trust at any layer.

---

## Security Controls

| Component     | Tool             | Role                                                                   |
| ------------- | ---------------- | ---------------------------------------------------------------------- |
| Identity      | Keycloak         | OIDC/OAuth2, TOTP MFA, brute-force protection, RBAC groups             |
| Authorization | OPA (Rego)       | ABAC enforcement: role + network source + MFA status + team + time     |
| Secrets       | Vault            | Policy-tiered access (admin / developer / auditor), PKI, dynamic creds |
| Network       | Istio mTLS       | Encrypted service-to-service communication                             |
| Behavioral    | Prometheus rules | Anomaly detection on auth failure rates and policy violations          |

**Key principle:** Access denied by default. OPA evaluates all five ABAC factors before any request reaches the application.

---

## Local Run

```bash
# Keycloak admin console (zero-trust realm)
open http://localhost:8080/admin   # admin/admin

# OPA policy decision point (API)
curl http://localhost:8181/v1/data/authz/allow \
  -d '{"input": {"role": "developer", "mfa": true, "network": "internal"}}'

# Vault UI
open http://localhost:8200/ui      # token: root
```

---

## Key Files

```
zero-trust/
├── identity/keycloak/
│   └── realm-export.json       # Zero-trust realm: MFA required, brute-force settings, roles
└── policies/opa/
    └── authz.rego              # ABAC policy: role + network + MFA + team + time
```

```
shared/infrastructure/
├── vault/
│   ├── vault-init.sh           # Seeds policies and initial secrets
│   ├── policies/admin.hcl      # Full access policy
│   ├── policies/developer.hcl  # Scoped read/write policy
│   ├── policies/auditor.hcl    # Read-only audit policy
│   └── vault-config-prod.hcl  # Production config (KMS seal, integrated storage)
├── keycloak/
│   └── realm.json              # Realm configuration for docker-compose import
└── opa/
    └── config.yaml             # OPA server config (decision log, bundle)
```

---

## Testing the Policy

```bash
# Should be allowed (developer + MFA + internal network)
curl -s http://localhost:8181/v1/data/authz/allow \
  -H "Content-Type: application/json" \
  -d '{"input":{"role":"developer","mfa":true,"network":"internal","team":"backend"}}'

# Should be denied (developer attempting admin action)
./shared/scripts/demo-privilege-esc.sh
```
