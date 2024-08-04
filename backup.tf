# Define an Azure Backup Vault
resource "azurerm_backup_vault" "example" {
  name                = "example-backup-vault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
}

# Define a backup policy for VMs
resource "azurerm_backup_policy_vm" "example" {
  name                = "example-backup-policy"
  resource_group_name = azurerm_resource_group.example.name
  recovery_vault_name = azurerm_backup_vault.example.name

timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
    
  }
retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 42
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 7
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 77
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}

# Protect the web tier VMs with the backup policy
resource "azurerm_backup_protected_vm" "example" {
  #name                = "example-backup-protected-vm"
  resource_group_name = azurerm_resource_group.example.name
  recovery_vault_name = azurerm_backup_vault.example.name
  backup_policy_id    = azurerm_backup_policy_vm.example.id
  source_vm_id        = data.azurerm_virtual_machine.web[0].id
}
