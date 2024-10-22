# Resource Naming Convention Policy
resource "azurerm_policy_definition" "policy_def_dwp_default_resourcenamingpattern" {
  name         = "poldef-${local.location_prefix}-${terraform.workspace}-${var.pdu}-deny-resource-naming-pattern"
  display_name = "Default Resource Naming Patterns"
  policy_type  = "Custom"
  mode         = "All"
  description  = "Deny the creation of resources that do not conform to the resource naming standard within the subscription"

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "equals": "[parameters('resourceType')]",
        "field": "type"
      },
      {
        "not": {
          "field": "name",
          "like": "[parameters('namePattern')]"
        }
      },
      {
        "not": {
          "field": "name",
          "like": "aks-*"
        }
      },
      {
        "not": {
          "field": "name",
          "contains": "${local.location_prefix}-${terraform.workspace}-${var.pdu}"
        }
      },
      {
        "not": {
          "field": "name",
          "contains": "dwp-${terraform.workspace}-${var.pdu}"
        }
      },
      {
        "not": {
          "field": "name",
          "contains": "${local.location_prefix}${terraform.workspace}${local.directorate}${local.deputydirectorate}"
        }
      },
      {
        "not": {
          "field": "name",
          "contains": "dwp${terraform.workspace}${local.directorate}${local.deputydirectorate}"
        }
      },
      {
        "not":{
          "field": "name",
          "like": "vhd*"
        }
      },
      {
        "not": {
          "field": "name",
          "like": "runner*"
        }
      },
      {
        "not": {
          "field": "name",
          "like": "avs-*"
        }
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "namePattern": {
    "metadata": {
      "description": "Pattern to use for names. Can include wildcard (*).",
      "strongType": "namePattern"
    },
    "type": "String"
  },
  "resourceType": {
    "metadata": {
      "description": "Resource Type String. <ResourceProvider>/<type>"
    },
    "type": "String"
  }
}
PARAMETERS

  count = terraform.workspace != "sbox" ? 1 : 0
}

# Storage Account Naming Pattern Policy Assignment
resource "azurerm_subscription_policy_assignment" "policy_assignment_default_resource_naming_pattern_storageaccounts" {
  name                 = "polass-${local.location_prefix}-${terraform.workspace}-${var.pdu}-defaultresourcenaming-storageaccounts"
  display_name         = "Default Resource Naming Pattern for Storage Accounts"
  policy_definition_id = azurerm_policy_definition.policy_def_dwp_default_resourcenamingpattern[count.index].id
  subscription_id      = data.azurerm_subscription.primary.id
  description          = "Deny the creation of Storage Accounts that do not conform to the resource naming standard within the subscription"

  parameters = <<PARAMETERS
{
  "namePattern": {
    "value": "str?${local.location_prefix}${terraform.workspace}${local.directorate}${local.deputydirectorate}*"
  },
  "resourceType": {
    "value": "Microsoft.Storage/storageAccounts"
  }
}
PARAMETERS

  count = terraform.workspace != "sbox" ? 1 : 0
}

# Virtual Machine Naming Pattern Policy Assignment
resource "azurerm_subscription_policy_assignment" "policy_assignment_default_resource_naming_pattern_vm" {
  name                 = "polass-${local.location_prefix}-${terraform.workspace}-${var.pdu}-defaultresourcenaming-vm"
  display_name         = "Default Resource Naming Pattern for Virtual Machines"
  policy_definition_id = azurerm_policy_definition.policy_def_dwp_default_resourcenamingpattern[count.index].id
  subscription_id      = data.azurerm_subscription.primary.id
  description          = "Deny the creation of Virtual Machines that do not conform to the resource naming standard within the subscription"

  parameters = <<PARAMETERS
{
  "namePattern": {
    "value": "${local.location_prefix}${local.environment_prefix}cc*"
  },
  "resourceType": {
    "value": "Microsoft.Compute/virtualMachines"
  }
}
PARAMETERS

  count = terraform.workspace != "sbox" ? 1 : 0
}

# Virtual Network Naming Pattern Policy Assignment
resource "azurerm_subscription_policy_assignment" "policy_assignment_default_resource_naming_pattern_vnet" {
  name                 = "polass-${local.location_prefix}-${terraform.workspace}-${var.pdu}-defaultresourcenaming-vnet"
  display_name         = "Default Resource Naming Pattern for Virtual Networks"
  policy_definition_id = azurerm_policy_definition.policy_def_dwp_default_resourcenamingpattern[count.index].id
  subscription_id      = data.azurerm_subscription.primary.id
  description          = "Deny the creation of Virtual Networks that do not conform to the resource naming standard within the subscription"

  parameters = <<PARAMETERS
{
  "namePattern": {
    "value": "vnet-?-${terraform.workspace}-${var.pdu}-*"
  },
  "resourceType": {
    "value": "Microsoft.Network/virtualNetworks"
  }
}
PARAMETERS

  count = terraform.workspace != "sbox" ? 1 : 0
}

# Azure Subnet NSG Audit Policy
resource "azurerm_policy_definition" "policy_def_dwp_deny_subnetwithoutnsg" {
  name         = "poldef-${local.location_prefix}-${terraform.workspace}-${var.pdu}-deny-subnetwithoutnsg"
  display_name = "Deny Subnet creation without an NSG"
  policy_type  = "Custom"
  mode         = "All"
  description  = "Deny the use of Subnets without an assigned Network Security Group (NSG) within the subscription"

  policy_rule = <<POLICY_RULE
{
  "if": {
    "anyOf": [
      {
        "allOf": [
          {
            "equals": "Microsoft.Network/virtualNetworks",
            "field": "type"
          },
          {
            "exists": "false",
            "field": "Microsoft.Network/virtualNetworks/subnets[*].networkSecurityGroup.id"
          }
        ]
      },
      {
        "allOf": [
          {
            "equals": "Microsoft.Network/virtualNetworks/subnets",
            "field": "type"
          },
          {
            "exists": "false",
            "field": "Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup.id"
          }
        ]
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE

  count = terraform.workspace != "sbox" && var.disable_nsg_policy != true ? 1 : 0
}

resource "azurerm_subscription_policy_assignment" "policy_assignment_deny_subnetwithoutnsg" {
  name                 = "polass-${local.location_prefix}-${terraform.workspace}-${var.pdu}-deny-subnetwithoutnsg"
  display_name         = "Deny Subnet creation without an NSG"
  policy_definition_id = azurerm_policy_definition.policy_def_dwp_deny_subnetwithoutnsg[count.index].id
  subscription_id      = data.azurerm_subscription.primary.id
  description          = "Deny the use of Subnets without an assigned Network Security Group (NSG) within the subscription"
  count                = terraform.workspace != "sbox" && var.disable_nsg_policy != true ? 1 : 0

  depends_on = [
    azurerm_subnet_network_security_group_association.be02,
    azurerm_subnet_network_security_group_association.mysqlfs
  ]
}
