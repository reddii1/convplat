terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.80.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "0.2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.2.1"
    }
    azapi = {
      source = "Azure/azapi"
      version = "1.10.0"
    }
  }
  required_version = "1.3.5"
}
