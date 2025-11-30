# ===== 로컬 변수 =====
locals {
  # 실무: 모든 리소스에 공통 레이블 적용
  common_labels = {
    app         = var.project_name
    version     = var.app_version
    environment = var.environment
    tier        = "app"
    managed-by  = "terraform"
  }

  # 네임스페이스 결정 로직
  namespace = var.create_namespace ? kubernetes_namespace.app[0].metadata[0].name : var.namespace
}

# ===== Namespace =====
resource "kubernetes_namespace" "app" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = merge(
      local.common_labels,
      var.namespace_labels
    )

    annotations = var.namespace_annotations
  }
}

# ===== gp3 StorageClass 생성 =====
# 실무: EBS CSI Driver용 gp3 StorageClass
# 왜: gp2보다 30% 저렴하고 성능 좋음
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }

    labels = {
      "managed-by"  = "terraform"
      "environment" = "dev"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type      = "gp3"
    encrypted = var.enable_encryption ? "true" : "false"
    fsType    = "ext4"
  }

  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
}

# 기존 gp2를 기본에서 제거
resource "kubernetes_annotations" "gp2_remove_default" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"

  metadata {
    name = "gp2"
  }

  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }

  depends_on = [kubernetes_storage_class_v1.gp3]
}

# ===== PVC (Persistent Volume Claim) =====
# 실무: Deployment용 PVC (ReadWriteOnce)
# 왜: 파일 업로드, 로그 저장 등 영구 스토리지 필요 시
resource "kubernetes_persistent_volume_claim" "app" {
  count = var.enable_persistent_storage ? 1 : 0

  metadata {
    name      = "${var.project_name}-pvc"
    namespace = local.namespace
    labels    = local.common_labels
  }

  spec {
    # 실무: Deployment는 ReadWriteOnce 사용 (EBS)
    # StatefulSet은 VolumeClaimTemplate 사용
    access_modes = var.pvc_access_modes

    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }

    # 실무: gp3 스토리지 클래스 (gp2보다 30% 저렴)
    storage_class_name = var.storage_class_name
  }

  # 실무: PVC 삭제 방지 (데이터 보호) #[PROD]
  # lifecycle {
  #   prevent_destroy = var.prevent_pvc_destroy
  # }
}

# ===== ConfigMap =====
# 실무: 설정 파일 외부화 (이미지 재빌드 없이 설정 변경)
resource "kubernetes_config_map" "app" {
  count = length(var.config_map_data) > 0 ? 1 : 0

  metadata {
    name      = "${var.project_name}-config"
    namespace = local.namespace
    labels    = local.common_labels
  }

  # 실무: 설정 파일 또는 환경 변수
  # 예: application.properties, nginx.conf
  data = var.config_map_data

  # 실무: 바이너리 데이터 (선택적)
  binary_data = var.config_map_binary_data
}

