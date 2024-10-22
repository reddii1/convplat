# Add SPN  as a service endpoint in the DevOps project

resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id            = data.azuredevops_project.project.id
  service_endpoint_name = "${var.pdu}-${terraform.workspace}"
  credentials {
    serviceprincipalid  = azuread_service_principal.dwp_ad_spn.application_id
    serviceprincipalkey = random_password.password.result
  }
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id[terraform.workspace]
  azurerm_subscription_name = data.azurerm_subscription.primary.display_name

  depends_on = [azuread_group_member.dwp_pdu_pduowner_group]

}


# Create variable group with details of DWP Cloud SPN

resource "azuredevops_variable_group" "variablegroup" {
  project_id   = data.azuredevops_project.project.id
  name         = "Credentials"
  description  = "Credentials used in the pipeline"
  allow_access = true

  variable {
    name         = "prdSsDeploymentSpnAppId"
    secret_value = data.azurerm_key_vault_secret.keyvault_secret_cloudspn_username.value
    is_secret    = true
  }

  variable {
    name         = "prdSsDeploymentSpnClientSecret"
    secret_value = data.azurerm_key_vault_secret.keyvault_secret_cloudspn_password.value
    is_secret    = true
  }
  variable {
    name         = "prdSsDeploymentSpnPAT"
    secret_value = data.azurerm_key_vault_secret.keyvault_secret_cloudspn_pat.value
    is_secret    = true
  }
  count = terraform.workspace == "sbox" ? 1 : 0
}

resource "azuredevops_build_definition" "build" {
  project_id = data.azuredevops_project.project.id
  name       = "${var.pdu}-network"
  # path       = "\\ExampleFolder"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type = "TfsGit"
    repo_id   = data.azuredevops_git_repository.repository.id
    yml_path  = "pipelines/deploy.yaml"
  }

  variable_groups = [
    azuredevops_variable_group.variablegroup[count.index].id
  ]
  count = terraform.workspace == "sbox" ? 1 : 0
}
