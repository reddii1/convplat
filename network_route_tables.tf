# Front End 01
resource "azurerm_route_table" "fe01" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-front-end-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  dynamic "route" {
    for_each = local.private_routes
    content {
      name                   = route.value["route_name"]
      address_prefix         = route.value["address_prefix"]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.csr_ip[terraform.workspace]
    }
  }

  route {
    name                   = "route_to_internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

  route {
    name                   = "route_to_sub-dwp-ss-core-fw-waf-in"
    address_prefix         = local.waf_address_prefix[terraform.workspace]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

  count = terraform.workspace != "sbox" ? 1 : 0
}

resource "azurerm_subnet_route_table_association" "fe01" {
  subnet_id      = azurerm_subnet.fe01.id
  route_table_id = azurerm_route_table.fe01[count.index].id
  count          = terraform.workspace != "sbox" ? 1 : 0
  depends_on = [
    azurerm_route_table.fe01
  ]

}
# Front End 02
resource "azurerm_route_table" "fe02" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-front-end-02"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  dynamic "route" {
    for_each = local.private_routes
    content {
      name                   = route.value["route_name"]
      address_prefix         = route.value["address_prefix"]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.csr_ip[terraform.workspace]
    }
  }

  route {
    name                   = "route_to_internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

  route {
    name                   = "route_to_sub-dwp-ss-core-fw-waf-in"
    address_prefix         = local.waf_address_prefix[terraform.workspace]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

  count = terraform.workspace != "sbox" ? 1 : 0
}
# If Modern Data Warehouse is selected to deploy (var.deploy_modern_data_warehouse set to true)), then FE02 and BE02 is delegated to data bricks
resource "azurerm_subnet_route_table_association" "fe02" {
  subnet_id      = azurerm_subnet.fe02[count.index].id
  route_table_id = azurerm_route_table.fe02[count.index].id

  count = terraform.workspace != "sbox" && var.deploy_modern_data_warehouse == false ? 1 : 0
  depends_on = [
    azurerm_route_table.fe02
  ]

}
resource "azurerm_subnet_route_table_association" "fe02_mdw" {
  subnet_id      = azurerm_subnet.fe02_mdw[count.index].id
  route_table_id = azurerm_route_table.fe02[count.index].id
  count          = terraform.workspace != "sbox" && var.deploy_modern_data_warehouse == true ? 1 : 0
  depends_on = [
    azurerm_route_table.fe02
  ]

}

# Front End 03
resource "azurerm_route_table" "fe03" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-front-end-03"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  count               = var.deploy_modern_data_warehouse == true && terraform.workspace != "sbox" ? 1 : 0
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  dynamic "route" {
    for_each = local.private_routes
    content {
      name                   = route.value["route_name"]
      address_prefix         = route.value["address_prefix"]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.csr_ip[terraform.workspace]
    }
  }
  dynamic "route" {
    for_each = local.ase_routes
    content {
      name           = route.value["route_name"]
      address_prefix = route.value["address_prefix"]
      next_hop_type  = "Internet"
    }
  }

  route {
    name                   = "route_to_internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

  route {
    name                   = "route_to_sub-dwp-ss-core-fw-waf-in"
    address_prefix         = local.waf_address_prefix[terraform.workspace]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

}

resource "azurerm_subnet_route_table_association" "fe03" {
  subnet_id      = azurerm_subnet.fe03[count.index].id
  route_table_id = azurerm_route_table.fe03[count.index].id

  count = var.deploy_modern_data_warehouse == true || var.deploy_fe03_subnet == true && terraform.workspace != "sbox" ? 1 : 0
  depends_on = [
    azurerm_route_table.fe03
  ]

}
# Back End 01
resource "azurerm_route_table" "be01" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-back-end-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  route {
    name                   = "route_to_internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }



  count = terraform.workspace != "sbox" ? 1 : 0
}

resource "azurerm_subnet_route_table_association" "be01" {
  subnet_id      = azurerm_subnet.be01.id
  route_table_id = azurerm_route_table.be01[count.index].id

  count = terraform.workspace != "sbox" ? 1 : 0
  depends_on = [
    azurerm_route_table.be02
  ]

}
# Back End 02
resource "azurerm_route_table" "be02" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-back-end-02"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  route {
    name                   = "route_to_internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }

  count = terraform.workspace != "sbox" ? 1 : 0
}
# If Modern Data Warehouse is selected to deploy (var.deploy_modern_data_warehouse set to true)), then FE02 and BE02 is delegated to data bricks
resource "azurerm_subnet_route_table_association" "be02" {
  subnet_id      = azurerm_subnet.be02[count.index].id
  route_table_id = azurerm_route_table.be02[count.index].id

  count = terraform.workspace != "sbox" && var.deploy_modern_data_warehouse == false ? 1 : 0
  depends_on = [
    azurerm_route_table.be02
  ]

}
resource "azurerm_subnet_route_table_association" "be02_mdw" {
  subnet_id      = azurerm_subnet.be02_mdw[count.index].id
  route_table_id = azurerm_route_table.be02[count.index].id
  count          = terraform.workspace != "sbox" && var.deploy_modern_data_warehouse == true ? 1 : 0
  depends_on = [
    azurerm_route_table.be02
  ]

}

# SQL Managed Instance
resource "azurerm_route_table" "sqlmi01" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-sql-mi-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  count               = terraform.workspace != "sbox" && var.deploy_sqlmi_subnet == true ? 1 : 0
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })

}
// The  vnet is delegated to SQL, so deploying a SQL Managed Instance with automate network rules in to the existing subnet
// will automatically provision the correct rules

# Redis Cache
resource "azurerm_route_table" "redis01" {
  name                = "udr-${local.location_prefix}-${terraform.workspace}-${var.pdu}-redis-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_network.name
  count               = terraform.workspace != "sbox" && var.deploy_redis_subnet == true ? 1 : 0
  tags                = merge(var.tags, { "Environment" = var.environment_tags[terraform.workspace] })
  route {
    name                   = "route_to_internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.core_firewall_ip[terraform.workspace]
  }
}

resource "azurerm_subnet_route_table_association" "redis01" {
  subnet_id      = azurerm_subnet.redis01[count.index].id
  route_table_id = azurerm_route_table.redis01[count.index].id
  count          = terraform.workspace != "sbox" && var.deploy_redis_subnet == true ? 1 : 0
  depends_on = [
    azurerm_route_table.redis01
  ]
}
