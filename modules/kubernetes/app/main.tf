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

/* kubectl get sc 시 gp2 없으면 주석처리 
# 기존 gp2를 기본에서 제거 - # gp2가 default가 아니도록 설정(어노테이션 제거)하는 코드
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
*/

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
# ===== Deployment =====
resource "kubernetes_deployment_v1" "app" {

  metadata {
    name      = var.project_name
    namespace = var.namespace
    labels = {
      app         = var.project_name
      environment = var.environment
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.project_name
      }
    }

    strategy {
      type = "RollingUpdate"

      # rolling_update {
      #   max_surge       = var.max_surge
      #   max_unavailable = var.max_unavailable
      # }
    }

    template {
      metadata {
        labels = {
          app         = var.project_name
          environment = var.environment
        }

        # annotations = var.pod_annotations
      }

      spec {
        # [핵심] PVC I/O Error 해결을 위한 Security Context 설정 (권한 확보)
        security_context {
          fs_group = 1000 # 볼륨의 소유권을 1000 GID로 설정
        }

        # [핵심] index.html 파일 생성을 위한 Init Container (403/500 에러 방지)
        init_container {
          name    = "init-html"
          image   = "busybox"
          command = ["/bin/sh", "-c", "echo '<h1>Hello via NLB!</h1>' > /html/index.html"]

          volume_mount {
            name       = "persistent-storage"
            mount_path = "/html"
          }
        }

        container {
          name  = "nginx-container"
          image = "nginx:latest"

          port {
            container_port = 80 # Nginx 기본 포트
          }

          # Nginx 컨테이너에서 PVC 마운트
          volume_mount {
            name       = "persistent-storage"
            mount_path = "/usr/share/nginx/html" # Nginx 루트 경로
          }
        }

        # PVC를 Deployment에 Volume으로 연결
        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = "${var.project_name}-pvc" # 실제 PVC 이름으로 변경 필요
          }
        }
      }

    }
  }

  lifecycle {
    ignore_changes = [
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
      app = kubernetes_deployment_v1.app.spec.0.selector.0.match_labels.app
    }



    port {
      port        = 80 # NLB Listener Port
      target_port = 80 # Pod Container Port
    }

    type = "LoadBalancer"


  }
}