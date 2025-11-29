# ============================================
# EKS Cluster Outputs
# ============================================
output "cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks_cluster.cluster_id
}

output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version for the cluster"
  value       = module.eks_cluster.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

# ============================================
# OIDC Provider Outputs
# ============================================
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  value       = module.eks_cluster.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC provider URL (without https://)"
  value       = module.eks_cluster.oidc_provider
}

# ============================================
# Node Group Outputs
# ============================================
output "node_group_id" {
  description = "EKS Node Group ID"
  value       = module.eks_cluster.node_group_id
}

output "node_group_arn" {
  description = "EKS Node Group ARN"
  value       = module.eks_cluster.node_group_arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = module.eks_cluster.node_group_status
}

# ============================================
# IAM Role Outputs
# ============================================
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks_cluster.cluster_iam_role_arn
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = module.eks_cluster.node_group_iam_role_arn
}

# ============================================
# Bastion Host Outputs
# ============================================
output "bastion_instance_id" {
  description = "Bastion Host instance ID"
  value       = var.enable_bastion ? module.bastion[0].instance_id : null
}

output "bastion_public_ip" {
  description = "Bastion Host Elastic IP"
  value       = var.enable_bastion ? module.bastion[0].public_ip : null
}

output "bastion_security_group_id" {
  description = "Bastion Host security group ID"
  value       = var.enable_bastion ? module.bastion[0].security_group_id : null
}