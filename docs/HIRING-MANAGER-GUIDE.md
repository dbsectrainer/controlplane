# Hiring Manager Guide

## 5-Minute Local Spin-Up

This guide gets the platform running on your laptop in 5 minutes so you can explore the live security architecture.

---

## Prerequisites

- Docker Desktop (or Docker + docker-compose)
- 8GB RAM available (all services combined)
- Ports available: 3000, 3100, 8008, 8025, 8080, 8088, 8181, 8200, 9000, 9090, 9093

---

## Quick Start

```bash
git clone https://github.com/dbsectrainer/controlplane
cd controlplane
./shared/scripts/demo-setup.sh
docker-compose up -d
```

Wait ~2 minutes for all services to become healthy, then open:

| Service                       | URL                             | Credentials   |
| ----------------------------- | ------------------------------- | ------------- |
| Demo App (Swagger)            | http://localhost:3000/api-docs  | —             |
| Grafana (Security Dashboards) | http://localhost:3100           | admin / admin |
| Vault (Secrets UI)            | http://localhost:8200/ui        | token: `root` |
| Keycloak (Identity)           | http://localhost:8080           | admin / admin |
| Compliance Dashboard          | http://localhost:8088/dashboard | —             |
| MobSF (Mobile Security)       | http://localhost:8008           | —             |
| Prometheus                    | http://localhost:9090           | —             |
| SonarQube (SAST)              | http://localhost:9000           | admin / admin |
| Mail (demo SMTP)              | http://localhost:8025           | —             |

---

## What to Look For

### 1. Zero Trust Architecture in Vault (`http://localhost:8200/ui`)

- Login with token: `root`
- Navigate to **Secrets → kv/demo-app** — shows the app's secrets managed centrally
- Navigate to **Policies** — see `admin`, `developer`, `auditor` role-based access controls

### 2. Identity & Role Management in Keycloak (`http://localhost:8080`)

- Login: admin / admin
- Select realm **zero-trust**
- Navigate to **Users** — see `admin-user`, `dev-user`, `auditor-user` with assigned roles
- Navigate to **Realm Settings → Security Defenses** — brute-force protection configured

### 3. Policy-as-Code in OPA

```bash
# Query the policy engine directly
curl -s http://localhost:8181/v1/data/authorization/allow \
  -H 'Content-Type: application/json' \
  -d '{"input":{"user":{"name":"admin-user","roles":["admin"],"groups":[],"team":"security","type":"human"},"resource":{"name":"admin-panel","type":"ui","environment":"production","team":"security","allowed_service_accounts":[]},"request":{"method":"GET","protocol":"https","source_ip":"10.0.0.1","authenticated":true,"mfa_verified":true,"headers":{"Content-Security-Policy":"default","X-Frame-Options":"DENY"}},"context":{"incident_id":null,"emergency_approved":false}}}'
```

Expected: `{"result": true}`

### 4. Compliance Dashboard (`http://localhost:8088/dashboard`)

- See SOC2, HIPAA, PCI-DSS controls with live pass/fail status
- Simulate a drift: `curl -X POST "http://localhost:8088/inject-drift?framework=SOC2&control=CC1.0"`
- Restore: `curl -X POST http://localhost:8088/restore`

### 5. Run a Demo Scenario

```bash
# Simulate brute-force attack — watch Grafana alerts fire
./shared/scripts/demo-attack.sh brute-force
# Open http://localhost:3100 — watch authentication_failures spike
```

---

## What This Demonstrates

| Skill                     | Evidence                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------- |
| Zero Trust Architecture   | Keycloak + OPA + Vault integration (`shared/infrastructure/`)                         |
| DevSecOps Pipeline Design | `.github/workflows/master-pipeline.yml` — 4-stage security-first CI/CD                |
| Cloud-Native Security     | `projects/cloud-native/terraform/` — AWS, Azure, GCP IaC with Checkov                 |
| Compliance Automation     | `projects/compliance/` — SOC2/HIPAA/PCI as code with live reporter                    |
| Mobile Security           | `projects/mobile/` — iOS/Android SAST, cert pinning, MobSF                            |
| Threat Detection          | Prometheus alert rules in `shared/infrastructure/monitoring/security-monitoring.yaml` |
| Supply Chain Security     | SBOM config in `shared/security-configs/supply-chain.yaml`                            |
| MITRE ATT&CK Mapping      | `shared/security-configs/mitre-mappings.yaml`                                         |

---

## Teardown

```bash
docker-compose down -v
```
