# Data Sources
# Client Config
data "azurerm_client_config" "client_config" {}
data "azurerm_subscription" "primary" {}
# Shared Services networks UK South
data "azurerm_virtual_network" "vnet_dwp_shared_services_core_uks" {
  provider            = azurerm.shared_services_uks
  name                = local.uks_shared_services_core_vnet_name[terraform.workspace]
  resource_group_name = local.uks_shared_services_core_vnet_resourcegroup[terraform.workspace]
}
data "azurerm_virtual_network" "vnet_dwp_shared_services_firewall_uks" {
  provider            = azurerm.shared_services_uks
  name                = local.uks_shared_services_firewall_vnet_name[terraform.workspace]
  resource_group_name = local.uks_shared_services_firewall_vnet_resourcegroup[terraform.workspace]
}
data "azurerm_virtual_network" "vnet_dwp_shared_services_er_uks" {
  provider            = azurerm.shared_services_uks
  name                = local.uks_shared_services_er_vnet_name[terraform.workspace]
  resource_group_name = local.uks_shared_services_er_vnet_resourcegroup[terraform.workspace]
}
data "azurerm_virtual_network" "vnet_dwp_shared_services_er_ukw" {
  provider            = azurerm.shared_services_ukw
  name                = local.ukw_shared_services_er_vnet_name[terraform.workspace]
  resource_group_name = local.ukw_shared_services_er_vnet_resourcegroup[terraform.workspace]
  count               = terraform.workspace == "stag" || terraform.workspace == "prod" ? 1 : 0
}

data "azurerm_virtual_network" "vnet_dwp_shared_services_inter_cloud_vpn_uks" {
  provider            = azurerm.shared_services_uks
  name                = local.uks_shared_services_inter_cloud_vpn_vnet_name[terraform.workspace]
  resource_group_name = local.uks_shared_services_inter_cloud_vpn_vnet_resourcegroup[terraform.workspace]
}
data "azurerm_virtual_network" "vnet_dwp_shared_services_vpn_uks" {
  provider            = azurerm.shared_services_uks
  name                = local.uks_shared_services_vpn_vnet_name[terraform.workspace]
  resource_group_name = local.uks_shared_services_vpn_vnet_resourcegroup[terraform.workspace]
}

# Shared Services networks UK West
data "azurerm_virtual_network" "vnet_dwp_shared_services_core_ukw" {
  provider            = azurerm.shared_services_ukw
  name                = local.ukw_shared_services_core_vnet_name[terraform.workspace]
  resource_group_name = local.ukw_shared_services_core_vnet_resourcegroup[terraform.workspace]
}

# Shared Services Dev Key Vault (SPN)
data "azurerm_key_vault" "dwp_keyvault" {
  provider            = azurerm.ss_dev_keyvault
  name                = "kv-dwp-cds-dev-ss"
  resource_group_name = "rg-kv-dwp-cds-dev-ss"
}

data "azurerm_key_vault_secret" "keyvault_secret_cloudspn_username" {
  provider     = azurerm.ss_dev_keyvault
  name         = "prdSsDeploymentSpnAppId"
  key_vault_id = data.azurerm_key_vault.dwp_keyvault.id
}

data "azurerm_key_vault_secret" "keyvault_secret_cloudspn_password" {
  provider     = azurerm.ss_dev_keyvault
  name         = "prdSsDeploymentSpnClientSecret"
  key_vault_id = data.azurerm_key_vault.dwp_keyvault.id
}
data "azurerm_key_vault_secret" "keyvault_secret_cloudspn_pat" {
  provider     = azurerm.ss_dev_keyvault
  name         = "prdSsDeploymentSpnPAT"
  key_vault_id = data.azurerm_key_vault.dwp_keyvault.id
}
# Azure DevOps project
data "azuredevops_project" "project" {
  name = var.pdu
}

data "azuredevops_git_repository" "repository" {
  name       = "${var.pdu}-network"
  project_id = data.azuredevops_project.project.id
}

# Azure Active Directory groups
data "azuread_group" "dwp_sre_actiongroup_rg" {
  display_name = var.dwp_sre_actiongroup_rg[terraform.workspace]
}

######################################################
# Zscaler App Connector 

# data "azurerm_key_vault_secret" "default_username" {
#   name      = "default-username"
#   key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
#   count = terraform.workspace == "prod" ? 1:0
# }

data "azurerm_key_vault_secret" "app-connector-public-key" {
  name      = "app-connector-public-key"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  depends_on = [azurerm_key_vault_secret.app-connector-public-key]
  count = terraform.workspace == "prod" ? 1:0
}

data "azurerm_key_vault_secret" "keyvault_secret_dwp_vm_username" {
  name         = "default-username"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  count = terraform.workspace == "prod" ? 1:0
}

# Uncomment after the provisioning key has been manually added to the core key vault in Prod
data "azurerm_key_vault_secret" "app-connector-provisioning-key" {
  name      = "app-connector-provisioning-key"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  count = terraform.workspace == "prod" ? 1:0
}
