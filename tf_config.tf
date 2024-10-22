# Remote State Backend
# terraform {
#   backend "azurerm" {
#     container_name       = "tfstate"
#     key                  = "network.tfstate"
#   }
# }

# Remote State Backend
terraform {
  backend "azurerm" {
  }
}
