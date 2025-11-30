# ===== 기본 설정 =====
variable "project_name" {
  description = "애플리케이션 이름 (K8s 리소스명)"
  type        = string
}

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

variable "namespace_labels" {
  description = "네임스페이스 레이블"
  type        = map(string)
  default     = {}
}

variable "namespace_annotations" {
  description = "네임스페이스 어노테이션"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "환경 (dev/staging/prod)"
  type        = string
}

# ===== 컨테이너 이미지 =====
variable "image_repository" {
  description = "컨테이너 이미지 레포지토리"
  type        = string
  # 예: stacksimplify/kubenginx
  # 예: 123456789012.dkr.ecr.us-east-1.amazonaws.com/app
}

variable "image_tag" {
  description = "이미지 태그 (latest 사용 금지)"
  type        = string
  # 실무: 특정 버전 명시 (1.0.0, v2.3.1 등)
}

variable "image_pull_policy" {
  description = "이미지 Pull 정책"
  type        = string
  default     = "IfNotPresent"

  validation {
    condition     = contains(["Always", "IfNotPresent", "Never"], var.image_pull_policy)
    error_message = "유효한 값: Always, IfNotPresent, Never"
  }
}

variable "image_pull_secrets" {
  description = "이미지 Pull Secret 목록 (Private Registry)"
  type        = list(string)
  default     = []
  # 예: ["ecr-registry-secret"]
}

variable "app_version" {
  description = "애플리케이션 버전 (레이블용)"
  type        = string
  default     = "1.0.0"
}

# ===== Deployment 설정 =====
variable "replicas" {
  description = "Pod 복제본 수"
  type        = number
  default     = 2

  validation {
    condition     = var.replicas >= 1
    error_message = "최소 1개 이상의 replica 필요"
  }
}

variable "max_surge" {
  description = "롤링 업데이트 시 최대 추가 Pod 수 (또는 %)"
  type        = string
  default     = "25%"
  # 실무: "1" 또는 "25%"
}

variable "max_unavailable" {
  description = "롤링 업데이트 시 최대 중단 가능 Pod 수 (또는 %)"
  type        = string
  default     = "0"
  # 실무: 무중단 배포는 "0"
}

variable "termination_grace_period_seconds" {
  description = "Pod 종료 대기 시간 (초)"
  type        = number
  default     = 30
  # 실무: 웹앱 30초, 배치작업 300초
}

# ===== 컨테이너 설정 =====
variable "container_port" {
  description = "컨테이너 포트"
  type        = number
  # 실무: 80 (nginx), 8080 (Spring Boot), 3000 (Node.js)
}

variable "cpu_request" {
  description = "CPU 요청량 (100m = 0.1 core)"
  type        = string
  default     = "100m"
  # 실무: 모니터링 데이터 기반 조정
}

variable "memory_request" {
  description = "메모리 요청량"
  type        = string
  default     = "128Mi"
  # 실무: 애플리케이션 메모리 사용량 기반
}

variable "cpu_limit" {
  description = "CPU 제한량"
  type        = string
  default     = "500m"
  # 실무: limit을 너무 낮게 설정하면 throttling 발생
}

variable "memory_limit" {
  description = "메모리 제한량"
  type        = string
  default     = "512Mi"
  # 실무: limit 초과 시 OOMKilled 발생
}

variable "pod_annotations" {
  description = "Pod 어노테이션"
  type        = map(string)
  default     = {}
}

# ===== Health Check =====
variable "enable_liveness_probe" {
  description = "Liveness Probe 활성화"
  type        = bool
  default     = true
}

variable "liveness_probe_path" {
  description = "Liveness Probe HTTP 경로"
  type        = string
  default     = "/health"
  # 실무: Spring Boot: /actuator/health
  # 실무: Express.js: /health
  # 실무: nginx: /
}

variable "liveness_probe_initial_delay" {
  description = "Liveness Probe 초기 대기 시간 (초)"
  type        = number
  default     = 30
  # 실무: 느린 앱은 60-120초
}

variable "liveness_probe_period" {
  description = "Liveness Probe 체크 주기 (초)"
  type        = number
  default     = 10
}

variable "liveness_probe_timeout" {
  description = "Liveness Probe 타임아웃 (초)"
  type        = number
  default     = 5
}

variable "liveness_probe_failure_threshold" {
  description = "Liveness Probe 실패 임계값"
  type        = number
  default     = 3
}

variable "enable_readiness_probe" {
  description = "Readiness Probe 활성화"
  type        = bool
  default     = true
}

variable "readiness_probe_path" {
  description = "Readiness Probe HTTP 경로"
  type        = string
  default     = "/ready"
  # 실무: Spring Boot: /actuator/health/readiness
}

