output "irsa_role_arn" {
  description = "The ARN of the IAM role for the ALB Controller"
  value       = aws_iam_role.alb_controller.arn
}