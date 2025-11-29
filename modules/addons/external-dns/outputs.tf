output "irsa_role_arn" {
  description = "The ARN of the IAM role for the ExternalDNS"
  value       = aws_iam_role.external_dns.arn
}