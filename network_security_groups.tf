# Front End 01
resource "azurerm_network_security_group" "fe01" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-front-end-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.fe01.id} \
    --location ${var.location} --name ${azurerm_network_security_group.fe01.name}  \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.fe01.name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.fe01.id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }

}

resource "azurerm_network_security_rule" "fe01_deny_internet_in" {
  name                        = "Deny_Internet_In"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.fe01.name

  count = terraform.workspace == "sbox" ? 1 : 0


}

# Outbound
resource "azurerm_network_security_rule" "app_connector_outbound" {
    priority            = 100
    name                = "Out-to-Tableau-subnet"
    direction           = "Outbound"
    source_address_prefix = "*"
    source_port_range   = "*"
    destination_address_prefix = var.fe02_subnet_cidr[terraform.workspace][0]
    destination_port_range = "22"
    protocol            = "Tcp"
    access              = "Allow"
    resource_group_name = azurerm_resource_group.rg_network.name
    network_security_group_name = azurerm_network_security_group.fe01.name
    count = terraform.workspace == "prod" ? 1:0
}

resource "azurerm_subnet_network_security_group_association" "fe01" {
  subnet_id                 = azurerm_subnet.fe01.id
  network_security_group_id = azurerm_network_security_group.fe01.id
  depends_on = [
    azurerm_network_security_group.fe01
  ]
}

# Front End 02
resource "azurerm_network_security_group" "fe02" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-front-end-02"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.fe02.id} \
    --location ${var.location} --name ${azurerm_network_security_group.fe01.name}  \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.fe02.name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.fe02.id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }


}
resource "azurerm_network_security_rule" "fe02_deny_internet_in" {
  name                        = "Deny_Internet_In"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.fe02.name

  count = terraform.workspace == "sbox" ? 1 : 0


}
# If Modern Data Warehouse is selected to deploy (var.deploy_modern_data_warehouse set to true)), then FE02 and BE02 is delegated to data bricks
resource "azurerm_subnet_network_security_group_association" "fe02" {
  subnet_id                 = azurerm_subnet.fe02[count.index].id
  network_security_group_id = azurerm_network_security_group.fe02.id
  count                     = var.deploy_modern_data_warehouse == false ? 1 : 0
  depends_on = [
    azurerm_network_security_group.fe02
  ]

}
resource "azurerm_subnet_network_security_group_association" "fe02_mdw" {
  subnet_id                 = azurerm_subnet.fe02_mdw[count.index].id
  network_security_group_id = azurerm_network_security_group.fe02.id
  count                     = var.deploy_modern_data_warehouse == true ? 1 : 0
  depends_on = [
    azurerm_network_security_group.fe02
  ]

}

# Front End 03
resource "azurerm_network_security_group" "fe03" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-front-end-03"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  count               = var.deploy_modern_data_warehouse == true || var.deploy_fe03_subnet == true ? 1 : 0
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.fe03[count.index].id} \
    --location ${var.location} --name ${azurerm_network_security_group.fe03[count.index].name} \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.fe03[count.index].name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.fe03[count.index].id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }

}
resource "azurerm_network_security_rule" "fe03_ase-management-in" {
  name                        = "inbound-management"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "454-455"
  source_address_prefix       = "AppServiceManagement"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.fe03[count.index].name

  count = var.deploy_modern_data_warehouse == true ? 1 : 0


}
resource "azurerm_network_security_rule" "fe03_ase-internal" {
  name                        = "ase-internal-communication"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.fe03_subnet_cidr[terraform.workspace]
  destination_address_prefix  = var.fe03_subnet_cidr[terraform.workspace]
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.fe03[count.index].name

  count = var.deploy_modern_data_warehouse == true ? 1 : 0


}
resource "azurerm_network_security_rule" "fe03_ase-loadbalancer-in" {
  name                        = "load-balancer-inbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["454-455", "16001"]
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = var.fe03_subnet_cidr[terraform.workspace]
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.fe03[count.index].name

  count = var.deploy_modern_data_warehouse == true ? 1 : 0


}
resource "azurerm_network_security_rule" "fe03_ase-deny-all" {
  name                        = "deny-all"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.fe03[count.index].name

  count = var.deploy_modern_data_warehouse == true ? 1 : 0


}
resource "azurerm_subnet_network_security_group_association" "fe03" {
  subnet_id                 = azurerm_subnet.fe03[count.index].id
  network_security_group_id = azurerm_network_security_group.fe03[count.index].id
  depends_on = [
    azurerm_network_security_group.fe03
  ]

  count = var.deploy_modern_data_warehouse == true || var.deploy_fe03_subnet == true ? 1 : 0

}
# Back End 01
resource "azurerm_network_security_group" "be01" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-back-end-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.be01.id} \
    --location ${var.location} --name ${azurerm_network_security_group.fe01.name}  \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.be01.name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.be01.id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }


}

