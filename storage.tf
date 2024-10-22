# NSG Flow Logs
resource "azurerm_storage_account" "nsg_logs_account" {
  name                            = replace("str${local.location_prefix}${terraform.workspace}${var.pdu}nsglogs", "-", "")
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg_core.name
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = "true"
  allow_nested_items_to_be_public = false
  tags                            = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })

}

# # VM Diagnostic Storage Accounts
# resource "azurerm_storage_account" "diag_accounts" {
#   name                      = replace("strdwp${terraform.workspace}${var.pdu}diag0${count.index+1}", "-", "")
#   count                     = 4
#   location                  = var.location
#   resource_group_name       = azurerm_resource_group.rg_core.name
#   account_tier              = "Standard"
#   account_kind              = "StorageV2"
#   account_replication_type  = "LRS"
#   enable_https_traffic_only = "true"
# }

# # CloudShell Storage Account
# resource "azurerm_storage_account" "cloudshell_account" {
#   name                      = replace("strdwp${terraform.workspace}${var.pdu}shell", "-", "")
#   location                  = var.location
#   resource_group_name       = azurerm_resource_group.rg_core.name
#   account_tier              = "Standard"
#   account_kind              = "StorageV2"
#   account_replication_type  = "LRS"
#   enable_https_traffic_only = "true"

# }

# resource "azurerm_storage_container" "cloudshell_container" {
#   name                  = replace("strdwp${terraform.workspace}${var.pdu}shellcontainer", "-", "")
#   storage_account_name  = azurerm_storage_account.cloudshell_account.name
#   container_access_type = "private"
# }

# resource "azurerm_storage_share" "cloudshell_fileshare" {
#   name                 = replace("strdwp${terraform.workspace}${var.pdu}shellshare", "-", "")
#   storage_account_name = azurerm_storage_account.cloudshell_account.name
#   quota                = 10
# }
