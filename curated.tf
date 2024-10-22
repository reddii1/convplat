
#  must be randomised and put in kv eventually
variable "sql_admin_username" {
    type = string
default       = "notATypicalSQLIdentifier"
}
variable "sql_admin_password" {
    type = string
    default       = "2BeChanged"

}


resource "random_string" "randomlower" {
    length = 8
    special = false
    upper = false
}
 
# Define Azure SQL Server

resource "azurerm_mssql_server" "curated_server" {
  count = length(local.cpenvprefix[terraform.workspace])
  name                         = "sql-server-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}-${random_string.randomlower.result}"
  resource_group_name          = azurerm_resource_group.rg_analytics[0].name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "curateddb" {
count = length(local.cpenvprefix[terraform.workspace])
  name                = "sql-db-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}-${random_string.randomlower.result}"
  server_id      = azurerm_mssql_server.curated_server[count.index].id


#   # prevent the possibility of accidental data loss
#   lifecycle {
#     prevent_destroy = true
#   }
}
