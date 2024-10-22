# Azure Recovery Services Vault
resource "azurerm_recovery_services_vault" "rsv_dwp_core" {
  name                = "rsv-${local.location_prefix}-${terraform.workspace}-${var.pdu}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_core.name
  sku                 = "Standard"
  soft_delete_enabled = terraform.workspace == "prod" ? true : false

  tags = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}

# Backup Protection Policies
resource "azurerm_backup_policy_vm" "rvpolicy_dwp_vm_7day" {
  name                = "retain-for-7-days"
  resource_group_name = azurerm_resource_group.rg_core.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_dwp_core.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_policy_vm" "rvpolicy_dwp_vm_4week" {
  name                = "retain-for-4-weeks"
  resource_group_name = azurerm_resource_group.rg_core.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_dwp_core.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "00:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }
}

resource "azurerm_backup_policy_vm" "rvpolicy_dwp_vm_3month" {
  name                = "retain-for-3-months"
  resource_group_name = azurerm_resource_group.rg_core.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_dwp_core.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "01:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 3
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

resource "azurerm_backup_policy_vm" "rvpolicy_dwp_vm_1year" {
  name                = "retain-for-1-year"
  resource_group_name = azurerm_resource_group.rg_core.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_dwp_core.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "02:00"
  }

  retention_daily {
    count = 7
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

# Management Locks
resource "azurerm_management_lock" "lock_rsv_dwp_core" {
  name       = "${azurerm_recovery_services_vault.rsv_dwp_core.name}-LockDoNotDelete"
  lock_level = "CanNotDelete"
  notes      = "Initial Deployment Lock - Do Not Delete!"
  scope      = azurerm_recovery_services_vault.rsv_dwp_core.id
  count      = terraform.workspace == "prod" ? 1 : 0
}
