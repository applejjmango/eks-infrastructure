

# ============================================
# Remote State: EKS Cluster
# ============================================
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "plydevops-infra-tf-dev"
    key    = "dev/02-eks/terraform.tfstate"
    region = var.aws_region
  }
}

# ============================================
# Remote State: Network Layer
# ============================================
data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = "plydevops-infra-tf-dev"
    key    = "dev/03-platform/terraform.tfstate"
    region = var.aws_region
  }
}


# ============================================
# Local Values
# ============================================
locals {
  # Platform Remote State에서 IngressClass 이름 가져오기
  ingress_class_name = data.terraform_remote_state.platform.outputs.ingress_class_name

  # 외부 노출 앱만 필터링 (Ingress에 포함)
  external_apps = [for app in var.apps : app if app.expose_external]

  # 모든 앱 (Deployment + Service는 모두 생성)
  all_apps = { for app in var.apps : app.name => app }
}

# =============================================================================
# App Tier - Main
# =============================================================================
# 실무 관점: 앱 배포 + Ingress를 하나의 티어에서 관리
#
# 구조:
#   1. App 모듈: 각 앱의 Deployment + Service 생성
#   2. Ingress 모듈: ACM + ALB Ingress 생성 (외부 노출 앱만)
#
# 장점:
#   - 한 번의 terraform apply로 앱 + Ingress 배포
#   - 관련 리소스가 한 곳에서 관리
#   - 원자적 배포/롤백 가능
# =============================================================================
module "apps" {
  source   = "../../../../modules/kubernetes/app"
  for_each = local.all_apps

  # -----------------------------
  # 기본 설정
  # -----------------------------
  app_name        = each.value.name
  environment     = var.environment
  namespace       = var.namespace
  container_image = each.value.image
  replicas        = each.value.replicas
  container_port  = each.value.container_port

  # -----------------------------
  # Health Check
  # -----------------------------
  health_check_path = each.value.health_check_path

  # -----------------------------
  # Service 설정
  # 실무: 외부 노출 앱은 NodePort, 내부용은 ClusterIP
  # -----------------------------
  create_service = true
  service_type   = each.value.expose_external ? "NodePort" : "ClusterIP"
  service_port   = 80

  # ALB Ingress Controller용 헬스체크 경로
  service_annotations = each.value.expose_external ? {
    "alb.ingress.kubernetes.io/healthcheck-path" = each.value.health_check_path
  } : {}

  # -----------------------------
  # 리소스 제한
  # -----------------------------
  resources = each.value.resources != null ? {
    requests = {
      cpu    = each.value.resources.requests_cpu
      memory = each.value.resources.requests_memory
    }
    limits = {
      cpu    = each.value.resources.limits_cpu
      memory = each.value.resources.limits_memory
    }
    } : {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }

  # 레이블
  labels = merge(var.tags, {
    app-tier = each.value.expose_external ? "external" : "internal"
  })
}

# =============================================================================
# ALB SSL Ingress 모듈 호출 (조건부)
# =============================================================================
# 실무: enable_ingress가 true이고, 외부 노출 앱이 있을 때만 생성

module "alb_ssl_ingress" {
  source = "../../../../modules/kubernetes/ingress/alb-ssl"
  count  = var.enable_ingress && length(local.external_apps) > 0 ? 1 : 0

  # -----------------------------
  # 기본 설정
  # -----------------------------
  environment  = var.environment
  project_name = var.project_name
  namespace    = var.namespace

  # -----------------------------
  # ACM 인증서
  # -----------------------------
  create_acm_certificate = var.create_acm_certificate
  acm_domain_name        = var.acm_domain_name
  acm_certificate_arn    = var.acm_certificate_arn
  acm_validation_method  = "DNS"

  # -----------------------------
  # Ingress 설정
  # -----------------------------
  ingress_name         = var.ingress_name
  load_balancer_name   = var.load_balancer_name
  ingress_class_name   = local.ingress_class_name
  alb_scheme           = var.alb_scheme
  ssl_redirect_enabled = var.ssl_redirect_enabled
  ssl_policy           = "ELBSecurityPolicy-TLS-1-2-2017-01"

  # -----------------------------
  # Health Check
  # -----------------------------
  health_check = {
    protocol            = "HTTP"
    port                = "traffic-port"
    interval_seconds    = 15
    timeout_seconds     = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    success_codes       = "200"
  }

  # -----------------------------
  # 백엔드 서비스 연결
  # 실무: App 모듈의 output을 참조하여 Service 연결
  # -----------------------------
  backend_services = [
    for app in local.external_apps : {
      name              = module.apps[app.name].service_name
      port              = module.apps[app.name].service_port
      path              = app.ingress_path
      path_type         = app.ingress_path_type
      health_check_path = app.health_check_path
      is_default        = app.is_default
    }
  ]

  # 태그
  tags = var.tags

  # App 모듈이 먼저 생성되어야 함
  depends_on = [module.apps]
}

