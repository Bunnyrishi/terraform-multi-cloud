variable "region" {
  type    = string
  default = "ap-south-1" # Mumbai
}

variable "allowed_cidr" {
  type    = string
  default = "203.0.113.0/32" # replace with your office IP
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