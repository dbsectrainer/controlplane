# Contributing to ControlPlane

## Prerequisites

- Docker Desktop 4.x+
- Node.js 18+
- Terraform 1.5+ (for cloud-native changes)
- Python 3.11+ (for compliance reporter changes)

## Local Setup

```bash
git clone https://github.com/dbsectrainer/controlplane
cd controlplane
./shared/scripts/demo-setup.sh
docker-compose up -d
```

Verify services are healthy: `docker-compose ps`

## Branch Conventions

| Branch prefix | Use                                  |
| ------------- | ------------------------------------ |
| `feat/`       | New features                         |
| `fix/`        | Bug fixes                            |
| `docs/`       | Documentation only                   |
| `refactor/`   | Code changes with no behavior change |
| `chore/`      | Dependency bumps, CI, tooling        |

Branch from `main`, target `main`.

## Commit Style

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(zero-trust): add time-based OPA policy restriction
fix(compliance): correct HIPAA §164.312 control mapping
docs(mobile): update MobSF setup instructions
```

## Pull Requests

- Fill out the PR template completely
- Keep PRs focused — one logical change per PR
- All CI checks must pass before merge
- One approving review required

## Testing Requirements

### App DevSecOps

```bash
cd projects/app-devsecops
npm test                    # Unit tests
npm run test:integration    # Integration tests (requires running services)
npm run lint                # ESLint security rules
```

### Compliance Reporter

```bash
cd projects/compliance/reporter
python -m pytest
```

### IaC (Terraform)

```bash
cd projects/cloud-native/terraform
checkov -d .
tfsec .
```

All tests must pass. New features require new tests.

## Security Contributions

If your change touches authentication, authorization, secrets handling, or any security control — note it explicitly in your PR description and tag it `security-impact`.

Do not introduce demo credentials into non-demo code paths.

## Reporting Vulnerabilities

See [SECURITY.md](SECURITY.md).
