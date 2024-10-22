# resource "azurerm_virtual_machine" "vm" {
#   count = length(local.cpenvprefix[terraform.workspace])
#   name                = "uksuccpowerbi-vm-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}"
#   resource_group_name = azurerm_resource_group.rg_analytics[0].name
#   location            = var.location

#   vm_size               = "Standard_DS1_v2"
#   delete_os_disk_on_termination    = true
#   delete_data_disks_on_termination = true

#   network_interface_ids =  [azurerm_network_interface.shir[count.index].id,]

# storage_image_reference {
#     id = data.azurerm_shared_image_version.win2019_latestGoldImage.id
# }

# storage_os_disk {

#     name              = "osDiskShir-${local.location_prefix}-${local.cpenvprefix[terraform.workspace][count.index]}${terraform.workspace}-${var.pdu}"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }
#   os_profile {
#     computer_name  = "hostname"
#     admin_username = "testadmin"
#     // This MUST be randomised and stored in kv eventually
#     admin_password = "Password12345!"

#   }

#   os_profile_windows_config {
#     provision_vm_agent = true
#     enable_automatic_upgrades = false

#   }


# }

# resource "time_sleep" "wait_120_seconds" {
#   depends_on = [ azurerm_windows_virtual_machine.vm]
#   create_duration = "120s"
# }


# #blob for the powershell file to go. This is for the VM to pull from
# resource "azurerm_storage_blob" "powerbi_script" {
#   name                   = "powerbi.ps1"
#   storage_account_name   = azurerm_storage_account.shir_storage.name
#   storage_container_name = azurerm_storage_container.shir.name
#   type                   = "Block"
#   access_tier            = "Cool"
#   source                 = "../scripts/powerbi_download_install.ps1"
# }



##VM Custom Script Extension to download and install the powershell script to  install PowerBi Gateway

# resource "azurerm_virtual_machine_extension" "powerbi_gateway_install" {
#   count = length(local.cpenvprefix[terraform.workspace])
#   name                       = "install-powerbi-gateway"
#   virtual_machine_id         = azurerm_windows_virtual_machine.vm[count.index].id
#   publisher                  = "Microsoft.Compute"
#   type                       = "CustomScriptExtension"
#   type_handler_version       = "1.10"
#   auto_upgrade_minor_version = true
#   depends_on = [ time_sleep.wait_120_seconds ]

#   protected_settings = <<PROTECTED_SETTINGS
#       {
#           "fileUris": ["${format("https://%s.blob.core.windows.net/%s/%s", azurerm_storage_account.shir_storage.name, azurerm_storage_container.shir.name, azurerm_storage_blob.powerbi_script.name)}"],
#           "commandToExecute": "${join(" ", ["powershell.exe -ExecutionPolicy Unrestricted -File",azurerm_storage_blob.powerbi_script.name,"-gatewayKey ${azurerm_data_factory_integration_runtime_self_hosted.shir[count.index].primary_authorization_key}"])}",
#           "storageAccountName": "${azurerm_storage_account.shir_storage.name}",
#           "storageAccountKey": "${azurerm_storage_account.shir_storage.primary_access_key}"
#       }
#   PROTECTED_SETTINGS

  

# }

