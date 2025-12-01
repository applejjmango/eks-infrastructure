# ============================================
# EKS Cluster Module Outputs
# ============================================

# ============================================
# Cluster
# ============================================
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = aws_eks_cluster.cluster.version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.cluster.platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# ============================================
# OIDC Provider
# ============================================
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider" {
  description = "OIDC provider URL without https://"
  value       = local.oidc_provider
}

# ============================================
# IAM Roles
# ============================================
output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS node group"
  value       = aws_iam_role.node_group.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group.arn
}

# ============================================
# Node Group Outputs - PUBLIC
# ============================================
output "public_node_group_id" {
  description = "Public Node Group ID"
  value       = var.enable_public_node_group ? aws_eks_node_group.public[0].id : null
}

output "public_node_group_arn" {
  description = "Public Node Group ARN"
  value       = var.enable_public_node_group ? aws_eks_node_group.public[0].arn : null
}

output "public_node_group_status" {
  description = "Public Node Group status"
  value       = var.enable_public_node_group ? aws_eks_node_group.public[0].status : null
}

output "public_node_group_version" {
  description = "Public Node Group Kubernetes version"
  value       = var.enable_public_node_group ? aws_eks_node_group.public[0].version : null
}

# ============================================
# Node Group Outputs - PRIVATE
# ============================================
output "private_node_group_id" {
  description = "Private Node Group ID"
  value       = var.enable_private_node_group ? aws_eks_node_group.private[0].id : null
}

output "private_node_group_arn" {
  description = "Private Node Group ARN"
  value       = var.enable_private_node_group ? aws_eks_node_group.private[0].arn : null
}

output "private_node_group_status" {
  description = "Private Node Group status"
  value       = var.enable_private_node_group ? aws_eks_node_group.private[0].status : null
}

output "private_node_group_version" {
  description = "Private Node Group Kubernetes version"
  value       = var.enable_private_node_group ? aws_eks_node_group.private[0].version : null
}

# ============================================
# Unified Output (Backward Compatibility)
# ============================================
output "node_group_id" {
  description = "Active Node Group ID (private preferred)"
  value = var.enable_private_node_group ? (
    aws_eks_node_group.private[0].id
    ) : (
    var.enable_public_node_group ? aws_eks_node_group.public[0].id : null
  )
}

output "node_group_arn" {
  description = "Active Node Group ARN"
  value = var.enable_private_node_group ? (
    aws_eks_node_group.private[0].arn
    ) : (
    var.enable_public_node_group ? aws_eks_node_group.public[0].arn : null
  )
}

output "node_group_status" {
  description = "Active Node Group status"
  value = var.enable_private_node_group ? (
    aws_eks_node_group.private[0].status
    ) : (
    var.enable_public_node_group ? aws_eks_node_group.public[0].status : null
  )
}

# ============================================
# CloudWatch Logs
# ============================================
output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch Log Group for cluster"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cluster.arn
}