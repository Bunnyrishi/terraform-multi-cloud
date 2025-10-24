# Azure Infrastructure Configuration
# Equivalent resources to AWS PHD project

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

########################
# Azure Resource Group
########################
resource "azurerm_resource_group" "azure_main" {
  name     = "${var.project_name}-azure-rg"
  location = var.azure_location
  
  tags = {
    Environment = var.environment
    Cloud       = "Azure"
    Project     = var.project_name
  }
}

########################
# Azure Virtual Network
########################
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "${var.project_name}-azure-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  
  tags = {
    Environment = var.environment
    Cloud       = "Azure"
  }
}

resource "azurerm_subnet" "azure_public_subnet" {
  name                 = "${var.project_name}-azure-public-subnet"
  resource_group_name  = azurerm_resource_group.azure_main.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "azure_private_subnet" {
  name                 = "${var.project_name}-azure-private-subnet"
  resource_group_name  = azurerm_resource_group.azure_main.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = ["10.1.101.0/24"]
}

resource "azurerm_subnet" "azure_db_subnet" {
  name                 = "${var.project_name}-azure-db-subnet"
  resource_group_name  = azurerm_resource_group.azure_main.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = ["10.1.201.0/24"]
  
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

########################
# Azure Public IP & NAT Gateway
########################
resource "azurerm_public_ip" "azure_nat_pip" {
  name                = "${var.project_name}-azure-nat-pip"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_nat_gateway" "azure_nat" {
  name                = "${var.project_name}-azure-nat"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  sku_name            = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_nat_gateway_public_ip_association" "azure_nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.azure_nat.id
  public_ip_address_id = azurerm_public_ip.azure_nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "azure_private_nat_assoc" {
  subnet_id      = azurerm_subnet.azure_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.azure_nat.id
}

########################
# Azure Storage Account
########################
resource "azurerm_storage_account" "azure_app_storage" {
  name                     = "${replace(var.project_name, "-", "")}azureappstorage${random_id.azure_storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.azure_main.name
  location                 = azurerm_resource_group.azure_main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_storage_container" "azure_app_container" {
  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.azure_app_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "azure_backup_storage" {
  name                     = "${replace(var.project_name, "-", "")}azurebackupstorage${random_id.azure_storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.azure_main.name
  location                 = azurerm_resource_group.azure_main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  tags = {
    Environment = var.environment
  }
}

resource "random_id" "azure_storage_suffix" {
  byte_length = 4
}

########################
# Azure PostgreSQL Flexible Server
########################
resource "azurerm_private_dns_zone" "azure_postgres_dns" {
  name                = "${var.project_name}-azure-postgres.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.azure_main.name
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "azure_postgres_dns_link" {
  name                  = "${var.project_name}-azure-postgres-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.azure_postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.azure_vnet.id
  resource_group_name   = azurerm_resource_group.azure_main.name
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server" "azure_postgres" {
  name                   = "${var.project_name}-azure-postgres"
  resource_group_name    = azurerm_resource_group.azure_main.name
  location               = azurerm_resource_group.azure_main.location
  version                = "16"
  delegated_subnet_id    = azurerm_subnet.azure_db_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.azure_postgres_dns.id
  administrator_login    = "app_user"
  administrator_password = random_password.azure_db_password.result
  zone                   = "1"
  
  storage_mb = 32768
  
  sku_name = "B_Standard_B1ms"
  
  tags = {
    Environment = var.environment
  }
  
  depends_on = [azurerm_private_dns_zone_virtual_network_link.azure_postgres_dns_link]
}

resource "random_password" "azure_db_password" {
  length  = 20
  special = true
}

########################
# Azure Redis Cache
########################
resource "azurerm_redis_cache" "azure_redis" {
  name                = "${var.project_name}-azure-redis"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
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

########################
# Azure Network Security Groups
########################
resource "azurerm_network_security_group" "azure_web_nsg" {
  name                = "${var.project_name}-azure-web-nsg"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  
  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_group" "azure_app_nsg" {
  name                = "${var.project_name}-azure-app-nsg"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  
  security_rule {
    name                       = "AppPorts"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080-8084"]
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefix = "*"
  }
  
  tags = {
    Environment = var.environment
  }
}

########################
# Azure Virtual Machines
########################
resource "azurerm_public_ip" "azure_web_pip" {
  name                = "${var.project_name}-azure-web-pip"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface" "azure_web_nic" {
  name                = "${var.project_name}-azure-web-nic"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure_web_pip.id
  }
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface_security_group_association" "azure_web_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.azure_web_nic.id
  network_security_group_id = azurerm_network_security_group.azure_web_nsg.id
}

resource "azurerm_linux_virtual_machine" "azure_web_vm" {
  name                = "${var.project_name}-azure-web-vm"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  
  disable_password_authentication = true
  
  network_interface_ids = [
    azurerm_network_interface.azure_web_nic.id,
  ]
  
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Update with your SSH key path
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface" "azure_app_nic" {
  name                = "${var.project_name}-azure-app-nic"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface_security_group_association" "azure_app_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.azure_app_nic.id
  network_security_group_id = azurerm_network_security_group.azure_app_nsg.id
}

resource "azurerm_linux_virtual_machine" "azure_app_vm" {
  name                = "${var.project_name}-azure-app-vm"
  location            = azurerm_resource_group.azure_main.location
  resource_group_name = azurerm_resource_group.azure_main.name
  size                = "Standard_B4ms"
  admin_username      = "azureuser"
  
  disable_password_authentication = true
  
  network_interface_ids = [
    azurerm_network_interface.azure_app_nic.id,
  ]
  
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Update with your SSH key path
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = var.environment
  }
}