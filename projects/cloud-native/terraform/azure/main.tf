terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "security-pipeline-rg"
}

variable "security_contact_email" {
  description = "Security contact email"
  type        = string
  default     = "security@example.com"
}

variable "security_contact_phone" {
  description = "Security contact phone"
  type        = string
  default     = "+1-555-000-0000"
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for network rules"
  type        = list(string)
  default     = []
}

variable "gateway_subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
  default     = ""
}

variable "endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = ""
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azurerm_public_ip" "waf" {
  name                = "security-pipeline-waf-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}
