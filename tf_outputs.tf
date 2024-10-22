# Outputs

output "automation_account_id" {
  value = azurerm_automation_account.automation_account_core.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.oms.name
}

output "log_analytics_workspace_resourcegroup" {
  value = azurerm_log_analytics_workspace.oms.resource_group_name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.oms.id
}

# output "log_analytics_workspace_key" {
#  value = azurerm_log_analytics_workspace.oms.primary_shared_key
# }

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}
output "vnet_resourcegroup" {
  value = azurerm_virtual_network.vnet.resource_group_name
}
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
