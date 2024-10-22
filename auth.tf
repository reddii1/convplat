# PDU AD Application
resource "azuread_application" "dwp_ad_app" {
  display_name = "spn-${var.pdu}-${terraform.workspace}"
  web {
    homepage_url = "https://${upper(var.pdu)}-${upper(terraform.workspace)}-SPN"
    implicit_grant {
      access_token_issuance_enabled = true
    }
  }
}

# PDU AD SPN
resource "azuread_service_principal" "dwp_ad_spn" {
  application_id = azuread_application.dwp_ad_app.application_id
}
resource "random_password" "password" {
  length  = 64
  special = false
}
resource "azuread_service_principal_password" "dwp_ad_spn_secret" {
  service_principal_id = azuread_service_principal.dwp_ad_spn.id
  value                = random_password.password.result
  end_date             = "2099-01-01T00:00:00Z"
}

## Add SPN to shared image gallery group
resource "azuread_group_member" "shared-image-gallery-reader-spn" {
  group_object_id  = "2cacc16a-07d4-4d7c-bb08-f37bda6e8457"
  member_object_id = azuread_service_principal.dwp_ad_spn.id
}

# Add SPN Credentials to Shared Services KeyVault
resource "azurerm_key_vault_secret" "keyvault_secret_dwp_spn_app_id" {
  name         = "spn-${var.pdu}-${terraform.workspace}-id"
  value        = azuread_service_principal.dwp_ad_spn.application_id
  content_type = "SPN App Id"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  tags         = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
  depends_on = [azurerm_role_assignment.dwp_pdu_key_vault_secrets_officer,
    azuread_group_member.dwp_pdu_key_vault_secrets_officer,
  ]
}

resource "azurerm_key_vault_secret" "keyvault_secret_dwp_spn_secret" {
  name         = "spn-${var.pdu}-${terraform.workspace}-secret"
  value        = azuread_service_principal_password.dwp_ad_spn_secret.value
  content_type = "SPN App Secret"
  key_vault_id = azurerm_key_vault.keyvault_dwp_core.id
  tags         = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
  depends_on = [azurerm_role_assignment.dwp_pdu_key_vault_secrets_officer,
  azuread_group_member.dwp_pdu_key_vault_secrets_officer, ]
}

# Limited Owner Role - creates custom role equivalent to owner, minus network, policy and rbac permissions
resource "azurerm_role_definition" "role_definition_pdu_owner" {
  name        = "PDU Owner Role - ${upper(var.pdu)}-${upper(terraform.workspace)}"
  description = "PDU Subscription limited Owner role (Owner less policy, rbac and net routing)"
  scope       = data.azurerm_subscription.primary.id

  permissions {
    actions = [
      "*",
    ]

    not_actions = [
      "Microsoft.Authorization/policyAssignments/write",
      "Microsoft.Authorization/policyAssignments/delete",
      "Microsoft.Authorization/policyDefinitions/write",
      "Microsoft.Authorization/policyDefinitions/delete",
      "Microsoft.Authorization/policySetDefinitions/write",
      "Microsoft.Authorization/policySetDefinitions/delete",
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
      "Microsoft.Authorization/roleDefinitions/write",
      "Microsoft.Authorization/roleDefinitions/delete",
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
      "Microsoft.Network/routeTables/write",
      "Microsoft.Network/routeTables/delete",
      "Microsoft.Network/routeTables/routes/write",
      "Microsoft.Network/routeTables/routes/delete",
      "Microsoft.Authorization/policyExemptions/write",
      "Microsoft.Authorization/policyExemptions/delete",
    ]
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]
}

## AD Groups and Role Assignments for RBAC
# Owner Group
resource "azuread_group" "dwp_pdu_owner_group" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-Owners"
}

resource "azurerm_role_assignment" "dwp_pdu_owner_group_role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Owner"
  principal_id         = azuread_group.dwp_pdu_owner_group.id
}

# PDU Owner Group
resource "azuread_group" "dwp_pdu_pduowner_group" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-PDUOwners"
}

resource "azurerm_role_assignment" "dwp_pdu_pduowner_group_role" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = azurerm_role_definition.role_definition_pdu_owner.role_definition_resource_id
  principal_id       = azuread_group.dwp_pdu_pduowner_group.id
}

## Add SPN to PDU Owner Group (or full owner if var.spn_full_owner set to true. Should be false by default)
resource "azuread_group_member" "dwp_pdu_pduowner_group" {
  group_object_id  = var.spn_full_owner == true ? azuread_group.dwp_pdu_owner_group.id : azuread_group.dwp_pdu_pduowner_group.id
  member_object_id = azuread_service_principal.dwp_ad_spn.id
}

