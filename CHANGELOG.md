# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
- `docker-compose up` local demo — all services running in under 5 minutes
