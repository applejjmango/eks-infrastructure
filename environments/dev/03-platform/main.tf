# (Root Module) Dev Addons - Main

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

# ============================================
# EBS CSI Driver (with IRSA)
# ============================================
module "ebs_csi_driver" {
  source = "../../../modules/addons/ebs-csi-driver"
  count  = var.enable_ebs_csi_driver ? 1 : 0

  name             = "${local.name}-ebs-csi-driver"
  eks_cluster_name = local.eks_cluster_name

  # OIDC Provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Add-on Configuration
  addon_version               = var.ebs_csi_driver_addon_version
  resolve_conflicts_on_create = var.ebs_csi_driver_resolve_conflicts_on_create

  # IAM Policy
  use_aws_managed_policy = var.ebs_csi_driver_use_aws_managed_policy

  # Service Account
  service_account_name = "ebs-csi-controller-sa"
  namespace            = "kube-system"

  # Helm Chart (only when run by HELM)
  #chart_version = var.ebs_csi_driver_chart_version

  tags = local.common_tags
}

/*
# ============================================
# External DNS (with IRSA)
# ============================================
module "external_dns" {
  source = "../../../modules/addons/external-dns"
  count  = var.enable_external_dns ? 1 : 0

  name             = "${local.name}-external-dns"
  eks_cluster_name = local.eks_cluster_name

  # OIDC Provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Route53
  hosted_zone_id = var.external_dns_hosted_zone_id
  domain_filters = var.external_dns_domain_filters

  # Helm Chart
  chart_version = var.external_dns_chart_version

  tags = local.common_tags
}

# ============================================
# AWS Load Balancer Controller (with IRSA)
# ============================================
module "aws_load_balancer_controller" {
  source = "../../../modules/addons/aws-load-balancer-controller"
  count  = var.enable_alb_controller ? 1 : 0

  name             = "${local.name}-alb-controller"
  eks_cluster_name = local.eks_cluster_name
  vpc_id           = local.vpc_id

  # OIDC Provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Helm Chart
  chart_version = var.alb_controller_chart_version

  tags = local.common_tags
}

# ============================================
# Cert Manager (with IRSA)
# ============================================
module "cert_manager" {
  source = "../../../modules/addons/cert-manager"
  count  = var.enable_cert_manager ? 1 : 0

  name             = "${local.name}-cert-manager"
  eks_cluster_name = local.eks_cluster_name

  # OIDC Provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Route53 for DNS-01 challenge
  hosted_zone_id = var.cert_manager_hosted_zone_id

  # Helm Chart
  chart_version = var.cert_manager_chart_version

  # Let's Encrypt
  acme_email  = var.cert_manager_acme_email
  acme_server = var.cert_manager_acme_server

  tags = local.common_tags
}

# ============================================
# Cluster Autoscaler (with IRSA)
# ============================================
module "cluster_autoscaler" {
  source = "../../../modules/addons/cluster-autoscaler"
  count  = var.enable_cluster_autoscaler ? 1 : 0

  name             = "${local.name}-cluster-autoscaler"
  eks_cluster_name = local.eks_cluster_name

  # OIDC Provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Helm Chart
  chart_version = var.cluster_autoscaler_chart_version

  tags = local.common_tags
}


*/