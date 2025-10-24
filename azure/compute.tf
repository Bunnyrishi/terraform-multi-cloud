# Azure Virtual Machines

# Web Server Public IP
resource "azurerm_public_ip" "web_pip" {
  name                = "${var.project_name}-azure-web-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

# Web Server Network Interface
resource "azurerm_network_interface" "web_nic" {
  name                = "${var.project_name}-azure-web-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_pip.id
  }
  
  tags = {
    Environment = var.environment
  }
}

# Web Server NSG Association
resource "azurerm_network_interface_security_group_association" "web_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.web_nic.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# Web Server Virtual Machine
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "${var.project_name}-azure-web-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  
  disable_password_authentication = true
  
  network_interface_ids = [
    azurerm_network_interface.web_nic.id,
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

# Application Server Network Interface
resource "azurerm_network_interface" "app_nic" {
  name                = "${var.project_name}-azure-app-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = {
    Environment = var.environment
  }
}

# Application Server NSG Association
resource "azurerm_network_interface_security_group_association" "app_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.app_nic.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Application Server Virtual Machine
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "${var.project_name}-azure-app-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B4ms"
  admin_username      = "azureuser"
  
  disable_password_authentication = true
  
  network_interface_ids = [
    azurerm_network_interface.app_nic.id,
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