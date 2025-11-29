# ============================================
# IRSA Module Variables (Common)
# 모든 IRSA 사용 케이스에서 재사용
# ============================================

variable "name" {
  description = "Name of the service using IRSA"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL (without https://)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Kubernetes Service Account name"
  type        = string
}

variable "iam_policy_statements" {
  description = "IAM policy statements for the role"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
}

variable "create_service_account" {
  description = "Create Kubernetes Service Account"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for IAM resources"
  type        = map(string)
  default     = {}
}