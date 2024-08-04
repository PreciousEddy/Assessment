# Create an Availability Set for the web tier VMs
resource "azurerm_availability_set" "web" {
  name                = "web-tier-avset"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  }

# Define the web tier VMs
resource "azurerm_virtual_machine" "web" {
  count               = "2"
  name                = "web-vm-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  vm_size                = "Standard_D2s_v3"
  network_interface_ids = [azurerm_network_interface.web[count.index].id]
  availability_set_id = azurerm_availability_set.web.id

  # OS Disk configuration
  storage_os_disk {
    name              = "web-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"    
    disk_size_gb      = 128
  }

  # OS Profile
  os_profile {
    computer_name  = "web-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = var.admin_password
  }
  os_profile_windows_config {}
}

# Define the database tier VM
resource "azurerm_virtual_machine" "database" {
  name                = "database-vm"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  vm_size                = "Standard_D4s_v3"
  network_interface_ids = [azurerm_network_interface.database.id]
  
  # OS Disk configuration
  storage_os_disk {
    name              = "database-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb = 256
  }

  # OS Profile
  os_profile {
    computer_name  = "database-vm"
    admin_username = "adminuser"
    admin_password = var.admin_password
  }
  os_profile_windows_config {}
}
