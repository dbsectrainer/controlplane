# Google Cloud Security Configuration

# Enable required APIs
resource "google_project_service" "security_apis" {
  for_each = toset([
    "cloudasset.googleapis.com",
    "cloudkms.googleapis.com",
    "securitycenter.googleapis.com",
    "containerscanning.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudarmor.googleapis.com"
  ])

  service = each.key
  disable_on_destroy = false
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "main" {
  name = "security-pipeline-policy"

  # Default rule (deny all)
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }

  # Allow specific IP ranges
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_ip_ranges
      }
    }
    description = "Allow trusted IPs"
  }

  # OWASP Top 10 protection
  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS protection"
  }

  rule {
    action   = "deny(403)"
    priority = "2001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL injection protection"
  }

  # Rate limiting
  rule {
    action   = "rate_based_ban"
    priority = "3000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      conform_action = "allow"
      exceed_action  = "deny(429)"
    }
    description = "Rate limiting rule"
  }
}

# Cloud KMS Configuration
resource "google_kms_key_ring" "main" {
  name     = "security-pipeline-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "main" {
  name     = "security-pipeline-key"
  key_ring = google_kms_key_ring.main.id
  
  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Security Command Center Settings
resource "google_scc_source" "custom_source" {
  display_name = "Security Pipeline Custom Source"
  organization = var.organization_id
  description  = "Custom security source for pipeline"
}

# Binary Authorization Policy
resource "google_binary_authorization_policy" "main" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }

  default_admission_rule {
    evaluation_mode  = "ALWAYS_DENY"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }

  cluster_admission_rules {
    cluster         = "*"
    evaluation_mode = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.security_attestor.name,
    ]
  }
}

# Binary Authorization Attestor
resource "google_binary_authorization_attestor" "security_attestor" {
  name = "security-pipeline-attestor"
  attestation_authority_note {
    note_reference = google_container_analysis_note.security_note.name
    public_keys {
      ascii_armored_pgp_public_key = file(var.attestor_public_key_path)
      comment                      = "Security Pipeline Attestor Key"
    }
  }
}

# Container Analysis Note
resource "google_container_analysis_note" "security_note" {
  name = "security-pipeline-note"
  attestation_authority {
    hint {
      human_readable_name = "Security Pipeline Authority"
    }
  }
}

# VPC Service Controls
resource "google_access_context_manager_service_perimeter" "security_perimeter" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/servicePerimeters/security_pipeline"
  title  = "Security Pipeline Perimeter"
  status {
    restricted_services = [
      "storage.googleapis.com",
      "bigquery.googleapis.com",
      "cloudfunctions.googleapis.com"
    ]
    resources = [
      "projects/${var.project_number}"
    ]
    access_levels = [
      google_access_context_manager_access_level.security_level.name
    ]
  }
}

# Access Level
resource "google_access_context_manager_access_level" "security_level" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/accessLevels/security_pipeline_level"
  title  = "Security Pipeline Access Level"
  basic {
    conditions {
      ip_subnetworks = var.allowed_ip_ranges
      required_access_levels = []
    }
  }
}

# Cloud Audit Logs
resource "google_project_iam_audit_config" "audit_config" {
  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Organization Policies
resource "google_organization_policy" "require_oslogin" {
  org_id     = var.organization_id
  constraint = "compute.requireOsLogin"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "disable_serial_port" {
  org_id     = var.organization_id
  constraint = "compute.disableSerialPortAccess"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "restrict_vpc_peering" {
  org_id     = var.organization_id
  constraint = "compute.restrictVpcPeering"

  list_policy {
    allow {
      values = var.allowed_vpc_projects
    }
  }
}

# Security Health Analytics
resource "google_monitoring_alert_policy" "security_alerts" {
  display_name = "Security Pipeline Alerts"
  combiner     = "OR"

  conditions {
    display_name = "High Severity Security Findings"
    condition_threshold {
      filter          = "resource.type = \"security_center_source\" AND metric.type = \"securitycenter.googleapis.com/finding_count\" AND metric.labels.severity = \"HIGH\""
      duration        = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = 0
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name
  ]
}

# Notification Channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "Security Pipeline Email"
  type         = "email"
  
  labels = {
    email_address = var.security_email
  }
}

# Outputs
output "security_policy_id" {
  value = google_compute_security_policy.main.id
}

output "kms_keyring_id" {
  value = google_kms_key_ring.main.id
}

output "security_perimeter_name" {
  value = google_access_context_manager_service_perimeter.security_perimeter.name
}
