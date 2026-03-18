# Cloud-Native Security Pipeline

Multi-cloud infrastructure security controls for AWS, Azure, and GCP with IaC scanning enforced in CI. Every Terraform plan is validated against CIS Benchmarks before apply.

---

## Security Controls

| Cloud | Controls                                        | Benchmark               |
| ----- | ----------------------------------------------- | ----------------------- |
| AWS   | WAF, IAM least-privilege, GuardDuty, AWS Config | CIS AWS Benchmark 1.4   |
| Azure | WAF, NSGs, Microsoft Defender, Azure Policy     | CIS Azure Benchmark 1.3 |
| GCP   | Cloud Armor, VPC firewall rules, IAM Conditions | CIS GCP Benchmark 1.2   |

| IaC Tool  | Purpose                                             |
| --------- | --------------------------------------------------- |
| Checkov   | Policy-as-code scanning (400+ checks)               |
| tfsec     | Terraform-specific security analysis                |
| Terraform | Infrastructure provisioning across all three clouds |

---

## Local Run

No cloud credentials required for scanning. IaC scanning runs against the Terraform source files:

```bash
cd projects/cloud-native/terraform

# Run Checkov against all modules
checkov -d .

# Run tfsec
tfsec .
```

---

## Key Files

```
cloud-native/terraform/
├── aws/
│   ├── waf.tf              # Web Application Firewall rules
│   ├── iam.tf              # Least-privilege IAM roles and policies
│   ├── guardduty.tf        # Threat detection
│   └── config.tf           # AWS Config compliance rules
├── azure/
│   ├── waf.tf              # Azure Application Gateway WAF
│   ├── nsg.tf              # Network Security Groups
│   ├── defender.tf         # Microsoft Defender for Cloud
│   └── policy.tf           # Azure Policy assignments
└── gcp/
    ├── cloud-armor.tf      # DDoS and WAF rules
    ├── firewall.tf         # VPC firewall rules
    └── iam.tf              # IAM Conditions + Workload Identity
```

---

## CI Enforcement

The CI pipeline (`.github/workflows/`) runs Checkov and tfsec on every PR touching `projects/cloud-native/`. A failed scan blocks merge.

Expected clean scan output:

```
Passed checks: N, Failed checks: 0, Skipped checks: 0
```
