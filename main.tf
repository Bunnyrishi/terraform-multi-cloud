# Multi-Cloud Infrastructure Deployment
# Supports both AWS and Azure based on cloud_provider variable

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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Conditional AWS Provider
provider "aws" {
  count  = var.cloud_provider == "aws" || var.cloud_provider == "both" ? 1 : 0
  region = var.aws_region
}

# Conditional Azure Provider
provider "azurerm" {
  count = var.cloud_provider == "azure" || var.cloud_provider == "both" ? 1 : 0
  features {}
}

# AWS Infrastructure Module
module "aws_infrastructure" {
  count  = var.cloud_provider == "aws" || var.cloud_provider == "both" ? 1 : 0
  source = "./aws"
  
  # Pass variables to module
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

# Azure Infrastructure Module
module "azure_infrastructure" {
  count  = var.cloud_provider == "azure" || var.cloud_provider == "both" ? 1 : 0
  source = "./azure"
  
  # Pass variables to module
  project_name   = var.project_name
  environment    = var.environment
  azure_location = var.azure_location
}