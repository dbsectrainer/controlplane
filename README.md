# ControlPlane

**End-to-end security architecture demonstrating Zero Trust, compliance automation, supply chain security, and real-time threat detection — runnable in 5 minutes with `docker-compose up`.**

---

## Quick Start

```bash
git clone https://github.com/dbsectrainer/controlplane
cd controlplane
./shared/scripts/demo-setup.sh
docker-compose up -d
open http://localhost:3000/api-docs  # Demo app
open http://localhost:3100           # Grafana security dashboards (admin/admin)
open http://localhost:8200/ui        # Vault (token: root)
open http://localhost:8088/dashboard # Compliance reporter
```

For a full walkthrough: [Hiring Manager Guide](docs/HIRING-MANAGER-GUIDE.md) · [Conference Runbook](docs/CONFERENCE-RUNBOOK.md)

---

## Architecture

Five security domains unified through a shared Zero Trust core:

```
┌─ Attack Surface ──────────────────────────────────┐
│  Code Commits · Mobile Apps · Cloud IaC · Web API │
└───────────────────────┬───────────────────────────┘
                        │ Pipeline Security Gates
                        │ SAST · DAST · Checkov · MobSF · detect-secrets
                        ▼
┌─ Zero Trust Core ─────────────────────────────────┐
│  Keycloak (OIDC/MFA) → OPA (ABAC) → Vault (PKI)  │
└───────────────────────┬───────────────────────────┘
                        │ Authenticated & Authorized
                        ▼
┌─ Application + Runtime Security ──────────────────┐
│  Demo App · Falco · Istio mTLS · Prometheus        │
└───────────────────────┬───────────────────────────┘
                        │ Continuous Monitoring
                        ▼
┌─ Compliance & Evidence ───────────────────────────┐
│  SOC2 · HIPAA · PCI-DSS · GDPR controls + reports │
└───────────────────────────────────────────────────┘
```

Full diagram: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## The Five Domains

<details>
<summary><strong>1. Application DevSecOps Pipeline</strong></summary>

Node.js Express application with defense-in-depth security controls embedded at every stage.

**Location:** `projects/app-devsecops/`

**Security controls:**

- SAST: SonarQube + ESLint security rules
- DAST: OWASP ZAP automated scanning
- Container security: Trivy image scanning + multi-stage Dockerfile
- Secrets: HashiCorp Vault integration (`src/services/vault.js`)
- Runtime: Falco syscall monitoring + Prometheus metrics
- Service mesh: Istio mTLS (`k8s/security/`)
- K8s policy: Kyverno + network policies

**MITRE ATT&CK mitigations:** T1059 (Command Execution), T1552 (Credentials in Files), T1195 (Supply Chain)

</details>

<details>
<summary><strong>2. Zero Trust Security Pipeline</strong></summary>

Identity-first security architecture implementing the NIST SP 800-207 Zero Trust framework.

**Location:** `projects/zero-trust/`, `shared/infrastructure/`

**Security controls:**

- Identity: Keycloak OIDC with TOTP MFA, brute-force protection, role-based groups
- Policy: OPA Rego — ABAC enforcement (role + network + MFA + team + time)
- Secrets: Vault with admin/developer/auditor policy tiers
- Network: Istio mTLS + Kubernetes network policies
- Behavioral: Prometheus-based anomaly detection

**Key principle:** Every request is authenticated, authorized, and logged — no implicit trust.

</details>

<details>
<summary><strong>3. Cloud-Native Security Pipeline</strong></summary>

Multi-cloud infrastructure security controls for AWS, Azure, and GCP with IaC scanning.

**Location:** `projects/cloud-native/terraform/`

**Security controls:**

- AWS: WAF, IAM least-privilege, GuardDuty, AWS Config rules
- Azure: WAF, NSGs, Microsoft Defender, Azure Policy
- GCP: Cloud Armor, Firewall rules, IAM Conditions
- IaC scanning: Checkov + tfsec in CI
- Compliance: CIS Benchmark 1.4/1.3/1.2 per cloud
- CSPM: Unified posture management across clouds

</details>

<details>
<summary><strong>4. Compliance Automation Pipeline</strong></summary>

Continuous compliance monitoring with automated evidence collection and live dashboard.

**Location:** `projects/compliance/`

**Frameworks supported:**