resource "azurerm_network_security_rule" "be01_deny_internet_in" {
  name                        = "Deny_Internet_In"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.be01.name

  count = terraform.workspace == "sbox" ? 1 : 0


}
resource "azurerm_subnet_network_security_group_association" "be01" {
  subnet_id                 = azurerm_subnet.be01.id
  network_security_group_id = azurerm_network_security_group.be01.id
  depends_on = [
    azurerm_network_security_group.be01
  ]
}

# Back End 02
resource "azurerm_network_security_group" "be02" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-back-end-02"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.be02.id} \
    --location ${var.location} --name ${azurerm_network_security_group.fe01.name}  \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.be02.name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.be02.id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }

}
resource "azurerm_network_security_rule" "be02_deny_internet_in" {
  name                        = "Deny_Internet_In"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.be02.name

  count = terraform.workspace == "sbox" ? 1 : 0


}
# If Modern Data Warehouse is selected to deploy (var.deploy_modern_data_warehouse set to true)), then FE02 and BE02 is delegated to data bricks
resource "azurerm_subnet_network_security_group_association" "be02" {
  subnet_id                 = azurerm_subnet.be02[count.index].id
  network_security_group_id = azurerm_network_security_group.be02.id
  count                     = var.deploy_modern_data_warehouse == false ? 1 : 0
  depends_on = [
    azurerm_network_security_group.be02
  ]

}
resource "azurerm_subnet_network_security_group_association" "be02_mdw" {
  subnet_id                 = azurerm_subnet.be02_mdw[count.index].id
  network_security_group_id = azurerm_network_security_group.be02.id
  count                     = var.deploy_modern_data_warehouse == true ? 1 : 0
  depends_on = [
    azurerm_network_security_group.be02
  ]

}


# SQL Managed Instance 01
resource "azurerm_network_security_group" "sqlmi01" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-sql-mi-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  count               = var.deploy_sqlmi_subnet == true ? 1 : 0
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.sqlmi01[count.index].id} \
    --location ${var.location} --name "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-sql-mi-01" \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.sqlmi01[count.index].name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.sqlmi01[count.index].id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }
}
// The  vnet is delegated to SQL, so deploying a SQL Managed Instance with automate network rules in to the existing subnet
// will automatically provision the correct rules

resource "azurerm_subnet_network_security_group_association" "sqlmi01" {
  subnet_id                 = azurerm_subnet.sqlmi01[count.index].id
  network_security_group_id = azurerm_network_security_group.sqlmi01[count.index].id

  count = var.deploy_sqlmi_subnet == true ? 1 : 0
  depends_on = [
    azurerm_network_security_group.sqlmi01
  ]
}

# Redis Cache
resource "azurerm_network_security_group" "redis01" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-redis-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  count               = var.deploy_redis_subnet == true ? 1 : 0
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.redis01[count.index].id} \
    --location ${var.location} --name "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-redis-01" \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365 --traffic-analytics true -l ${var.location} -n  ${azurerm_network_security_group.redis01[count.index].name}
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.redis01[count.index].id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }
}


resource "azurerm_subnet_network_security_group_association" "redis01" {
  subnet_id                 = azurerm_subnet.redis01[count.index].id
  network_security_group_id = azurerm_network_security_group.redis01[count.index].id

  count = var.deploy_redis_subnet == true ? 1 : 0
  depends_on = [
    azurerm_network_security_group.redis01
  ]
}

