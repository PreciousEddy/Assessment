Here’s a detailed README for your Terraform project that covers all aspects from setup to execution and troubleshooting:

---

# Azure Infrastructure Provisioning with Terraform

## Overview

This Terraform project provisions a comprehensive Azure infrastructure including:

- **Resource Group**
- **Virtual Network (VNet)**
- **Subnets (Web Tier & Database Tier)**
- **Network Security Groups (NSGs)**
- **Network Interfaces**
- **Virtual Machines (VMs) for Web and Database Tiers**
- **Load Balancer**
- **Application Gateway**
- **Azure SQL Server and Database**

This setup ensures a scalable, secure, and highly available environment for deploying applications.

## Project Structure

1. **`main.tf`** - Defines core Azure resources such as VNet, Subnets, NSGs, VMs, Load Balancer, Application Gateway, and SQL resources.
2. **`network.tf`** - Manages the network configuration including VNet, Subnets, and Network Security Groups.
3. **`vm.tf`** - Configures Virtual Machines and their Network Interfaces.
4. **`loadbalancer.tf`** - Sets up the Azure Load Balancer.
5. **`appgateway.tf`** - Configures the Azure Application Gateway.
6. **`sqlserver.tf`** - Defines the Azure SQL Server.
7. **`sqldatabase.tf`** - Configures the Azure SQL Database.

## Prerequisites

- **Terraform**: Ensure Terraform is installed. [Download Terraform](https://www.terraform.io/downloads).
- **Azure Account**: An Azure subscription is required. [Create an Azure account](https://azure.microsoft.com/en-us/free/).
- **Azure CLI**: Install Azure CLI and authenticate. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

## Configuration

### Variables

Ensure to define necessary variables in a `terraform.tfvars` file or directly in your Terraform configuration. Examples include:

```hcl
admin_password = "your_admin_password"
```

### Provider Configuration

The provider configuration is included in `main.tf`. Ensure the Azure provider is set up correctly.

```hcl
provider "azurerm" {
  features {}
}
```

## Resources Defined

### Resource Group

Defines the Azure resource group in which all resources will be created.

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}
```

### Network Configuration

- **Virtual Network**: Provides a secure, isolated network.
- **Subnets**: Separates the network into web and database tiers.
- **Network Security Groups**: Defines rules to control traffic flow.

```hcl
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "web" {
  name                 = "web-tier-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "web" {
  name                = "web-tier-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

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
```

### Virtual Machines

Configures VMs for both web and database tiers, ensuring availability and scaling.

```hcl
resource "azurerm_virtual_machine" "web" {
  count               = 2
  name                = "web-vm-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  vm_size             = "Standard_D2s_v3"
  network_interface_ids = [azurerm_network_interface.web[count.index].id]
  availability_set_id = azurerm_availability_set.web.id

  storage_os_disk {
    name              = "web-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"    
    disk_size_gb      = 128
  }

  os_profile {
    computer_name  = "web-vm-${count.index}"
    admin_username = "adminuser"
    admin_password = var.admin_password
  }
  os_profile_windows_config {}
}
```

### Load Balancer

Distributes traffic across VMs for high availability.

```hcl
resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "example-fe-ip"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_rule" "my_lb_rule" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "example-fe-ip"
  enable_floating_ip             = false
  load_distribution              = "Default"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example.id
}
```

### Application Gateway

Provides advanced routing and load balancing.

```hcl
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

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

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
```

### SQL Server and Database

Sets up Azure SQL Server and Database for backend data storage.

```hcl
resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login = "sqladmin"
  administrator_login_password = "GreenGoblin!!"
}

resource "azurerm_sql_database" "example" {
  name                = "example-database"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Standard"
  
  lifecycle {
    prevent_destroy = true
  }
}
```

## Deployment

1. **Initialize Terraform**: Run `terraform init` to initialize the working directory.
2. **Plan Deployment**: Run `terraform plan` to preview the changes Terraform will make.
3. **Apply Configuration**: Run `terraform apply` to apply the configuration and provision resources.
4. **Destroy Resources**: If needed, run `terraform destroy` to remove all resources created by this configuration.

## Troubleshooting

- **Resource Not Found**: Ensure all resources are declared and correctly referenced.
- **Authentication Issues**: Verify Azure CLI is authenticated and has the necessary permissions.
- **Invalid Configuration**: Check for syntax errors or missing parameters in your `.tf` files.

```markdown
## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Resource Manager Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/)
- [Azure Load Balancer Documentation](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [Azure Application Gateway Documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/sql-database/)

## Contributing

Contributions to this project are welcome. Please follow these steps to contribute:

1. **Fork the Repository**: Click the "Fork" button on GitHub.
2. **Create a Branch**: Create a new branch for your changes.
3. **Make Changes**: Implement your changes or enhancements.
4. **Commit Changes**: Commit your changes with descriptive messages.
5. **Push to Fork**: Push your changes to your forked repository.
6. **Create a Pull Request**: Open a pull request to the original repository for review.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or further assistance, please contact Bryan at bryan@example.com.

---

This README provides a comprehensive guide to understanding, configuring, and managing your Terraform-based Azure infrastructure project. If you have any specific requests or need additional sections, feel free to ask!
```

Feel free to adjust the specifics to match your exact configuration or preferences!
