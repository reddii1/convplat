# Azure Automation Account
resource "azurerm_automation_account" "automation_account_core" {
  name                = "aaa-${local.location_prefix}-${terraform.workspace}-${var.pdu}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name

  sku_name = "Basic"

  tags = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
}
# Link to Log analytics
resource "azurerm_log_analytics_linked_service" "oms_linked_service_dwp" {
  resource_group_name = azurerm_resource_group.rg_oms.name
  workspace_id        = azurerm_log_analytics_workspace.oms.id
  read_access_id      = azurerm_automation_account.automation_account_core.id
  depends_on = [
    azurerm_log_analytics_workspace.oms,
    azurerm_automation_account.automation_account_core
  ]
}
