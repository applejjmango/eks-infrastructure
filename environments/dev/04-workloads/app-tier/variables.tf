# ============================================
# General Variables
# ============================================
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "playdevops"
}
variable "namespace" {
  description = "Kubernetes 네임스페이스"
  type        = string
  default     = "default"
}
# -----------------------------------------------------------------------------
# Ingress 활성화 여부
# 실무: 모든 앱이 외부 노출이 필요한 것은 아님
# -----------------------------------------------------------------------------
variable "enable_ingress" {
  description = "ALB Ingress 생성 여부"
  type        = bool
  default     = true
}

variable "ingress_hostnames" {
  description = "Ingress에 연결할 호스트네임 목록"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# ACM/SSL 설정
# -----------------------------------------------------------------------------
variable "acm_domain_name" {
  description = "ACM 인증서 도메인 (예: *.example.com)"
  type        = string
  default     = null # Ingress 비활성화 시 null 가능
}

variable "create_acm_certificate" {
  description = "새 ACM 인증서 생성 여부 (false면 기존 인증서 사용)"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "기존 ACM 인증서 ARN (create_acm_certificate=false 시 필수)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Ingress 설정
# -----------------------------------------------------------------------------
variable "ingress_name" {
  description = "Ingress 이름"
  type        = string
  default     = "app-ingress"
}

variable "load_balancer_name" {
  description = "ALB 이름 (AWS 콘솔 표시용)"
  type        = string
  default     = "app-alb"
}

variable "alb_scheme" {
  description = "ALB 스킴 (internet-facing, internal)"
  type        = string
  default     = "internet-facing"
}

variable "ssl_redirect_enabled" {
  description = "HTTP → HTTPS 리다이렉트 활성화"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# 앱 설정
# -----------------------------------------------------------------------------
variable "apps" {
  description = "배포할 애플리케이션 목록"
  type = list(object({
    name              = string # 앱 이름
    image             = string # 컨테이너 이미지
    replicas          = number # Pod 복제본 수
    container_port    = number # 컨테이너 포트
    health_check_path = string # 헬스체크 경로

    # Ingress 라우팅 설정
    ingress_path      = string # URL 경로 (예: /app1)
    ingress_path_type = string # Prefix, Exact
    is_default        = bool   # 기본 백엔드 여부

    # 외부 노출 여부 (Ingress에 포함할지)
    expose_external = bool # true: Ingress에 포함, false: 내부용

    # 리소스 설정 (선택적)
    resources = optional(object({
      requests_cpu    = string
      requests_memory = string
      limits_cpu      = string
      limits_memory   = string
    }))
  }))
}


variable "hosted_zone_id" {
  description = "ACM 검증을 위한 Route53 Hosted Zone ID"
  type        = string
  default     = null
}

# ============================================
# Tags
# ============================================
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}