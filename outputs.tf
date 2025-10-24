# Multi-Cloud Infrastructure Outputs

########################
# AWS Outputs
########################
output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = var.deploy_aws ? aws_vpc.aws_main[0].id : null
}

output "aws_public_subnets" {
  description = "AWS Public Subnet IDs"
  value = var.deploy_aws ? [
    aws_subnet.aws_public_a[0].id,
    aws_subnet.aws_public_b[0].id
  ] : []
}

output "aws_private_subnets" {
  description = "AWS Private Subnet IDs"
  value = var.deploy_aws ? [
    aws_subnet.aws_private_a[0].id,
    aws_subnet.aws_private_b[0].id
  ] : []
}

output "aws_rds_endpoint" {
  description = "AWS RDS PostgreSQL endpoint"
  value       = var.deploy_aws ? aws_db_instance.aws_postgres[0].address : null
  sensitive   = true
}

output "aws_redis_endpoint" {
  description = "AWS Redis endpoint"
  value       = var.deploy_aws ? aws_elasticache_cluster.aws_redis[0].cache_nodes[0].address : null
}

output "aws_s3_buckets" {
  description = "AWS S3 bucket names"
  value = var.deploy_aws ? {
    app_storage    = aws_s3_bucket.aws_app_storage[0].bucket
    backup_storage = aws_s3_bucket.aws_backup_storage[0].bucket
  } : {}
}

output "aws_web_server_ip" {
  description = "AWS Web Server Public IP"
  value       = var.deploy_aws ? aws_instance.aws_web_server[0].public_ip : null
}

output "aws_app_server_ip" {
  description = "AWS App Server Private IP"
  value       = var.deploy_aws ? aws_instance.aws_app_server[0].private_ip : null
}

########################
# Azure Outputs
########################
output "azure_resource_group_name" {
  description = "Azure Resource Group name"
  value       = var.deploy_azure ? azurerm_resource_group.azure_main[0].name : null
}

output "azure_vnet_id" {
  description = "Azure Virtual Network ID"
  value       = var.deploy_azure ? azurerm_virtual_network.azure_vnet[0].id : null
}

output "azure_public_subnet_id" {
  description = "Azure Public Subnet ID"
  value       = var.deploy_azure ? azurerm_subnet.azure_public_subnet[0].id : null
}

output "azure_private_subnet_id" {
  description = "Azure Private Subnet ID"
  value       = var.deploy_azure ? azurerm_subnet.azure_private_subnet[0].id : null
}

output "azure_postgres_fqdn" {
  description = "Azure PostgreSQL FQDN"
  value       = var.deploy_azure ? azurerm_postgresql_flexible_server.azure_postgres[0].fqdn : null
  sensitive   = true
}

output "azure_redis_hostname" {
  description = "Azure Redis hostname"
  value       = var.deploy_azure ? azurerm_redis_cache.azure_redis[0].hostname : null
}

output "azure_storage_accounts" {
  description = "Azure Storage Account names"
  value = var.deploy_azure ? {
    app_storage    = azurerm_storage_account.azure_app_storage[0].name
    backup_storage = azurerm_storage_account.azure_backup_storage[0].name
  } : {}
}

output "azure_web_vm_ip" {
  description = "Azure Web VM Public IP"
  value       = var.deploy_azure ? azurerm_public_ip.azure_web_pip[0].ip_address : null
}

output "azure_app_vm_ip" {
  description = "Azure App VM Private IP"
  value       = var.deploy_azure ? azurerm_network_interface.azure_app_nic[0].private_ip_address : null
}

########################
# Multi-Cloud Summary
########################
output "infrastructure_summary" {
  description = "Multi-cloud infrastructure summary"
  value = {
    aws_deployed   = var.deploy_aws
    azure_deployed = var.deploy_azure
    project_name   = var.project_name
    environment    = var.environment
    aws_region     = var.aws_region
    azure_location = var.azure_location
  }
}

output "database_endpoints" {
  description = "Database endpoints across clouds"
  value = {
    aws_postgres   = var.deploy_aws ? aws_db_instance.aws_postgres[0].address : null
    azure_postgres = var.deploy_azure ? azurerm_postgresql_flexible_server.azure_postgres[0].fqdn : null
  }
  sensitive = true
}

output "cache_endpoints" {
  description = "Cache endpoints across clouds"
  value = {
    aws_redis   = var.deploy_aws ? aws_elasticache_cluster.aws_redis[0].cache_nodes[0].address : null
    azure_redis = var.deploy_azure ? azurerm_redis_cache.azure_redis[0].hostname : null
  }
}

output "storage_resources" {
  description = "Storage resources across clouds"
  value = {
    aws_s3_buckets = var.deploy_aws ? {
      app_storage    = aws_s3_bucket.aws_app_storage[0].bucket
      backup_storage = aws_s3_bucket.aws_backup_storage[0].bucket
    } : {}
    azure_storage_accounts = var.deploy_azure ? {
      app_storage    = azurerm_storage_account.azure_app_storage[0].name
      backup_storage = azurerm_storage_account.azure_backup_storage[0].name
    } : {}
  }
}