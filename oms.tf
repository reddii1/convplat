#Log Analytics Workspace
# resource "random_id" "workspace_id" {
#   keepers = {
#     # Generate a new id each time we switch to a new resource group
#     resource_group = azurerm_resource_group.rg_oms.namevar
#   }

#   byte_length = 4
# }

resource "azurerm_log_analytics_workspace" "oms" {
  # name                = "oms-${local.location_prefix}-${terraform.workspace}-${var.pdu}-${random_id.workspace_id.hex}"
  name                = "oms-${local.location_prefix}-${terraform.workspace}-${var.pdu}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  sku                 = "PerGB2018"
  retention_in_days   = 365
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Configure OMS Advanced Settings (Automation Account, Event Logs & Performance Counters)
data "template_file" "oms_powershell" {
  template = file("${path.module}/oms_configure.ps1")

  vars = {
    tenant_id                = var.tenant_id
    subcription_id           = var.subscription_id[terraform.workspace]
    workspace_resource_group = azurerm_log_analytics_workspace.oms.resource_group_name
    workspace_name           = azurerm_log_analytics_workspace.oms.name
    automation_account_id    = "/subscriptions/${data.azurerm_client_config.client_config.subscription_id}/resourceGroups/rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-core/providers/Microsoft.Automation/automationAccounts/aaa-${local.location_prefix}-${terraform.workspace}-${var.pdu}"
    spn_id                   = data.azurerm_key_vault_secret.keyvault_secret_cloudspn_username.value
    spn_pw                   = data.azurerm_key_vault_secret.keyvault_secret_cloudspn_password.value
  }
}

resource "null_resource" "oms_config" {
  provisioner "local-exec" {
    command     = data.template_file.oms_powershell.rendered
    interpreter = ["pwsh", "-Command"]
  }
}


# Log Analytics Solution - AD Assessment
resource "azurerm_log_analytics_solution" "solution_ad_assessment_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "ADAssessment"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ADAssessment"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Agent Health Assessment
resource "azurerm_log_analytics_solution" "solution_agenthealth_assessment_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "AgentHealthAssessment"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AgentHealthAssessment"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Alert Management
resource "azurerm_log_analytics_solution" "solution_alertmanagement_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "AlertManagement"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AlertManagement"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Anti Malware
resource "azurerm_log_analytics_solution" "solution_antimalware_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "AntiMalware"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AntiMalware"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Azure Activity
resource "azurerm_log_analytics_solution" "solution_azure_activity_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "AzureActivity"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureActivity"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Azure Automation
resource "azurerm_log_analytics_solution" "solution_azure_automation_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "AzureAutomation"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureAutomation"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - NSG Analytics
resource "azurerm_log_analytics_solution" "solution_azure_nsg_analytics_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "AzureNSGAnalytics"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureNSGAnalytics"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Backup
resource "azurerm_log_analytics_solution" "solution_backup_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "Backup"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Backup"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Change Tracking
resource "azurerm_log_analytics_solution" "solution_change_tracking_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "ChangeTracking"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ChangeTracking"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - KeyVault Analytics
resource "azurerm_log_analytics_solution" "solution_keyvault_analytics_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "KeyVaultAnalytics"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/KeyVaultAnalytics"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Network Monitoring
resource "azurerm_log_analytics_solution" "solution_network_monitoring_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "NetworkMonitoring"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/NetworkMonitoring"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - SQL Assessment
resource "azurerm_log_analytics_solution" "solution_sql_assessment_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "SQLAssessment"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SQLAssessment"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Security
resource "azurerm_log_analytics_solution" "solution_security_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "Security"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Security Center Free
resource "azurerm_log_analytics_solution" "solution_security_center_free_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "SecurityCenterFree"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityCenterFree"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Service Desk
resource "azurerm_log_analytics_solution" "solution_servicedesk_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "ServiceDesk"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ServiceDesk"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Service Map
resource "azurerm_log_analytics_solution" "solution_servicemap_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "ServiceMap"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ServiceMap"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]
  tags       = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - Updates
resource "azurerm_log_analytics_solution" "solution_updates_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "Updates"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]

  tags = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Log Analytics Solution - WireData2
resource "azurerm_log_analytics_solution" "solution_wiredata2_oms_dwp" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_oms.name
  solution_name         = "WireData2"
  workspace_name        = azurerm_log_analytics_workspace.oms.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/WireData2"
  }

  depends_on = [azurerm_log_analytics_workspace.oms]

  tags = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
