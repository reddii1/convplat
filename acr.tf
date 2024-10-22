# Create an Azure Container Registry

resource "azurerm_container_registry" "acr" {
  name                = replace("acr${local.location_prefix}${terraform.workspace}${var.pdu}", "-", "")
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_core.name
  sku                 = "Premium"
  admin_enabled       = false
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  count               = var.deploy_container_registry == true ? 1 : 0
}

# ACR Role Assignment
resource "azurerm_role_assignment" "aks_spn_acrpull_role" {
  scope                = azurerm_container_registry.acr[count.index].id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.dwp_ad_spn.object_id
  count                = var.deploy_container_registry == true ? 1 : 0
}
