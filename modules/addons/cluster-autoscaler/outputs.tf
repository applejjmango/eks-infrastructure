output "irsa_role_arn" {
  description = "The ARN of the IAM role for the Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}