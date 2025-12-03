# =============================================================================
# ALB SSL Ingress 모듈 - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# ACM 인증서 출력
# -----------------------------------------------------------------------------
output "acm_certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = var.create_acm_certificate ? aws_acm_certificate.this[0].arn : var.acm_certificate_arn
}

output "acm_certificate_status" {
  description = "ACM 인증서 상태"
  value       = var.create_acm_certificate ? aws_acm_certificate.this[0].status : "EXISTING"
}

output "acm_domain_validation_options" {
  description = "DNS 검증용 CNAME 레코드 정보"
  value       = var.create_acm_certificate ? aws_acm_certificate.this[0].domain_validation_options : null
}

# -----------------------------------------------------------------------------
# Ingress 출력
# -----------------------------------------------------------------------------
output "ingress_name" {
  description = "Ingress 이름"
  value       = kubernetes_ingress_v1.this.metadata[0].name
}

output "ingress_hostname" {
  description = "ALB DNS 이름"
  value       = try(kubernetes_ingress_v1.this.status[0].load_balancer[0].ingress[0].hostname, "pending")
}

output "load_balancer_name" {
  description = "ALB 이름"
  value       = var.load_balancer_name
}