- SOC2 Type II (CC1.0–CC9.0 controls)
- HIPAA (§164.312 technical safeguards)
- PCI-DSS (Requirements 1–12)
- GDPR (Articles 25, 32)

**Live dashboard:** `http://localhost:8088/dashboard`

- Real-time pass/fail per control
- Prometheus metrics for alerting on drift
- Simulated drift endpoint for demos

</details>

<details>
<summary><strong>5. Mobile Security Pipeline</strong></summary>

iOS and Android security testing pipeline covering the OWASP Mobile Security Testing Guide (MSTG).

**Location:** `projects/mobile/`

**Security controls:**

- SAST: Semgrep custom rules + MobSF static analysis
- Certificate pinning: `SecurityConfig.kt` + `security-config.swift`
- Runtime protection: RASP integration, root/jailbreak detection
- Obfuscation: ProGuard/R8 (Android), Bitcode (iOS)
- Secret detection: detect-secrets scan on all source files
- Dynamic analysis: MobSF DAST (`http://localhost:8008`)

</details>

---

## Live Demo Scenarios

Start the demo attacker: `docker-compose --profile demo up -d attacker`

| #   | Scenario               | Command                                                                                      | What it shows                                                    |
| --- | ---------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| 1   | Credential Brute-Force | `./shared/scripts/demo-attack.sh brute-force`                                                | Keycloak lockout → Prometheus alert → Grafana live visualization |
| 2   | Privilege Escalation   | `./shared/scripts/demo-privilege-esc.sh`                                                     | Developer token denied admin access via OPA                      |
| 3   | Compliance Drift       | `./shared/scripts/demo-compliance.sh inject-drift`                                           | SOC2 control fails → dashboard red → auto-recovery               |
| 4   | Supply Chain Attack    | `./shared/scripts/demo-supply-chain.sh inject && ./shared/scripts/demo-supply-chain.sh scan` | Malicious dep blocked by Trivy pipeline gate                     |
| 5   | Mobile Secret Leak     | `./shared/scripts/demo-mobile-leak.sh inject && ./shared/scripts/demo-mobile-leak.sh scan`   | Hardcoded API key caught by Semgrep                              |

---

## Service Ports

| Service             | Port | URL                   | Notes                                                     |
| ------------------- | ---- | --------------------- | --------------------------------------------------------- |
| Demo App            | 3000 | http://localhost:3000 | Node.js Express API + Swagger                             |
| Grafana             | 3100 | http://localhost:3100 | Security dashboards (admin/admin)                         |
| MobSF               | 8008 | http://localhost:8008 | Mobile security framework                                 |
| Mailhog             | 8025 | http://localhost:8025 | Email test inbox (SMTP alerts)                            |
| Keycloak            | 8080 | http://localhost:8080 | Identity provider — admin console: `/admin` (admin/admin) |
| Compliance Reporter | 8088 | http://localhost:8088 | SOC2/HIPAA/PCI dashboard                                  |
| Vault               | 8200 | http://localhost:8200 | Secrets management UI (token: root)                       |
| OPA                 | 8181 | http://localhost:8181 | Policy decision point — API only                          |
| Prometheus          | 9090 | http://localhost:9090 | Metrics explorer                                          |
| SonarQube           | 9000 | http://localhost:9000 | SAST dashboard (admin/admin)                              |
| Alertmanager        | 9093 | http://localhost:9093 | Alert routing                                             |

---

## Repository Structure

```
controlplane/
├── shared/
│   ├── infrastructure/      # Vault, Keycloak, OPA, monitoring configs
│   ├── security-configs/    # MITRE mappings, behavioral analytics, supply chain
│   └── scripts/             # Demo scenarios + infra init scripts
├── projects/
│   ├── app-devsecops/       # Node.js app + K8s + CI/CD
│   ├── zero-trust/          # Identity, policies, OPA rules
│   ├── cloud-native/        # Terraform for AWS/Azure/GCP
│   ├── compliance/          # SOC2/HIPAA/PCI controls + Flask reporter
│   └── mobile/              # iOS/Android security + MobSF configs
├── .github/workflows/       # Master CI/CD pipeline (4-stage DAG)
└── docs/                    # Hiring manager guide + conference runbook
```

---

## Teardown

```bash
docker-compose down -v    # Remove containers and volumes
```

---

## License

[MIT](LICENSE)
