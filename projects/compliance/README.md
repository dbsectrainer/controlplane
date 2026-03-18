# Compliance Automation Pipeline

Continuous compliance monitoring with automated evidence collection across SOC2 Type II, HIPAA, PCI-DSS, and GDPR. Controls are defined as YAML, evaluated in real time, and surfaced on a live dashboard.

---

## Frameworks Supported

| Framework    | Scope                         | Controls                                                                     |
| ------------ | ----------------------------- | ---------------------------------------------------------------------------- |
| SOC2 Type II | Common Criteria CC1.0–CC9.0   | Access control, availability, confidentiality, processing integrity, privacy |
| HIPAA        | §164.312 Technical Safeguards | Access control, audit controls, integrity, transmission security             |
| PCI-DSS      | Requirements 1–12             | Network security, access control, monitoring, encryption                     |
| GDPR         | Articles 25, 32               | Data minimization, encryption, access controls, audit trail                  |

---

## Local Run

```bash
# Live compliance dashboard
open http://localhost:8088/dashboard

# Inject a simulated compliance drift (SOC2 CC6.1 access control failure)
./shared/scripts/demo-compliance.sh inject-drift

# Watch dashboard go red, then recover
./shared/scripts/demo-compliance.sh recover
```

---

## Key Files

```
compliance/
├── compliance/
│   ├── soc2/controls.yaml      # SOC2 control definitions + evidence mappings
│   ├── hipaa/controls.yaml     # HIPAA safeguard definitions
│   └── pci/controls.yaml       # PCI-DSS requirement definitions
└── reporter/
    ├── app.py                  # Flask dashboard server
    ├── evaluator.py            # Control evaluation engine
    └── templates/              # Dashboard HTML templates
```

---

## How Controls Are Evaluated

Each control in `controls.yaml` defines:

- `id` — framework control ID (e.g. `CC6.1`)
- `description` — plain-language description
- `check` — evaluation method (OPA query, Prometheus metric threshold, or API probe)
- `evidence` — where evidence is collected (audit log, metric name, etc.)

The reporter evaluates all controls on a configurable interval and exposes results as both a dashboard and Prometheus metrics (`compliance_control_status`).

---

## Prometheus Metrics

```
# HELP compliance_control_status Pass (1) or fail (0) per control
# TYPE compliance_control_status gauge
compliance_control_status{framework="soc2",control="CC6.1"} 1
compliance_control_status{framework="hipaa",control="164.312a"} 1
```

Alertmanager fires `ComplianceDrift` when any control drops to 0 for more than 2 minutes.
