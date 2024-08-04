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
