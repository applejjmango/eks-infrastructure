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
