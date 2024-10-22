# # Security Center
# resource "azurerm_security_center_workspace" "security_center_dwp" {
#   scope        = "/subscriptions/${var.subscription_id[terraform.workspace]}"
#   workspace_id = azurerm_log_analytics_workspace.oms.id
# }
resource "null_resource" "security_center_oms_config" {
  provisioner "local-exec" {
    command = "az security workspace-setting create -n default --target-workspace '/subscriptions/${data.azurerm_client_config.client_config.subscription_id}/resourcegroups/${azurerm_log_analytics_workspace.oms.resource_group_name}/providers/microsoft.operationalinsights/workspaces/${azurerm_log_analytics_workspace.oms.name}'"
  }
  depends_on = [azurerm_log_analytics_workspace.oms]
}

# # Security Center - Contacts
# resource "azurerm_security_center_contact" "security_center_contact_dwp" {
#   email               = "crc.smi@dwp.gov.uk"
#   phone               = "+1-000-000-0000"
#   alert_notifications = true
#   alerts_to_admins    = true

# }

# Moved to deployment script, as local exec fails
# resource "null_resource" "security_center_contact_crc" {
#   provisioner "local-exec" {
#     command     = "az security contact create --email 'crc.smi@dwp.gov.uk' --name default --alert-notifications 'on' --alerts-admins 'on'"
#   }
#   depends_on = [null_resource.security_center_oms_config]

# }

# resource "null_resource" "security_center_contact_sre" {
#   provisioner "local-exec" {
#     command     = "az security contact create --email 'sre.azure@engineering.digital.dwp.gov.uk' --name default2 --alert-notifications 'on' --alerts-admins 'on'"
#   }
#   depends_on = [null_resource.security_center_contact_crc]

# }

resource "null_resource" "security_center_pricing_vm" {
  provisioner "local-exec" {
    command = "az security pricing create -n VirtualMachines --tier 'standard'"
  }
}

resource "null_resource" "security_center_pricing_sqlservers" {
  provisioner "local-exec" {
    command = "az security pricing create -n SqlServers --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_AppServices" {
  provisioner "local-exec" {
    command = "az security pricing create -n AppServices --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_StorageAccounts" {
  provisioner "local-exec" {
    command = "az security pricing create -n StorageAccounts --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_SqlServerVirtualMachines" {
  provisioner "local-exec" {
    command = "az security pricing create -n SqlServerVirtualMachines --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_KubernetesService" {
  provisioner "local-exec" {
    command = "az security pricing create -n KubernetesService --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_ContainerRegistry" {
  provisioner "local-exec" {
    command = "az security pricing create -n ContainerRegistry --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_KeyVaults" {
  provisioner "local-exec" {
    command = "az security pricing create -n KeyVaults --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_Dns" {
  provisioner "local-exec" {
    command = "az security pricing create -n Dns --tier 'standard'"
  }
}
resource "null_resource" "security_center_pricing_Arm" {
  provisioner "local-exec" {
    command = "az security pricing create -n Arm --tier 'standard'"
  }
}
