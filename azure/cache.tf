# Azure Redis Cache Resources

# Redis Cache
resource "azurerm_redis_cache" "redis" {
  name                = "${var.project_name}-azure-redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  
  redis_configuration {
  }
  
  tags = {
    Environment = var.environment
  }
}