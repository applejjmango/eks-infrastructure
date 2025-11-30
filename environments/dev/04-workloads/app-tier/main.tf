

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
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "plydevops-infra-tf-dev"
    key    = "dev/01-network/terraform.tfstate"
    region = var.aws_region
  }
}


# ============================================
# Local Values
# ============================================
locals {
  name             = "${var.environment}-${var.project_name}"
  eks_cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Layer       = "addons"
    }
  )
}

# ===== playdevops WebApp 배포 =====
# 실무: modules/kubernetes/app/ 모듈 사용
module "playdevops" {
  source = "../../../../modules/kubernetes/app"

  # ===== 기본 설정 =====
  project_name = var.project_name
  namespace    = var.namespace
  environment  = "dev"

  # 실무: dev 환경은 default 네임스페이스 사용 가능
  # prod 환경은 별도 네임스페이스 권장
  create_namespace = var.create_namespace

  namespace_labels = {
    "team"        = "backend"
    "application" = "playdevops"
    "tier"        = "app"
  }

  # ===== 컨테이너 이미지 =====
  # 실무: ECR 사용 권장, latest 태그 절대 금지
  # 기존 코드: stacksimplify/kubenginx:1.0.0
  image_repository  = var.image_repository
  image_tag         = var.image_tag
  image_pull_policy = "IfNotPresent"
  app_version       = var.app_version

  # 실무: Private Registry (ECR) 사용 시
  # image_pull_secrets = ["ecr-registry-secret"]

  # ===== Deployment 설정 =====
  # 실무: dev=1, staging=2, prod=3+
  replicas = var.replicas

  # 실무: 롤링 업데이트 전략
  max_surge       = "1" # 동시 1개 추가 생성
  max_unavailable = "0" # 무중단 배포

  # 실무: 우아한 종료 (진행 중인 요청 완료)
  termination_grace_period_seconds = 30

  # ===== 컨테이너 리소스 =====
  # 실무: 모니터링 데이터 기반으로 조정
  container_port = var.container_port
  cpu_request    = var.cpu_request
  memory_request = var.memory_request
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit

  # ===== Health Check (실무 필수) =====
  # Liveness: 애플리케이션이 살아있는지 확인
  enable_liveness_probe            = true
  liveness_probe_path              = var.liveness_probe_path
  liveness_probe_initial_delay     = var.liveness_probe_initial_delay
  liveness_probe_period            = 10
  liveness_probe_timeout           = 5
  liveness_probe_failure_threshold = 3

  # Readiness: 트래픽 받을 준비가 되었는지 확인
  enable_readiness_probe            = true
  readiness_probe_path              = var.readiness_probe_path
  readiness_probe_initial_delay     = var.readiness_probe_initial_delay
  readiness_probe_period            = 5
  readiness_probe_timeout           = 3
  readiness_probe_failure_threshold = 3

  # ===== 환경 변수 =====
  # 실무: 민감하지 않은 설정만 여기에
  # 민감 정보는 Kubernetes Secret 또는 AWS Secrets Manager 사용
  environment_variables = merge(
    var.environment_variables,
    {
      # 실무: 환경별 자동 주입
      "APP_ENV"   = "dev"
      "LOG_LEVEL" = "debug"
      "TZ"        = "Asia/Seoul"
    }
  )

  # ===== ConfigMap =====
  # 실무: 설정 파일 외부화 (재배포 없이 변경 가능)
  config_map_data = var.config_map_data

  # ===== 보안 설정 (실무 권장) =====
  # 왜: 최소 권한 원칙, 컨테이너 보안 강화
  run_as_non_root           = true
  run_as_user               = 1000
  read_only_root_filesystem = false # nginx는 로컬 쓰기 필요

  # ===== 영구 스토리지 =====
  # 실무: 파일 업로드, 로그 저장 등
  # EBS CSI Driver gp3 사용 (gp2보다 30% 저렴)
  enable_persistent_storage = var.enable_persistent_storage
  pvc_storage_size          = var.pvc_storage_size
  storage_class_name        = "gp3"
  volume_mount_path         = var.volume_mount_path
  pvc_access_modes          = ["ReadWriteOnce"]
  volume_read_only          = false
  prevent_pvc_destroy       = false # dev: false, prod: true

  # ===== Service 설정 =====
  create_service = true
  service_type   = var.service_type
  service_port   = var.service_port

  # 실무: LoadBalancer 타입 시 NLB 설정
  service_annotations = var.service_type == "LoadBalancer" ? {
    # 실무: NLB 사용 (ALB보다 간단하고 빠름)
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"

    # 실무: 외부 노출 (internet-facing) 또는 내부 (internal)
    "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"

    # 실무: Cross-Zone 로드밸런싱 활성화
    "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"

    # 실무: 서브넷 지정 (선택적)
    # "service.beta.kubernetes.io/aws-load-balancer-subnets" = "subnet-xxx,subnet-yyy"
  } : {}

  # 실무: 외부 트래픽 정책
  # Local: 소스 IP 보존, 노드 로컬 Pod만 사용
  # Cluster: 전체 Pod 사용 (기본값)
  external_traffic_policy = var.service_type == "LoadBalancer" ? "Cluster" : "Cluster"

  # ===== 노드 선택 (선택적) =====
  # 실무: 특정 노드 그룹에 배포
  node_selector = var.node_selector

  # ===== Pod 어노테이션 =====
  pod_annotations = {
    "prometheus.io/scrape" = "true"
    "prometheus.io/port"   = tostring(var.container_port)
    "prometheus.io/path"   = "/metrics"
  }
}


