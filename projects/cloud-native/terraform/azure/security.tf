# Azure Security Configuration

# Resource Group
resource "azurerm_resource_group" "security" {
  name     = "security-pipeline-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Azure Security Center
resource "azurerm_security_center_subscription_pricing" "main" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_contact" "main" {
  email = var.security_contact_email
  phone = var.security_contact_phone

  alert_notifications = true
  alerts_to_admins   = true
}

# Enable Security Center Auto Provisioning
resource "azurerm_security_center_auto_provisioning" "main" {
  auto_provision = "On"
}

# Azure Defender Settings
resource "azurerm_security_center_subscription_pricing" "containers" {
  tier          = "Standard"
  resource_type = "Containers"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "appservices" {
  tier          = "Standard"
  resource_type = "AppServices"
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "security-pipeline-${var.environment}"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  tenant_id          = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Application Gateway WAF
resource "azurerm_application_gateway" "waf" {
  name                = "security-pipeline-waf"
  resource_group_name = azurerm_resource_group.security.name
  location            = azurerm_resource_group.security.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = var.gateway_subnet_id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.waf.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "https"
    protocol                       = "Https"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-settings"
    priority                   = 100
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "main" {
  name                = "security-pipeline-nsg"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name

  security_rule {
    name                       = "HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "443"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Azure Monitor
resource "azurerm_log_analytics_workspace" "main" {
  name                = "security-pipeline-logs"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  sku                = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Azure Monitor Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "security-pipeline-keyvault-diag"
  target_resource_id        = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

# Azure Policy Assignments
resource "azurerm_subscription_policy_assignment" "security_benchmark" {
  name                 = "security-benchmark"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  description          = "Azure Security Benchmark policy initiative assignment"
  display_name         = "Azure Security Benchmark"

  parameters = jsonencode({
    "effect" = {
      value = "AuditIfNotExists"
    }
  })
}

# Azure DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  name                = "security-pipeline-ddos"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Azure Private Link
resource "azurerm_private_endpoint" "keyvault" {
  name                = "security-pipeline-keyvault-endpoint"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  subnet_id           = var.endpoint_subnet_id

  private_service_connection {
    name                           = "keyvault-connection"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection          = false
    subresource_names            = ["vault"]
  }

  tags = {
    Environment = var.environment
    Project     = "security-pipeline"
  }
}

# Outputs
output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "waf_public_ip" {
  value = azurerm_public_ip.waf.ip_address
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}
