output "node_group_id" {
  description = "The ID of the EKS Node Group"
  value       = aws_eks_node_group.main.id
}

output "node_role_arn" {
  description = "The ARN of the Node IAM Role (for aws-auth ConfigMap)"
  value       = aws_iam_role.eks_node.arn
}