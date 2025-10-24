# Azure Main Configuration
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

# Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-azure-rg"
  location = var.azure_location
  
  tags = {
    Environment = var.environment
    Cloud       = "Azure"
    Project     = var.project_name
  }
}