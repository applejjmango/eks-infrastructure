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


variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

# ===== 애플리케이션 기본 설정 =====


variable "namespace" {
  description = "K8s 네임스페이스"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "네임스페이스 생성 여부"
  type        = bool
  default     = false
}

# ===== 컨테이너 이미지 =====
variable "image_repository" {
  description = "컨테이너 이미지 레포지토리"
  type        = string
  # 기존: stacksimplify/kubenginx
  # 실무: 123456789012.dkr.ecr.us-east-1.amazonaws.com/playdevops-webapp
}

variable "image_tag" {
  description = "이미지 태그 (latest 사용 금지)"
  type        = string
  # 실무: 1.0.0, v2.3.1 등 특정 버전
}

variable "app_version" {
  description = "애플리케이션 버전"
  type        = string
  default     = "1.0.0"
}

# ===== Deployment 설정 =====
variable "replicas" {
  description = "Pod 복제본 수 (dev=1, staging=2, prod=3+)"
  type        = number
  default     = 1
}

# ===== 컨테이너 설정 =====
variable "container_port" {
  description = "컨테이너 포트"
  type        = number
  default     = 80
  # nginx: 80
  # Spring Boot: 8080
  # Node.js: 3000
}

variable "cpu_request" {
  description = "CPU 요청량 (100m = 0.1 core)"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "메모리 요청량"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU 제한량"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "메모리 제한량"
  type        = string
  default     = "256Mi"
}

# ===== Health Check =====
variable "liveness_probe_path" {
  description = "Liveness Probe 경로"
  type        = string
  default     = "/"
  # nginx: /
  # Spring Boot: /actuator/health
}

variable "liveness_probe_initial_delay" {
  description = "Liveness Probe 초기 대기 (초)"
  type        = number
  default     = 30
}

variable "readiness_probe_path" {
  description = "Readiness Probe 경로"
  type        = string
  default     = "/"
  # nginx: /
  # Spring Boot: /actuator/health/readiness
}

variable "readiness_probe_initial_delay" {
  description = "Readiness Probe 초기 대기 (초)"
  type        = number
  default     = 10
}

# ===== 환경 변수 =====
variable "environment_variables" {
  description = "컨테이너 환경 변수"
  type        = map(string)
  default     = {}
  # 예: {"DATABASE_HOST" = "mysql.default.svc.cluster.local"}
}

variable "config_map_data" {
  description = "ConfigMap 데이터"
  type        = map(string)
  default     = {}
}

# ===== 스토리지 =====
variable "enable_persistent_storage" {
  description = "영구 스토리지 사용 여부"
  type        = bool
  default     = true
}

variable "pvc_storage_size" {
  description = "PVC 크기"
  type        = string
  default     = "4Gi"
}

variable "volume_mount_path" {
  description = "볼륨 마운트 경로"
  type        = string
  default     = "/usr/share/nginx/html"
  # nginx: /usr/share/nginx/html
  # 파일 업로드: /app/uploads
}

# ===== Service =====
variable "service_type" {
  description = "Service 타입 (ClusterIP/LoadBalancer/NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "service_port" {
  description = "Service 포트"
  type        = number
  default     = 80
}

# ===== 노드 선택 =====
variable "node_selector" {
  description = "노드 셀렉터"
  type        = map(string)
  default     = {}
  # 예: {"workload-type" = "application"}
}

# ============================================
# Tags
# ============================================
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}