## Resources
# Resource Group network
resource "azurerm_resource_group" "rg_network" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-network"
  location = var.location
  tags     = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
resource "azurerm_management_lock" "rg_network_lock" {
  name       = "${azurerm_resource_group.rg_network.name}-Lock-DoNotDelete"
  scope      = azurerm_resource_group.rg_network.id
  lock_level = "CanNotDelete"
  count      = terraform.workspace == "prod" && var.enable_locks == true ? 1 : 0
}
# Resource Group OMS
resource "azurerm_resource_group" "rg_oms" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-oms"
  location = var.location
  tags     = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
resource "azurerm_management_lock" "rg_oms_lock" {
  name       = "${azurerm_resource_group.rg_oms.name}-Lock-DoNotDelete"
  scope      = azurerm_resource_group.rg_oms.id
  lock_level = "CanNotDelete"
  count      = terraform.workspace == "prod" && var.enable_locks == true ? 1 : 0
}
# Resource Group management
resource "azurerm_resource_group" "rg_core" {
  name     = "rg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-core"
  location = var.location
  tags     = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
resource "azurerm_management_lock" "rg_core_lock" {
  name       = "${azurerm_resource_group.rg_core.name}-Lock-DoNotDelete"
  scope      = azurerm_resource_group.rg_core.id
  lock_level = "CanNotDelete"
  count      = terraform.workspace == "prod" && var.enable_locks == true ? 1 : 0
}
