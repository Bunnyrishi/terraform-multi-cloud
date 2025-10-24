# Azure PostgreSQL Database Resources

# Random password for database
resource "random_password" "db_password" {
  length  = 20
  special = true
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "${var.project_name}-azure-postgres.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Environment = var.environment
  }
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "${var.project_name}-azure-postgres-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.main.name
  
  tags = {
    Environment = var.environment
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "${var.project_name}-azure-postgres"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  delegated_subnet_id    = azurerm_subnet.db_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id
  administrator_login    = "app_user"
  administrator_password = random_password.db_password.result
  zone                   = "1"
  
  storage_mb = 32768
  
  sku_name = "B_Standard_B1ms"
  
  tags = {
    Environment = var.environment
  }
  
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_link]
}