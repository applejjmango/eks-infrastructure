# ============================================
# Addons Layer Outputs
# ============================================

# ============================================
# EBS CSI Driver Outputs
# ============================================
output "ebs_csi_driver_iam_role_arn" {
  description = "IAM Role ARN for EBS CSI Driver"
  value       = var.enable_ebs_csi_driver ? module.ebs_csi_driver[0].iam_role_arn : null
}

output "ebs_csi_driver_addon_id" {
  description = "EBS CSI Driver add-on ID"
  value       = var.enable_ebs_csi_driver ? module.ebs_csi_driver[0].addon_id : null
}

output "ebs_csi_driver_addon_version" {
  description = "EBS CSI Driver add-on version"
  value       = var.enable_ebs_csi_driver ? module.ebs_csi_driver[0].addon_version : null
}



# ============================================
# Verification Commands
# ============================================
output "ebs_csi_verification_commands" {
  description = "Shell commands to verify EBS CSI Driver; run manually or via script if enable_ebs_csi_driver = true"
  value       = <<-EOT
    # ============================================
    # Verify EBS CSI Driver Add-on
    # ============================================
    aws eks list-addons --cluster-name ${local.eks_cluster_name}
    aws eks describe-addon --cluster-name ${local.eks_cluster_name} --addon-name aws-ebs-csi-driver
    kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-ebs-csi-driver
    kubectl -n kube-system get deploy ebs-csi-controller
    kubectl -n kube-system get ds ebs-csi-node
    kubectl -n kube-system get sa ebs-csi-controller-sa
    kubectl -n kube-system get sa ebs-csi-controller-sa -o jsonpath='{.metadata.annotations.eks\\.amazonaws\\.com/role-arn}'
    kubectl get storageclass
    kubectl get sc ebs-sc
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: test-ebs-pvc
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: gp3
      resources:
        requests:
          storage: 1Gi
    EOF
    kubectl get pvc test-ebs-pvc
    kubectl get pv
    kubectl delete pvc test-ebs-pvc
  EOT
  # optional: sensitive = false
}


# ============================================
# AWS Load Balancer Controller Outputs
# ============================================
output "alb_controller_iam_role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  value       = var.enable_alb_controller ? module.aws_load_balancer_controller[0].iam_role_arn : null
}

output "alb_controller_helm_release_name" {
  description = "Helm release name for AWS Load Balancer Controller"
  value       = var.enable_alb_controller ? module.aws_load_balancer_controller[0].helm_release_name : null
}

output "alb_controller_helm_release_status" {
  description = "Helm release status for AWS Load Balancer Controller"
  value       = var.enable_alb_controller ? module.aws_load_balancer_controller[0].helm_release_status : null
}

output "alb_controller_ingress_class_name" {
  description = "Ingress Class name"
  value       = var.enable_alb_controller ? module.aws_load_balancer_controller[0].ingress_class_name : null
}

# ============================================
# Verification Commands
# ============================================
output "alb_controller_verification_commands" {
  description = "Shell commands to verify AWS Load Balancer Controller (if enabled)"

  value = <<-EOT
  %{if var.enable_alb_controller}
  # ============================================
  # Verify AWS Load Balancer Controller
  # ============================================

  # 1. Verify Deployment
  kubectl -n kube-system get deployment aws-load-balancer-controller
  kubectl -n kube-system describe deployment aws-load-balancer-controller

  # 2. Verify Pods
  kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller

  # 3. Verify Service Account
  kubectl -n kube-system get sa aws-load-balancer-controller
  kubectl -n kube-system describe sa aws-load-balancer-controller

  # 4. Verify IAM Role Annotation
  kubectl -n kube-system get sa aws-load-balancer-controller \\
    -o jsonpath='{.metadata.annotations.eks\\.amazonaws\\.com/role-arn}'

  # 5. Verify Webhook Service
  kubectl -n kube-system get svc aws-load-balancer-webhook-service
  kubectl -n kube-system describe svc aws-load-balancer-webhook-service

  # 6. Verify Ingress Class
  kubectl get ingressclass
  kubectl describe ingressclass ${var.alb_controller_ingress_class_name}

  # 7. Check Controller Logs
  kubectl -n kube-system logs -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50

  # 8. Test with Sample Ingress (optional)
  cat <<EOF | kubectl apply -f -
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: test-ingress
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
  spec:
    ingressClassName: ${var.alb_controller_ingress_class_name}
    rules:
      - http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: test-service
                  port:
                    number: 80
  EOF

  kubectl get ingress test-ingress
  kubectl describe ingress test-ingress
  kubectl delete ingress test-ingress
  %{else}
  # AWS Load Balancer Controller is disabled (enable_alb_controller = false)
  %{endif}
  EOT
}
