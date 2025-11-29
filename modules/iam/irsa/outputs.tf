# ============================================
# IRSA Module Outputs
# ============================================

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.this.arn
}

output "service_account_name" {
  description = "Name of the Kubernetes Service Account"
  value       = var.create_service_account ? kubernetes_service_account_v1.this[0].metadata[0].name : var.service_account_name
}

output "service_account_namespace" {
  description = "Namespace of the Service Account"
  value       = var.namespace
}