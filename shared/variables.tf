# Multi-Cloud Infrastructure Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "multi-cloud-infra"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "azure_location" {
  description = "Azure location for resources"
  type        = string
  default     = "Central India"
}

variable "allowed_cidr" {
  description = "CIDR block allowed for SSH/RDP access"
  type        = string
  default     = "0.0.0.0/0" # Restrict this in production
}

# SSL certificate ARN for ALB (optional)
variable "ssl_certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN for ALB HTTPS listener. Leave empty for HTTP only."
}

# Optional domain and Route53 (if using ACM DNS validation)
variable "domain_name" {
  type        = string
  default     = ""
  description = "Domain name for ACM certificate validation (optional)"
}

variable "route53_zone_id" {
  type        = string
  default     = ""
  description = "Route53 hosted zone ID (optional, needed for ACM DNS validation)"
}

# Cloud provider selection
variable "deploy_aws" {
  description = "Deploy AWS infrastructure"
  type        = bool
  default     = true
}

variable "deploy_azure" {
  description = "Deploy Azure infrastructure"
  type        = bool
  default     = true
}

# List of all lambdas
locals {
  lambda_names = [
    "irn-reports",
    "ewb-reports",
    "irn-pull-v1",
    "irn-ewbbyirn-v1",
    "irn-push-v1",
    "irn-email-v1",
    "irn-cancel-v1",
    "irn-demo-raw",
    "irn-demo-process"
  ]
}