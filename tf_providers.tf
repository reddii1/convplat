# Terraform Providers
# Azure AD Provider

# Shared Services Providers
provider "azurerm" {
  subscription_id = local.uks_shared_services_subscription_id[terraform.workspace]
  alias           = "shared_services_uks"
  features {}
  skip_provider_registration = true
}
provider "azurerm" {
  subscription_id = local.ukw_shared_services_subscription_id[terraform.workspace]
  alias           = "shared_services_ukw"
  features {}
  skip_provider_registration = true
}

provider "azurerm" {
  tenant_id       = "96f1f6e9-1057-4117-ac28-80cdfe86f8c3"
  subscription_id = var.subscription_id[terraform.workspace]
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = true
    }
  }
  skip_provider_registration = true
}

provider "azurerm" {
  tenant_id       = "96f1f6e9-1057-4117-ac28-80cdfe86f8c3"
  subscription_id = "304e776d-6a37-425c-9304-cd3a77e4c6fe"
  alias           = "ss_dev_keyvault"
  features {}
  skip_provider_registration = true
}

provider "azuread" {
}

provider "random" {
}

provider "null" {
}

provider "template" {
}

provider "tls" {
}

provider "azuredevops" {
}

provider "azapi" {
}