variable "readiness_probe_initial_delay" {
  description = "Readiness Probe 초기 대기 시간 (초)"
  type        = number
  default     = 10
}

variable "readiness_probe_period" {
  description = "Readiness Probe 체크 주기 (초)"
  type        = number
  default     = 5
}

variable "readiness_probe_timeout" {
  description = "Readiness Probe 타임아웃 (초)"
  type        = number
  default     = 3
}

variable "readiness_probe_failure_threshold" {
  description = "Readiness Probe 실패 임계값"
  type        = number
  default     = 3
}

# ===== 환경 변수 =====
variable "environment_variables" {
  description = "컨테이너 환경 변수 (key-value)"
  type        = map(string)
  default     = {}
  # 실무: 민감하지 않은 설정만
  # 예: {"APP_ENV" = "dev", "LOG_LEVEL" = "info"}
}

variable "config_map_data" {
  description = "ConfigMap 데이터 (key-value)"
  type        = map(string)
  default     = {}
  # 실무: 설정 파일 외부화
  # 예: {"application.properties" = file("config/app.properties")}
}

variable "config_map_binary_data" {
  description = "ConfigMap 바이너리 데이터"
  type        = map(string)
  default     = {}
}

# ===== 보안 설정 =====
variable "run_as_non_root" {
  description = "비루트 사용자로 실행"
  type        = bool
  default     = true
  # 실무: 보안 강화를 위해 true 권장
}

variable "run_as_user" {
  description = "실행 사용자 ID"
  type        = number
  default     = 1000
}

variable "read_only_root_filesystem" {
  description = "읽기 전용 루트 파일시스템"
  type        = bool
  default     = false
  # 실무: 앱이 로컬 쓰기 필요하면 false
}

# ===== 스토리지 =====
variable "enable_persistent_storage" {
  description = "영구 스토리지(PVC) 사용 여부"
  type        = bool
  default     = false
}

variable "pvc_storage_size" {
  description = "PVC 스토리지 크기"
  type        = string
  default     = "10Gi"
  # 실무: 사용량에 따라 조정
}

variable "pvc_access_modes" {
  description = "PVC 액세스 모드"
  type        = list(string)
  default     = ["ReadWriteOnce"]
  # 실무: RWO (EBS), RWX (EFS), ROX (읽기전용)
}

variable "storage_class_name" {
  description = "스토리지 클래스 이름"
  type        = string
  default     = "gp3"
  # 실무: gp3 (EBS CSI), efs-sc (EFS CSI)
}

variable "volume_mount_path" {
  description = "컨테이너 내 볼륨 마운트 경로"
  type        = string
  default     = "/data"
  # 실무: 애플리케이션 요구사항에 맞게
  # 예: /usr/share/nginx/html, /app/uploads
}

variable "volume_read_only" {
  description = "볼륨 읽기 전용 마운트"
  type        = bool
  default     = false
}

variable "prevent_pvc_destroy" {
  description = "PVC 삭제 방지 (데이터 보호)"
  type        = bool
  default     = false
  # 실무: dev: false, prod: true
}

# ===== Service 설정 =====
variable "create_service" {
  description = "Service 생성 여부"
  type        = bool
  default     = true
}

variable "service_type" {
  description = "Service 타입"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "LoadBalancer", "NodePort"], var.service_type)
    error_message = "유효한 Service 타입: ClusterIP, LoadBalancer, NodePort"
  }
}

variable "service_port" {
  description = "Service 포트"
  type        = number
  default     = 80
}

variable "service_annotations" {
  description = "Service 어노테이션 (LB 설정 등)"
  type        = map(string)
  default     = {}
  # 실무 예시 (NLB):
  # {
  #   "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
  #   "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
  # }
}

variable "node_port" {
  description = "NodePort (service_type=NodePort 시)"
  type        = number
  default     = null
}

variable "session_affinity" {
  description = "세션 어피니티 (None/ClientIP)"
  type        = string
  default     = "None"
  # 실무: WebSocket, Stateful 세션 필요 시 "ClientIP"
}

variable "external_traffic_policy" {
  description = "외부 트래픽 정책 (Cluster/Local)"
  type        = string
  default     = "Cluster"
  # 실무: Local = 소스 IP 보존, Cluster = 전체 Pod 사용
}

# ===== 노드 선택 =====
variable "node_selector" {
  description = "노드 셀렉터 (특정 노드에 배포)"
  type        = map(string)
  default     = {}
  # 실무 예시:
  # {"workload-type" = "application"}
  # {"node-type" = "spot"}
}

variable "enable_encryption" {
  description = "EBS 암호화 활성화"
  type        = bool
  default     = false # dev: false, prod: true
}