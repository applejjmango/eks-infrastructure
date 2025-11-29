# Input Variables - Placeholder file
# AWS Region
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "us-east-1"
}
# Environment Variable
variable "environment" {
  description = "Environment Variable used as a prefix"
  type        = string
  default     = "dev"
}
# Business Division
variable "business_divsion" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type        = string
  default     = "SAP"
}


variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's OIDC Provider"
  type        = string
}

variable "oidc_issuer" {
  description = "URL of the cluster's OIDC Issuer"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for external-dns"
  type        = string
  default     = "1.14.5"
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID to manage"
  type        = string
}

variable "domain_filter" {
  description = "Domain filter for ExternalDNS (e.g., 'example.com')"
  type        = string
}

variable "common_tags" {
  description = "Map of common tags"
  type        = map(string)
  default     = {}
}