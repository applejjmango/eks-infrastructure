# =============================================================================
# App Tier - Outputs
# =============================================================================
# 실무: 운영팀/개발팀이 확인할 정보
# =============================================================================

# -----------------------------------------------------------------------------
# 앱 정보
# -----------------------------------------------------------------------------
output "app_deployments" {
  description = "배포된 Deployment 목록"
  value       = { for k, v in module.apps : k => v.deployment_name }
}

output "app_services" {
  description = "배포된 Service 목록"
  value = {
    for k, v in module.apps : k => {
      name = v.service_name
      type = v.service_type
      dns  = v.service_dns
    }
  }
}

# -----------------------------------------------------------------------------
# Ingress 정보 (활성화된 경우만)
# -----------------------------------------------------------------------------
output "ingress_enabled" {
  description = "Ingress 활성화 여부"
  value       = var.enable_ingress && length(local.external_apps) > 0
}

output "ingress_name" {
  description = "Ingress 이름"
  value       = var.enable_ingress && length(local.external_apps) > 0 ? module.alb_ssl_ingress[0].ingress_name : null
}

output "alb_dns_name" {
  description = "ALB DNS 이름 (Route53 Alias 대상)"
  value       = var.enable_ingress && length(local.external_apps) > 0 ? module.alb_ssl_ingress[0].ingress_hostname : null
}

# -----------------------------------------------------------------------------
# ACM 인증서 정보
# -----------------------------------------------------------------------------
output "acm_certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = var.enable_ingress && length(local.external_apps) > 0 ? module.alb_ssl_ingress[0].acm_certificate_arn : null
}

output "acm_certificate_status" {
  description = "ACM 인증서 상태 (ISSUED 확인 필요)"
  value       = var.enable_ingress && length(local.external_apps) > 0 ? module.alb_ssl_ingress[0].acm_certificate_status : null
}

output "acm_validation_options" {
  description = "DNS 검증용 CNAME 레코드 정보"
  value       = var.enable_ingress && length(local.external_apps) > 0 ? module.alb_ssl_ingress[0].acm_domain_validation_options : null
}

# -----------------------------------------------------------------------------
# 외부/내부 앱 분류
# -----------------------------------------------------------------------------
output "external_apps" {
  description = "외부 노출 앱 목록 (Ingress 포함)"
  value       = [for app in var.apps : app.name if app.expose_external]
}

output "internal_apps" {
  description = "내부용 앱 목록 (Ingress 미포함)"
  value       = [for app in var.apps : app.name if !app.expose_external]
}

# -----------------------------------------------------------------------------
# 검증 명령어
# -----------------------------------------------------------------------------
output "verification_commands" {
  description = "배포 검증을 위한 kubectl 명령어"
  value       = <<-EOT
    
    # ========================================
    # 리소스 확인
    # ========================================
    
    # Deployment 확인
    kubectl get deployments -n ${var.namespace}
    
    # Pod 확인
    kubectl get pods -n ${var.namespace}
    
    # Service 확인
    kubectl get svc -n ${var.namespace}
    
    # Ingress 확인
    kubectl get ingress -n ${var.namespace}
    kubectl describe ingress ${var.ingress_name} -n ${var.namespace}
    
    # ========================================
    # 접속 테스트 (ALB DNS)
    # ========================================
    %{if var.enable_ingress && length(local.external_apps) > 0~}
    # HTTP 테스트 (HTTPS로 리다이렉트됨)
    %{for app in local.external_apps~}
    curl -v http://${module.alb_ssl_ingress[0].ingress_hostname}${app.ingress_path}/
    %{endfor~}
    
    # HTTPS 테스트 (Route53 도메인 설정 후)
    # curl -v https://your-domain.com/app1/index.html
    %{endif~}
    
    # ========================================
    # 내부 서비스 테스트 (클러스터 내부)
    # ========================================
    # kubectl run -it --rm debug --image=curlimages/curl -- sh
    # curl http://<service-name>.<namespace>.svc.cluster.local/
    
  EOT
}

# -----------------------------------------------------------------------------
# 요약 정보
# -----------------------------------------------------------------------------
output "summary" {
  description = "배포 요약"
  value = {
    environment     = var.environment
    namespace       = var.namespace
    total_apps      = length(var.apps)
    external_apps   = length([for app in var.apps : app if app.expose_external])
    internal_apps   = length([for app in var.apps : app if !app.expose_external])
    ingress_enabled = var.enable_ingress
    alb_dns         = var.enable_ingress && length(local.external_apps) > 0 ? module.alb_ssl_ingress[0].ingress_hostname : "N/A"
  }
}