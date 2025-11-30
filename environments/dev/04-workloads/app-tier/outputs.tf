# ===== Outputs =====
# 실무: 배포 정보 출력 (디버깅 및 확인용)
output "deployment_info" {
  description = "playdevops WebApp 배포 정보"
  value = {
    namespace          = module.playdevops.namespace
    deployment_name    = module.playdevops.deployment_name
    service_name       = module.playdevops.service_name
    service_cluster_ip = module.playdevops.service_cluster_ip
    load_balancer_url  = module.playdevops.load_balancer_hostname
    pvc_name           = module.playdevops.pvc_name
    config_map_name    = module.playdevops.config_map_name
  }
}

# 실무: kubectl 명령어 가이드
output "kubectl_commands" {
  description = "유용한 kubectl 명령어"
  value       = <<-EOT
    # ===== Pod 관리 =====
    # Pod 목록 확인
    kubectl get pods -n ${module.playdevops.namespace} -l app=${var.project_name}
    
    # Pod 상태 실시간 확인
    kubectl get pods -n ${module.playdevops.namespace} -l app=${var.project_name} -w
    
    # Pod 상세 정보
    kubectl describe pod -n ${module.playdevops.namespace} -l app=${var.project_name}
    
    # Pod 로그 확인 (실시간)
    kubectl logs -n ${module.playdevops.namespace} -l app=${var.project_name} --tail=100 -f
    
    # ===== Deployment 관리 =====
    # Deployment 상태
    kubectl get deployment ${var.project_name} -n ${module.playdevops.namespace}
    
    # Deployment 상세 정보
    kubectl describe deployment ${var.project_name} -n ${module.playdevops.namespace}
    
    # 수동 재시작 (롤링 업데이트)
    kubectl rollout restart deployment/${var.project_name} -n ${module.playdevops.namespace}
    
    # 롤링 업데이트 상태 확인
    kubectl rollout status deployment/${var.project_name} -n ${module.playdevops.namespace}
    
    # 롤백
    kubectl rollout undo deployment/${var.project_name} -n ${module.playdevops.namespace}
    
    # 롤아웃 히스토리
    kubectl rollout history deployment/${var.project_name} -n ${module.playdevops.namespace}
    
    # ===== 스토리지 관리 =====
    # PVC 상태
    kubectl get pvc -n ${module.playdevops.namespace}
    
    # PVC 상세 정보
    kubectl describe pvc -n ${module.playdevops.namespace}
    
    # ===== 네트워크 관리 =====
    # Service 상태
    kubectl get svc ${var.project_name} -n ${module.playdevops.namespace}
    
    # Service 상세 정보
    kubectl describe svc ${var.project_name} -n ${module.playdevops.namespace}
    
    # LoadBalancer 주소 확인
    kubectl get svc ${var.project_name} -n ${module.playdevops.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    # ===== 디버깅 =====
    # Pod 내부 접속
    kubectl exec -it -n ${module.playdevops.namespace} <pod-name> -- /bin/bash
    
    # 이벤트 확인
    kubectl get events -n ${module.playdevops.namespace} --sort-by='.lastTimestamp'
    
    # 리소스 사용량 확인
    kubectl top pods -n ${module.playdevops.namespace} -l app=${var.project_name}
    
    # ===== 애플리케이션 접속 =====
    # LoadBalancer URL로 접속
    curl http://${module.playdevops.load_balancer_hostname}
  EOT
}

# 실무: LoadBalancer URL 출력 (웹 브라우저 접속용)
output "application_url" {
  description = "애플리케이션 접속 URL"
  value = var.service_type == "LoadBalancer" ? (
    module.playdevops.load_balancer_hostname != null ?
    "http://${module.playdevops.load_balancer_hostname}" :
    "LoadBalancer 생성 중..."
  ) : "ClusterIP 서비스 (내부 접근만 가능)"
}