# Include network configuration
# Ensure network.tf file defines outputs like vnet_id, web_subnet_id, and db_subnet_id
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

# Define Network Resources
# Create a Virtual Network with specified address space
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create a subnet for the web tier
resource "azurerm_subnet" "web" {
  name                 = "web-tier-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a subnet for the database tier
resource "azurerm_subnet" "database" {
  name                 = "database-tier-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group for the web tier
resource "azurerm_network_security_group" "web" {
  name                = "web-tier-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Allow HTTP and HTTPS traffic
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 80
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for the database tier
resource "azurerm_network_security_group" "database" {
  name                = "database-tier-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Allow SQL traffic from the web tier subnet
  security_rule {
    name                       = "Allow-SQL"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 1433
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# resource "azurerm_virtual_network" "example" {
#   name                = "example-network"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   address_space       = ["10.254.0.0/16"]
# }

# resource "azurerm_subnet" "example" {
#   name                 = "example"
#   resource_group_name  = azurerm_resource_group.example.name
#   virtual_network_name = azurerm_virtual_network.example.name
#   address_prefixes     = ["10.254.0.0/24"]
# }

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
}
# Include Virtual Machines configuration
# Ensure vm.tf file defines the VMs and outputs like web_nic_ids
# Create an Availability Set for the web tier VMs
resource "azurerm_availability_set" "web" {
  name                = "web-tier-avset"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  }

# Define the web tier VMs
resource "azurerm_virtual_machine" "web" {
  count               = 2
  name                = "web-vm-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  vm_size             = "Standard_D2s_v3"
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
    admin_password = "GreenGoblin!!"
  }
  os_profile_windows_config {}
}

resource "azurerm_virtual_machine" "database" {
  name                = "database-vm"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  vm_size             = "Standard_D4s_v3"
  network_interface_ids = [azurerm_network_interface.database.id]
  
  # OS Disk configuration
  storage_os_disk {
    name              = "database-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 256
  }

  # OS Profile
  os_profile {
    computer_name  = "database-vm"
    admin_username = "adminuser"
    admin_password = "GreenGoblin!!"
  }
  os_profile_windows_config {}
}

 # Network Interface for Web VMs

resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "web-nic-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface for Database VM
resource "azurerm_network_interface" "database" {
  name                = "database-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.database.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Include Load Balancer configuration
# Ensure loadbalancer.tf file defines Load Balancer resources
# Define a Public IP for the Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "example-lb-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

# Define the Load Balancer
resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  # Frontend IP configuration
  frontend_ip_configuration {
    name                 = "example-fe-ip"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
  
  }

  # Backend address pool
  resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-backend-pool"
}
  
  # Health probe for the Load Balancer
  resource "azurerm_lb_probe" "example"{
    loadbalancer_id = azurerm_lb.example.id
    name                = "http-probe"
    protocol            = "Http"
    port                = 80
    request_path        = "/"
    interval_in_seconds = 15
    number_of_probes    = 2
  }

  # Load balancing rule
  resource "azurerm_lb_rule" "my_lb_rule" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                 = 80
  backend_port                  = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "example-fe-ip"
  enable_floating_ip            = false
  load_distribution             = "Default"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example.id
  }
  


# Include Application Gateway configuration
# Ensure appgateway.tf file defines Application Gateway resources
# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.example.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.example.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.example.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.example.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.example.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.example.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.example.name}-rdrcfg"
}

resource "azurerm_application_gateway" "example" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.web.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

# Frontend IP configuration
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

# Backend address pool
  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

# Include SQL Server and Database configuration
# Ensure sqlserver.tf and sqldatabase.tf files define SQL Server and SQL Database resources
# Create an Azure SQL Server
resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login = "sqladmin"
  administrator_login_password = "GreenGoblin!!"

  tags = {
    environment = "production"
  }
}

# Create an Azure SQL Database
resource "azurerm_sql_database" "example" {
  name                = "example-database"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Standard"
  
  # Allow Azure services to access the server
 lifecycle {
    prevent_destroy = true
  }

  tags = {
    environment = "production"
  }
}
