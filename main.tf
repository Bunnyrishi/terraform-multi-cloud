# Multi-Cloud Infrastructure Automation
# AWS and Azure deployment with Terraform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
}

# AWS Resources
module "aws_infrastructure" {
  source = "./modules/aws"
  
  environment = var.environment
  project_name = var.project_name
  aws_region = var.aws_region
}

# Azure Resources
module "azure_infrastructure" {
  source = "./modules/azure"
  
  environment = var.environment
  project_name = var.project_name
  azure_location = var.azure_location
}

# Outputs
output "aws_vpc_id" {
  value = module.aws_infrastructure.vpc_id
}

output "azure_vnet_id" {
  value = module.azure_infrastructure.vnet_id
}