# ===== Deployment =====
# 실무: Stateless 애플리케이션의 핵심 리소스
# 왜: 롤링 업데이트, 자동 복구, 스케일링 자동 관리
resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = var.project_name
    namespace = local.namespace
    labels    = local.common_labels

    # 실무: 배포 히스토리 추적용 어노테이션
    annotations = {
      "deployment.kubernetes.io/revision" = "1"
    }
  }

  spec {
    # 실무: dev=1, staging=2, prod=3+ replicas
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.project_name
      }
    }

    # 실무: 롤링 업데이트 전략 (무중단 배포)
    strategy {
      type = "RollingUpdate"

      rolling_update {
        # 실무: 동시에 생성 가능한 추가 Pod 수
        # 25% = replicas가 4개면 1개 추가 생성 가능
        max_surge = var.max_surge

        # 실무: 업데이트 중 중단 가능한 Pod 수
        # 0 = 무중단 배포 (권장)
        max_unavailable = var.max_unavailable
      }
    }

    template {
      metadata {
        labels = local.common_labels

        # 실무: Prometheus 메트릭 수집 어노테이션
        annotations = merge(
          {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = tostring(var.container_port)
            "prometheus.io/path"   = "/metrics"
          },
          var.pod_annotations
        )
      }

      spec {
        # 실무: 특정 노드에 Pod 배포 (선택적)
        # 예: GPU 노드, Spot 인스턴스 노드
        node_selector = var.node_selector

        # 실무: 우아한 종료 대기 시간 (초)
        # 왜: Pod 종료 시 진행 중인 요청 완료할 시간 제공
        termination_grace_period_seconds = var.termination_grace_period_seconds

        container {
          name  = var.project_name
          image = "${var.image_repository}:${var.image_tag}"

          # 실무: 이미지 Pull 정책
          # IfNotPresent: 로컬에 없을 때만 다운로드 (권장)
          # Always: 매번 최신 이미지 확인 (latest 태그 사용 시)
          image_pull_policy = var.image_pull_policy

          # 컨테이너 포트
          port {
            name           = "http"
            container_port = var.container_port
            protocol       = "TCP"
          }

          # 실무 필수: 리소스 요청/제한
          # 왜: requests 없으면 노드 과부하, limits 없으면 다른 Pod 영향
          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          # 실무 필수: Liveness Probe
          # 왜: 애플리케이션이 응답 없으면 컨테이너 재시작
          # 언제: 데드락, 무한 루프 등 감지
          dynamic "liveness_probe" {
            for_each = var.enable_liveness_probe ? [1] : []

            content {
              http_get {
                path   = var.liveness_probe_path
                port   = var.container_port
                scheme = "HTTP"
              }

              # 실무: 초기 대기 시간은 앱 시작 시간보다 길게
              # 예: Spring Boot 느리면 60-120초
              initial_delay_seconds = var.liveness_probe_initial_delay

              # 실무: 체크 주기 (기본 10초)
              period_seconds = var.liveness_probe_period

              # 실무: 타임아웃 (기본 5초)
              timeout_seconds = var.liveness_probe_timeout

              # 실무: 연속 실패 횟수 (기본 3회)
              failure_threshold = var.liveness_probe_failure_threshold

              # 실무: 연속 성공 횟수 (기본 1회)
              success_threshold = 1
            }
          }

          # 실무 필수: Readiness Probe
          # 왜: Pod가 트래픽 받을 준비되었는지 확인
          # 언제: DB 연결, 캐시 워밍업 등 완료 후
          dynamic "readiness_probe" {
            for_each = var.enable_readiness_probe ? [1] : []

            content {
              http_get {
                path   = var.readiness_probe_path
                port   = var.container_port
                scheme = "HTTP"
              }

              # 실무: Readiness는 Liveness보다 빠르게 시작
              initial_delay_seconds = var.readiness_probe_initial_delay
              period_seconds        = var.readiness_probe_period
              timeout_seconds       = var.readiness_probe_timeout
              failure_threshold     = var.readiness_probe_failure_threshold
              success_threshold     = 1
            }
          }

          # 환경 변수 주입
          # 실무: 민감하지 않은 설정만 여기에
          dynamic "env" {
            for_each = var.environment_variables

            content {
              name  = env.key
              value = env.value
            }
          }

          # ConfigMap에서 환경 변수 로드
          # 실무: 설정 파일을 환경 변수로 변환
          dynamic "env_from" {
            for_each = length(var.config_map_data) > 0 ? [1] : []

            content {
              config_map_ref {
                name = kubernetes_config_map.app[0].metadata[0].name
              }
            }
          }

          # PVC 마운트 (선택적)
          # 실무: 파일 업로드, 공유 스토리지 등
          dynamic "volume_mount" {
            for_each = var.enable_persistent_storage ? [1] : []

            content {
              name       = "persistent-storage"
              mount_path = var.volume_mount_path

              # 실무: 읽기 전용 마운트가 필요한 경우
              read_only = var.volume_read_only
            }
          }

          # 실무: 보안 컨텍스트 (권장)
          # 왜: 최소 권한 원칙, 루트 권한 실행 방지
          security_context {
            # 실무: 비루트 사용자로 실행 (보안)
            run_as_non_root = var.run_as_non_root
            run_as_user     = var.run_as_user

            # 실무: 읽기 전용 루트 파일시스템 (보안)
            read_only_root_filesystem = var.read_only_root_filesystem

            # 실무: 권한 상승 방지
            allow_privilege_escalation = false
          }
        }

        # PVC를 Pod 볼륨으로 정의
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [1] : []

          content {
            name = "persistent-storage"

            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.app[0].metadata[0].name
            }
          }
        }

        # 실무: 이미지 Pull Secret (Private Registry)
        # 왜: ECR, Docker Hub Private 사용 시 필요
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets

          content {
            name = image_pull_secrets.value
          }
        }
      }
    }
  }

  # 실무: 라이프사이클 설정
  # 왜: 불필요한 재시작 방지
  lifecycle {
    ignore_changes = [
      # kubectl rollout restart로 재시작 시 어노테이션 변경 무시
      spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"]
    ]
  }
}

# ===== Service =====
# 실무: Pod간 로드밸런싱 및 서비스 디스커버리
resource "kubernetes_service" "app" {
  count = var.create_service ? 1 : 0

  metadata {
    name      = var.project_name
    namespace = local.namespace
    labels    = local.common_labels

    # 실무: Service 타입별 어노테이션
    # 예: LoadBalancer 타입 시 NLB/ALB 설정
    annotations = var.service_annotations
  }

  spec {
    selector = {
      app = var.project_name
    }

    # 실무: Service 타입 선택 가이드
    # ClusterIP: 클러스터 내부 통신 (Ingress 사용 시)
    # LoadBalancer: 외부 노출 (AWS NLB/ALB 생성)
    # NodePort: 테스트/개발 환경
    type = var.service_type

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"

      # 실무: NodePort 타입 시 포트 지정 (선택적)
      node_port = var.service_type == "NodePort" ? var.node_port : null
    }

    # 실무: Session Affinity (선택적)
    # 왜: 동일 클라이언트 요청을 같은 Pod로 라우팅
    # 언제: WebSocket, Stateful 세션 필요 시
    session_affinity = var.session_affinity

    # 실무: 외부 트래픽 정책 (LoadBalancer/NodePort)
    # Local: 동일 노드의 Pod로만 라우팅 (소스 IP 보존)
    # Cluster: 모든 노드의 Pod로 라우팅 (기본값)
    external_traffic_policy = var.external_traffic_policy
  }
}