# Azure Bastion
resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-${local.location_prefix}-${terraform.workspace}-${var.pdu}-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  provisioner "local-exec" {
    command = <<EOF
    az network watcher flow-log create --nsg ${azurerm_network_security_group.bastion[count.index].id} \
    --location ${var.location} --name ${azurerm_network_security_group.fe01.name}  \
    --storage-account ${azurerm_storage_account.nsg_logs_account.id} \
    --workspace ${azurerm_log_analytics_workspace.oms.id} \
    --enabled true --format JSON --log-version 2 --retention 365
    EOF
  }

  provisioner "local-exec" {
    command = <<EOF
        az monitor diagnostic-settings create \
        --name nsg-diagnostics --resource ${azurerm_network_security_group.bastion[count.index].id} \
        --workspace ${azurerm_log_analytics_workspace.oms.id} \
        --logs '[ { "category": "NetworkSecurityGroupEvent", "enabled": true }, { "category": "NetworkSecurityGroupRuleCounter", "enabled": true } ]'
    EOF
  }
  count = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0

}

# Azure Bastion NSG Rules
# Ingress
# Allow HTTPS Inbound
resource "azurerm_network_security_rule" "bastion-https-in-allow" {
  name                        = "bastion-https-in-allow"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Allow Gateway Manager Inbound
resource "azurerm_network_security_rule" "bastion-gateway-in-allow" {
  name                        = "bastion-gateway-in-allow"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Allow Azure Load Balancer Inbound
resource "azurerm_network_security_rule" "bastion-load-balancer-in-allow" {
  name                        = "bastion-load-balancer-in-allow"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Allow Bastion Host Communication
resource "azurerm_network_security_rule" "bastion-host-comms-in-allow" {
  name                        = "bastion-host-comms-in-allow"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Bastion Default Deny Inbound
resource "azurerm_network_security_rule" "bastion-in-deny" {
  name                        = "bastion-in-default-deny"
  priority                    = 900
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Egress
# Allow SSH/RDP Outbound
resource "azurerm_network_security_rule" "bastion-ssh-rdp-out-allow" {
  name                        = "bastion-ssh-rdp-out-allow"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Allow Azure Cloud Outbound
resource "azurerm_network_security_rule" "bastion-azure-cloud-out-allow" {
  name                        = "bastion-azure-cloud-out-allow"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Allow Bastion Communication
resource "azurerm_network_security_rule" "bastion-comms-out-allow" {
  name                        = "bastion-comms-out-allow"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Allow Get Session Information
resource "azurerm_network_security_rule" "bastion-get-session-info-out-allow" {
  name                        = "bastion-get-session-info-out-allow"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Bastion Default Deny All Out
resource "azurerm_network_security_rule" "bastion-deny-all-out" {
  name                        = "Deny-All"
  priority                    = 900
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_network.name
  network_security_group_name = azurerm_network_security_group.bastion[count.index].name
  count                       = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
# Bastion Security Group Association
resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion[count.index].id
  network_security_group_id = azurerm_network_security_group.bastion[count.index].id
  depends_on = [
    azurerm_network_security_group.bastion,
    azurerm_network_security_rule.bastion-https-in-allow,
    azurerm_network_security_rule.bastion-gateway-in-allow,
    azurerm_network_security_rule.bastion-load-balancer-in-allow,
    azurerm_network_security_rule.bastion-host-comms-in-allow,
    azurerm_network_security_rule.bastion-in-deny,
    azurerm_network_security_rule.bastion-ssh-rdp-out-allow,
    azurerm_network_security_rule.bastion-azure-cloud-out-allow,
    azurerm_network_security_rule.bastion-comms-out-allow,
    azurerm_network_security_rule.bastion-get-session-info-out-allow,
    azurerm_network_security_rule.bastion-deny-all-out,
  ]
  count = var.deploy_azure_bastion[terraform.workspace] == true ? 1 : 0
}
