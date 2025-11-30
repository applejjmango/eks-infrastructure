output "namespace" {
  description = "배포된 네임스페이스"
  value       = local.namespace
}

output "deployment_name" {
  description = "Deployment 이름"
  value       = kubernetes_deployment_v1.app.metadata[0].name
}

output "deployment_uid" {
  description = "Deployment UID"
  value       = kubernetes_deployment_v1.app.metadata[0].uid
}

output "service_name" {
  description = "Service 이름"
  value       = var.create_service ? kubernetes_service.app[0].metadata[0].name : null
}

output "service_cluster_ip" {
  description = "Service Cluster IP"
  value       = var.create_service ? kubernetes_service.app[0].spec[0].cluster_ip : null
}

output "load_balancer_hostname" {
  description = "LoadBalancer 호스트명 (service_type=LoadBalancer 시)"
  value = var.create_service && var.service_type == "LoadBalancer" ? (
    length(kubernetes_service.app[0].status[0].load_balancer) > 0 &&
    length(kubernetes_service.app[0].status[0].load_balancer[0].ingress) > 0 ?
    kubernetes_service.app[0].status[0].load_balancer[0].ingress[0].hostname : null
  ) : null
}

output "pvc_name" {
  description = "PVC 이름"
  value       = var.enable_persistent_storage ? kubernetes_persistent_volume_claim.app[0].metadata[0].name : null
}

output "config_map_name" {
  description = "ConfigMap 이름"
  value       = length(var.config_map_data) > 0 ? kubernetes_config_map.app[0].metadata[0].name : null
}

output "gp3_storage_class_name" {
  description = "gp3 StorageClass 이름"
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}

output "gp3_provisioner" {
  description = "gp3 Provisioner"
  value       = kubernetes_storage_class_v1.gp3.storage_provisioner
}