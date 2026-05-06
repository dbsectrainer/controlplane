# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [1.1.0] — 2026-05-06

### Fixed

#### CI/CD Pipeline (`.github/workflows/master-pipeline.yml`)

- **Terraform version — 1.15** — bumped Terraform to v1.15.2 in CI and updated all module `required_version` constraints to `>= 1.15.1`
- **Trivy action — v0.35.0** — updated container scan action from mutable `@master` to pinned `@0.35.0`
- **docker compose v2** — replaced `docker-compose` (v1 standalone) with `docker compose` (v2 plugin) in integration-tests and teardown; not shipped by default on Ubuntu 22.04 runners
- **Terraform validate — multi-cloud** — expanded `pipeline-cloud-native` to validate all three provider directories (AWS, Azure, GCP); previously only AWS was validated
- **`terraform_wrapper: false`** — disabled the Node.js wrapper in `hashicorp/setup-terraform@v3` to prevent `/usr/bin/env: 'node': No such file or directory` failures
- **OPA binary checksum verification** — fixed filename mismatch by downloading binary to `/tmp/opa_linux_amd64_static` so `sha256sum -c` resolves the correct entry in the checksum file
- **Vault HCL format check** — replaced non-existent `vault policy fmt -check` flag with a copy-then-format-then-diff pattern using `mktemp`
- **tfsec checksum URL** — changed from `tfsec-linux-amd64.SHA256` (404) to `tfsec_checksums.txt` with `grep "tfsec-linux-amd64$"` extraction and direct hash comparison
- **detect-secrets regex** — changed `--exclude-files '*.hcl'` (invalid glob) to `--exclude-files '.*\.hcl'` (valid Python regex)
- **detect-secrets exclusions** — added exclusions for `shared/scripts/.*`, `shared/infrastructure/monitoring/.*`, and `shared/infrastructure/keycloak/.*` to suppress intentional placeholder credentials in demo configs
- **`actions/setup-python` removed** — all jobs use the Python 3.10 pre-installed in `catthehacker/ubuntu:act-22.04`; setup-python post-step fails in act due to missing cache API
- **npm cache path** — corrected `cache-dependency-path` from `package.json` to `package-lock.json`
- **Job timeouts** — added explicit `timeout-minutes` to every job
- **Integration-test health polling** — replaced `sleep 10` with `timeout 60 bash -c 'until curl -sf ...; do sleep 2; done'` for Vault and OPA readiness

#### Terraform — AWS (`projects/cloud-native/terraform/aws/`)

- **Created `main.tf`** — provider config, variables, data sources, and supporting resource stubs (`aws_iam_role`, `aws_cloudwatch_log_group`, `aws_s3_bucket`) required by `security.tf`
- **AWS provider v5 breaking change** — changed `include_global_resources` → `include_global_resource_types` in `aws_config_configuration_recorder`

#### Terraform — Azure (`projects/cloud-native/terraform/azure/`)

- **Created `main.tf`** — provider config, variables, data sources, and `azurerm_public_ip.waf` stub required by `security.tf`
- **Application Gateway WAF certificate variables** — introduced `waf_ssl_certificate_data` and `waf_ssl_certificate_password` (sensitive variables) to allow injecting base64 PFX and password for production deployments; replaced file-based stub and hardcoded values
- **azurerm v3 breaking change** — replaced removed `azurerm_policy_assignment` with `azurerm_subscription_policy_assignment`; updated `scope` → `subscription_id`
- **Application Gateway required blocks** — added missing `backend_address_pool`, `backend_http_settings`, `http_listener`, and `request_routing_rule` blocks

#### Terraform — GCP (`projects/cloud-native/terraform/gcp/`)

- **Created `main.tf`** — provider config and all variables referenced by `security.tf`

#### Policies

- **`shared/infrastructure/opa/policies.rego`** — formatted with `opa fmt` to resolve `opa fmt --fail` CI check failure
- **`shared/infrastructure/vault/policies/*.hcl`** — all three files reformatted with Vault 1.15 to fix brace style
- **`projects/zero-trust/identity/vault/policies/auditor-policy.hcl`** — removed invalid `permissions` key from deny block; reformatted

#### Secret Scanning

- **Created `.secrets.baseline`** — detect-secrets baseline for known findings in `shared/infrastructure/keycloak/realm.json`

### Added

- **`.actrc`** — configures `act` for local pipeline runs: `catthehacker/ubuntu:act-22.04` image, `linux/amd64` architecture (Apple Silicon), artifact server path
- **CI/CD section in README** — documents 4-stage pipeline structure and `act` commands for local job execution

---

## [1.0.0] — 2026-03-18

### Added

- Application DevSecOps pipeline: Node.js Express app with Vault integration, Falco runtime monitoring, Istio mTLS, and full SAST/DAST/container scanning
- Zero Trust security pipeline: Keycloak OIDC with TOTP MFA, OPA ABAC policies (role + network + MFA + time), Vault PKI
- Cloud-native security pipeline: Terraform modules for AWS, Azure, and GCP with Checkov and tfsec scanning
- Compliance automation pipeline: Continuous SOC2 Type II, HIPAA §164.312, PCI-DSS Req 1–12, and GDPR evidence collection with live Flask dashboard
- Mobile security pipeline: iOS (Swift) and Android (Kotlin) apps with cert pinning, MobSF DAST, Semgrep SAST, and secret detection
- Five runnable live attack demo scenarios: brute-force, privilege escalation, compliance drift, supply chain attack, mobile secret leak
- Shared observability stack: Prometheus, Grafana, Alertmanager with pre-built security dashboards and alert rules
- MITRE ATT&CK coverage mapping for T1078, T1110, T1548, T1021, T1027, T1552, T1565, T1195
- Kubernetes manifests for staging, production, and security contexts
- `docker compose up` local demo — all services running in under 5 minutes
