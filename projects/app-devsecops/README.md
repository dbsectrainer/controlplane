# Application DevSecOps Pipeline

Node.js Express application demonstrating defense-in-depth security controls embedded at every stage of the software delivery pipeline.

---

## Security Controls

| Layer         | Tool                                 | What it does                                          |
| ------------- | ------------------------------------ | ----------------------------------------------------- |
| SAST          | SonarQube + ESLint                   | Static code analysis + security rule enforcement      |
| DAST          | OWASP ZAP                            | Automated runtime vulnerability scanning              |
| Secrets       | HashiCorp Vault                      | Dynamic credential injection (no hardcoded secrets)   |
| Container     | Trivy + multi-stage Dockerfile       | Image vulnerability scanning + minimal attack surface |
| Runtime       | Falco                                | Syscall-level anomaly detection                       |
| Service mesh  | Istio mTLS                           | Mutual TLS between services                           |
| K8s policy    | Kyverno + network policies           | Admission control + pod-to-pod traffic restrictions   |
| Observability | Prometheus + structured JSON logging | Metrics + audit trail                                 |

MITRE ATT&CK mitigations: T1059 (Command Execution), T1552 (Credentials in Files), T1195 (Supply Chain)

---

## Local Run

Requires the full stack to be running (`docker-compose up -d` from repo root).

```bash
# Application API + Swagger docs
open http://localhost:3000/api-docs

# SonarQube SAST dashboard
open http://localhost:9000   # admin/admin
```

---

## Key Files

```
app-devsecops/
├── src/
│   ├── app.js                  # Express setup, Helmet headers, rate limiting
│   ├── middleware/             # Auth, logging, security headers
│   ├── routes/                 # API endpoints
│   ├── services/vault.js       # Vault integration (dynamic secrets)
│   └── swagger.js              # OpenAPI spec
├── k8s/
│   ├── staging/                # Staging deployment manifests
│   ├── production/             # Production deployment manifests
│   └── security/               # Istio policies, network policies, Kyverno rules
├── .eslintrc.cjs               # ESLint security rules (no-eval, no-implied-eval, etc.)
├── jest.config.js              # Unit test config
├── jest.integration.config.js  # Integration test config
└── jest.smoke.config.js        # Smoke test config
```

---

## Tests

```bash
npm test                    # Unit tests
npm run test:integration    # Integration tests (requires running services)
npm run test:smoke          # Smoke tests against running app
npm run lint                # ESLint security rules
```
