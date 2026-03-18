# Conference Demo Runbook

## ControlPlane — Live Demo Script

**Total runtime:** ~35 minutes | **Setup:** 5 minutes before presentation

---

## Pre-Show Setup (5 min before)

```bash
cd controlplane

# Start all services (conference mode — faster healthchecks)
docker-compose -f docker-compose.yml -f docker-compose.demo.yml up -d

# Verify all healthy
docker-compose ps

# Pre-open browser tabs:
# Tab 1: http://localhost:3000/api-docs         (Demo App — Swagger)
# Tab 2: http://localhost:3100                   (Grafana — Security Dashboard)
# Tab 3: http://localhost:8200/ui               (Vault)
# Tab 4: http://localhost:8080/admin            (Keycloak Admin — zero-trust realm)
# Tab 5: http://localhost:8088/dashboard        (Compliance Reporter)
# Tab 6: http://localhost:8008                  (MobSF)
```

---

## Opening (2 min)

> "Today I'm going to show you a fully integrated DevSecOps platform that demonstrates
> Zero Trust architecture, automated compliance, and real-time threat detection —
> all running live on my laptop."

**Show:** Architecture diagram (`ARCHITECTURE.md`) — point out the five domains and the Zero Trust core.

Key message:

> "Every arrow crossing inward passes through Keycloak, OPA, and Vault. That's the
> Zero Trust principle: verify explicitly, never trust, least privilege."

---

## Scenario 1: Credential Brute-Force (5 min)

**Narrative:** "Let's simulate an attacker trying to brute-force our admin account."

**Step 1** — Show Grafana → Security Dashboard (baseline, all green)

**Step 2** — Run attack:

```bash
./shared/scripts/demo-attack.sh brute-force
```

**Step 3** — Switch to Grafana — watch `authentication_failures_total` spike

**Step 4** — Show Keycloak Admin → Events tab → LOGIN_ERROR entries

**Step 5** — Show account locked (try logging in at localhost:8080)

**Key points to narrate:**

- Brute-force protection triggers after 3 failures (`failureFactor=3`)
- Lockout escalates: 60s → 120s → 240s
- All events stream to Prometheus, visible in Grafana within seconds
- This is behavioral analytics in action — same principle as UEBA

**Reset:**

```bash
./shared/scripts/demo-attack.sh reset
```

---

## Scenario 2: Privilege Escalation (7 min)

**Narrative:** "Now let's say the attacker got a developer credential. Can they escalate to admin?"

**Step 1** — Show the OPA policy briefly (`shared/infrastructure/opa/policies.rego`)

- Point out `has_role("admin")` check
- Point out ABAC: role + network + MFA + team membership

**Step 2** — Run privilege escalation attempt:

```bash
./shared/scripts/demo-privilege-esc.sh
```

**Step 3** — Walk through the output:

- Developer token obtained from Keycloak ✓
- OPA evaluated the request
- `allow = false` — denied (developer ≠ admin, wrong team, production resource)

**Step 4** — Show Grafana → `policy_violations_total` counter incremented

**Key points:**

- OPA evaluates at microsecond speed — zero latency penalty
- Violations are immediately metrics — no log parsing needed
- Policy is version-controlled code, not tribal knowledge

---

## Scenario 3: Compliance Drift (6 min)

**Narrative:** "Enterprise clients always ask: how do you know you're compliant right now, not just at audit time?"

**Step 1** — Show Compliance Reporter → `http://localhost:8088/dashboard`

- All SOC2, HIPAA, PCI controls green

**Step 2** — Inject drift:

```bash
./shared/scripts/demo-compliance.sh inject-drift SOC2 CC1.0
```

**Step 3** — Refresh dashboard — CC1.0 goes RED immediately

**Step 4** — Show API:

```bash
curl -s http://localhost:8088/api/controls | jq '.SOC2[] | select(.status=="FAIL")'
```

**Step 5** — Restore:

```bash
./shared/scripts/demo-compliance.sh restore
```

**Key points:**

- Compliance is continuous, not periodic
- Controls are YAML — version-controlled, reviewable, diffable
- Any CI commit can be blocked by a failing compliance gate
- Audit evidence is generated automatically (no manual evidence collection)

---

## Scenario 4: Supply Chain Attack (8 min)

**Narrative:** "The most dangerous attack vector right now is the software supply chain."

**Step 1** — Show `projects/app-devsecops/package.json` — clean dependencies

**Step 2** — Inject malicious package:

```bash
./shared/scripts/demo-supply-chain.sh inject
```

**Step 3** — Run scan:

```bash
./shared/scripts/demo-supply-chain.sh scan
```

**Step 4** — Walk through Trivy output: HIGH/CRITICAL finding, build gate blocks

**Step 5** — Show SBOM concept (supply-chain.yaml in shared/security-configs)

**Step 6** — Restore:

```bash
./shared/scripts/demo-supply-chain.sh restore
```

**Key points:**

- Trivy scans the filesystem, not just lock files — catches transitive deps
- `--exit-code 1` means the CI pipeline literally cannot proceed with a CRITICAL dep
- SBOM generated on every build — you know exactly what's in your artifact
- detect-secrets runs in parallel — catches credentials injected via compromised packages

---

## Scenario 5: Mobile Secret Exfiltration (5 min)

**Narrative:** "Mobile apps are a common source of secret leaks — API keys hardcoded in source."

**Step 1** — Inject secret:

```bash
./shared/scripts/demo-mobile-leak.sh inject
```

**Step 2** — Run scan:

```bash
./shared/scripts/demo-mobile-leak.sh scan
```

**Step 3** — Show finding: hardcoded API key at exact file:line

**Step 4** — Show MobSF UI (`http://localhost:8008`) — point to analysis capabilities

**Step 5** — Show secure alternative:

```bash
./shared/scripts/demo-mobile-leak.sh fix
```

**Key points:**

- Semgrep catches this in under 2 seconds on the developer's laptop — shift left
- Vault pattern means secrets rotate automatically; hardcoded strings can't
- Certificate pinning verification runs in the same scan pass

**Restore:**

```bash
./shared/scripts/demo-mobile-leak.sh restore
```

---

## Closing (2 min)

> "What you've seen today is five security domains working together as one platform:
>
> - **Zero Trust** — every request verified, no implicit trust
> - **Pipeline Security** — SAST, DAST, supply chain, mobile — shift-left
> - **Real-time Detection** — Prometheus + Grafana, alerts in seconds not days
> - **Compliance as Code** — SOC2, HIPAA, PCI controls version-controlled and continuously monitored
> - **Secrets Management** — Vault as the single source of truth, never hardcoded
>
> The architecture scales from a local docker-compose demo to production EKS.
> The same Vault policies, OPA rules, and compliance controls run in both."

**Point to GitHub:** The entire platform is open-source. See `README.md`.

---

## Teardown

```bash
docker-compose -f docker-compose.yml -f docker-compose.demo.yml down -v
```

---

## Troubleshooting

| Issue                             | Fix                                                                                                      |
| --------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Keycloak not starting             | `docker-compose logs keycloak` — wait 60s for startup                                                    |
| `dev-user` login fails            | Keycloak realm not imported — restart: `docker-compose restart keycloak`                                 |
| OPA returns `allow=false` for all | Check `shared/infrastructure/opa/policies.rego` — `within_working_hours` should be `true`                |
| Compliance dashboard empty        | `docker-compose logs compliance-reporter` — check YAML parsing                                           |
| MobSF slow to start               | Normal — allow 30-60s. Pull image in advance: `docker pull opensecurity/mobile-security-framework-mobsf` |
