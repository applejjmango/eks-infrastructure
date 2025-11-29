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

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller"
  type        = string
  default     = "1.7.1"
}

variable "common_tags" {
  description = "Map of common tags"
  type        = map(string)
  default     = {}
}