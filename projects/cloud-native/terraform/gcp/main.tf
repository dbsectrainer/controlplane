terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "security-pipeline"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "organization_id" {
  description = "GCP organization ID"
  type        = string
  default     = ""
}

variable "access_policy_id" {
  description = "GCP Access Context Manager access policy ID"
  type        = string
  default     = ""
}

variable "project_number" {
  description = "GCP project number"
  type        = string
  default     = ""
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for security policies"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "allowed_vpc_projects" {
  description = "Allowed VPC projects for peering"
  type        = list(string)
  default     = []
}

variable "attestor_public_key_path" {
  description = "Path to the attestor public key file"
  type        = string
  default     = "/dev/null"
}

variable "security_email" {
  description = "Security notification email address"
  type        = string
  default     = "security@example.com"
}
