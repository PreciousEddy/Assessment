# Define a Public IP for the Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "example-lb-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

# Define the Load Balancer
resource "azurerm_load_balancer" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  # Frontend IP configuration
  frontend_ip_configuration {
    name                 = "example-fe-ip"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  # Backend address pool
  backend_address_pool {
    name = "example-backend-pool"
  }

  # Health probe for the Load Balancer
  probe {
    name                = "http-probe"
    protocol            = "Http"
    port                = 80
    request_path        = "/"
    interval_in_seconds = 15
    number_of_probes    = 2
  }

  # Load balancing rule
  load_balancing_rule {
    name                           = "http-rule"
    protocol                       = "Tcp"
    frontend_port                 = 80
    backend_port                  = 80
    enable_floating_ip            = false
    load_distribution             = "Default"
    backend_address_pool_id      = azurerm_load_balancer.example.backend_address_pool[0].id
    probe_id                      = azurerm_load_balancer.example.probe[0].id
  }
}
