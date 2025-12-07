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
# Ingress 정보 (Map으로 변경)
# -----------------------------------------------------------------------------
output "ingress_resources" {
  description = "생성된 Ingress 리소스 정보 목록"
  value = {
    for k, v in module.alb_ssl_ingress : k => {
      name     = v.ingress_name
      hostname = v.ingress_hostname
    }
  }
}



# -----------------------------------------------------------------------------
# 외부/내부 앱 분류
# -----------------------------------------------------------------------------
output "external_apps" {
  description = "외부 노출 앱 목록 (Ingress 포함)"
  # ▼▼▼ [수정] Map 반복문으로 이름 추출 ▼▼▼
  value = [for name, config in var.microservices : name if config.expose_external]
}

output "internal_apps" {
  description = "내부용 앱 목록 (Ingress 미포함)"
  # ▼▼▼ [수정] Map 반복문으로 이름 추출 ▼▼▼
  value = [for name, config in var.microservices : name if !config.expose_external]
}

output "summary" {
  description = "배포 요약"
  value = {
    environment     = var.environment
    namespace       = var.namespace
    total_apps      = length(var.microservices)
    ingress_enabled = var.enable_ingress
    # ALB 주소는 하나만 나오면 되므로 (그룹핑되어서 같음) 첫 번째 것 출력 시도
    alb_dns_example = length(module.alb_ssl_ingress) > 0 ? values(module.alb_ssl_ingress)[0].ingress_hostname : "N/A"
  }
}