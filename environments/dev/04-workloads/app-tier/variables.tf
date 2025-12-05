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
variable "ingress_class_name" {
  description = "Ingress Class 이름"
  type        = string
  default     = "alb"
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

# =============================================================================
# [추가] Ingress Group 설정
# =============================================================================
variable "ingress_group_name" {
  description = "Ingress Group 이름 (여러 Ingress를 이 이름의 ALB 하나로 통합)"
  type        = string
  default     = null # null이면 개별 Ingress 생성 (기존 동작 유지)
}

variable "ingress_group_order" {
  description = "Ingress Group 내에서 이 Ingress의 우선순위 (낮을수록 먼저 평가됨)"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# 앱 설정
# -----------------------------------------------------------------------------
variable "microservices" {
  description = "마이크로서비스 배포 설정 맵 (Key: 서비스명)"
  type = map(object({
    # 1. 컨테이너 설정
    image             = string
    replicas          = number
    container_port    = number
    service_port      = number
    health_check_path = string

    # 2. 리소스 제한 (선택적)
    resources = optional(object({
      requests_cpu    = string
      requests_memory = string
      limits_cpu      = string
      limits_memory   = string
    }))

    # 3. Ingress 라우팅 설정
    expose_external   = bool         # true: Ingress 생성, false: ClusterIP만 생성
    ingress_hosts     = list(string) # 연결할 도메인 목록
    ingress_path      = string       # URL 경로
    ingress_path_type = string       # Prefix 등
    ingress_order     = number       # Ingress Group 내 우선순위 (필수)
    is_default        = bool         # Default Backend 여부
  }))
  default = {}
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