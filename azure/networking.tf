# Azure Virtual Network and Networking Resources

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-azure-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Environment = var.environment
    Cloud       = "Azure"
  }
}

# Public Subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = "${var.project_name}-azure-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Private Subnet
resource "azurerm_subnet" "private_subnet" {
  name                 = "${var.project_name}-azure-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.101.0/24"]
}

# Database Subnet
resource "azurerm_subnet" "db_subnet" {
  name                 = "${var.project_name}-azure-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
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

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_pip" {
  name                = "${var.project_name}-azure-nat-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "nat" {
  name                = "${var.project_name}-azure-nat"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

# NAT Gateway Public IP Association
resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

# NAT Gateway Subnet Association
resource "azurerm_subnet_nat_gateway_association" "private_nat_assoc" {
  subnet_id      = azurerm_subnet.private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}