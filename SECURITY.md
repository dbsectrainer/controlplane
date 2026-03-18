# Security Policy

## Supported Versions

| Version         | Supported |
| --------------- | --------- |
| latest (`main`) | Yes       |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Use [GitHub Private Security Advisories](https://github.com/dbsectrainer/controlplane/security/advisories/new) to report vulnerabilities privately.

Include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You will receive a response within 48 hours acknowledging receipt. If confirmed, a fix will be prioritized and you will be credited in the advisory unless you prefer to remain anonymous.

## Scope

This repository is a **security demonstration platform** intended for local demo and educational use. Production deployments require additional hardening (see `ARCHITECTURE.md` — Production vs. Demo Differences).

Known demo-mode limitations that are intentional and out of scope:

- Vault running in dev mode with a static root token
- Keycloak using H2 in-memory database
- Demo credentials hardcoded in `docker-compose.yml`
- TLS disabled for localhost services

Vulnerabilities in the above are expected for the demo context. Report issues where security controls that are intended to work (OPA policies, Keycloak MFA, Vault policy enforcement) can be bypassed.
