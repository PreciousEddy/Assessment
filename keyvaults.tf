# Key Vault Resource
resource "azurerm_key_vault" "example" {
  name                = "example-keyvault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name             = "standard"
  tenant_id            = data.azurerm_client_config.example.tenant_id
  access_policy {
    tenant_id = data.azurerm_client_config.example.tenant_id
    object_id  = data.azurerm_client_config.example.object_id
    secret_permissions = [
      "get",
      "list"
    ]
  }
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = "your-db-password"
  key_vault_id = azurerm_key_vault.example.id
}

# Access Key Vault Secrets
data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = azurerm_key_vault.example.id
}

# VM Configuration with Key Vault Secret
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
    admin_password = data.azurerm_key_vault_secret.db_password.value
  }
  os_profile_windows_config {}
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "sql_admin_username" {
  name         = "sql-admin-username"
  value        = "your-sql-admin-username"
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = "your-sql-admin-password"
  key_vault_id = azurerm_key_vault.example.id
}

# Access Key Vault Secrets
data "azurerm_key_vault_secret" "sql_admin_username" {
  name         = "sql-admin-username"
  key_vault_id = azurerm_key_vault.example.id
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = azurerm_key_vault.example.id
}

# SQL Server
resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login = data.azurerm_key_vault_secret.sql_admin_username.value
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value

  tags = {
    environment = "production"
  }
}

# SQL Database
resource "azurerm_sql_database" "example" {
  name                = "example-database"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Standard"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    environment = "production"
  }
}

# Allow access from Azure services
resource "azurerm_sql_server_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}