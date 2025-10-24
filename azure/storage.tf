# Azure Storage Resources

# Random ID for storage account names
resource "random_id" "storage_suffix" {
  byte_length = 4
}

# Application Storage Account
resource "azurerm_storage_account" "app_storage" {
  name                     = "${replace(var.project_name, "-", "")}azureappstorage${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = var.environment
    Type        = "Application"
  }
}

# Application Storage Container
resource "azurerm_storage_container" "app_container" {
  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.app_storage.name
  container_access_type = "private"
}

# Backup Storage Account
resource "azurerm_storage_account" "backup_storage" {
  name                     = "${replace(var.project_name, "-", "")}azurebackupstorage${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  tags = {
    Environment = var.environment
    Type        = "Backup"
  }
}