# Add PDU SPN TO SRE BMC ActionGroup AAD group
resource "azuread_group_member" "dwp_sre_actiongroups_group" {
  group_object_id  = data.azuread_group.dwp_sre_actiongroup_rg.id
  member_object_id = azuread_service_principal.dwp_ad_spn.id
}

# Contributor Group
resource "azuread_group" "dwp_pdu_contributor_group" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-Contributors"
}

resource "azurerm_role_assignment" "dwp_pdu_contributor_group_role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.dwp_pdu_contributor_group.id
}

# Reader Group
resource "azuread_group" "dwp_pdu_reader_group" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-Readers"
}

resource "azurerm_role_assignment" "dwp_pdu_reader_group_role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.dwp_pdu_reader_group.id
}

# Monitoring Group
resource "azuread_group" "dwp_pdu_monitoring_group" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-Monitoring"
}

resource "azurerm_role_assignment" "dwp_pdu_monitoring_group_role_1" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azuread_group.dwp_pdu_monitoring_group.id
}

resource "azurerm_role_assignment" "dwp_pdu_monitoring_group_role_2" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azuread_group.dwp_pdu_monitoring_group.id
}

resource "azurerm_role_assignment" "dwp_pdu_monitoring_group_role_3" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Security Admin"
  principal_id         = azuread_group.dwp_pdu_monitoring_group.id
}

# Cost Management Group
resource "azuread_group" "dwp_pdu_cost_group" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-Cost"
}

resource "azurerm_role_assignment" "dwp_pdu_cost_group_role_1" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Billing Reader"
  principal_id         = azuread_group.dwp_pdu_cost_group.id
}

resource "azurerm_role_assignment" "dwp_pdu_cost_group_role_2" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azuread_group.dwp_pdu_cost_group.id
}

## Key Vault Groups

# Key Vault Contributor - Does not allow access to keys, secret and certificates
resource "azurerm_role_assignment" "key_vault_contributor_role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = azuread_group.dwp_pdu_contributor_group.id
}

# Key Vault Certificates Officer
resource "azuread_group" "dwp_pdu_key_vault_cert_officer" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-KeyVault-Certificates-Officer"
}

resource "azurerm_role_assignment" "dwp_pdu_key_vault_cert_officer" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azuread_group.dwp_pdu_key_vault_cert_officer.id
}

# Key Vault Crypto Officer

resource "azuread_group" "dwp_pdu_key_vault_crypto_officer" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-KeyVault-Crypto-Officer"
}

resource "azurerm_role_assignment" "dwp_pdu_key_vault_crypto_officer" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azuread_group.dwp_pdu_key_vault_crypto_officer.id
}

# Key Vault Crypto User
resource "azuread_group" "dwp_pdu_key_vault_crypto_user" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-KeyVault-Crypto-User"
}

resource "azurerm_role_assignment" "dwp_pdu_key_vault_crypto_user" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azuread_group.dwp_pdu_key_vault_crypto_user.id
}

# Key Vault Secrets Officer
resource "azuread_group" "dwp_pdu_key_vault_secrets_officer" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-KeyVault-Secrets-Officer"
}

resource "azurerm_role_assignment" "dwp_pdu_key_vault_secrets_officer" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_group.dwp_pdu_key_vault_secrets_officer.id
}

# Key Vault Secrets User
resource "azuread_group" "dwp_pdu_key_vault_secrets_user" {
  display_name = "Role-PDU-${upper(var.pdu)}-${upper(terraform.workspace)}-KeyVault-Secrets-User"
}

resource "azurerm_role_assignment" "dwp_pdu_key_vault_secrets_user" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_group.dwp_pdu_key_vault_secrets_user.id
}

## Add DWP Cloud Services to Key Vaults Secrets Officer so it can manage key_vault secrets
resource "azuread_group_member" "dwp_pdu_key_vault_secrets_officer" {
  group_object_id  = azuread_group.dwp_pdu_key_vault_secrets_officer.id
  member_object_id = "53e8dbe1-ed7f-42d0-8f41-31811dd75cd1"
}

## Add DWP Cloud Services to Key Vaults Crypto Officer so it can manage key_vault keys
resource "azuread_group_member" "dwp_pdu_key_vault_crypto_officer" {
  group_object_id  = azuread_group.dwp_pdu_key_vault_crypto_officer.id
  member_object_id = "53e8dbe1-ed7f-42d0-8f41-31811dd75cd1"
}
