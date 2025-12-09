# (Root Module) Dev Addons - Main

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
# environments/dev/03-platform/main.tf (라인 32-46)
locals {
  name             = "${var.environment}-${var.project_name}"
  eks_cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id

  # 태그 정규화: 공백을 하이픈으로 변환 후 기본 태그와 병합
  common_tags = merge(
    { for key, value in var.tags : key => replace(value, " ", "-") },
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Layer       = "platform"
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
  aws_region       = var.aws_region

  # OIDC Provider
  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Helm Chart
  helm_chart_version = var.alb_controller_chart_version

  # Image Repository: Use ecr_account_id instead of the full path
  ecr_account_id = split(".", var.alb_controller_image_repository)[0] # Extracting ECR Account ID


  # Ingress Class
  ingress_class_name = var.alb_controller_ingress_class_name
  is_default_class   = var.alb_controller_is_default

  common_tags = local.common_tags
}

# ============================================
# External DNS (with IRSA)
# ============================================
module "external_dns" {
  source = "../../../modules/addons/external-dns"
  count  = var.enable_external_dns ? 1 : 0

  cluster_name = local.eks_cluster_name
  aws_region   = var.aws_region

  oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # [수정 완료] 통합된 hosted_zone_id 변수 사용
  hosted_zone_id = var.hosted_zone_id
  domain_filters = var.external_dns_domain_filters

  namespace     = "kube-system"
  chart_version = var.external_dns_chart_version

  tags = local.common_tags
}



# ============================================
# [NEW] ACM Certificate (Platform Shared)
# ============================================
module "acm" {
  source = "../../../modules/security/acm"

  # Apex(루트) 도메인을 메인으로 설정 (예: playdevops.click)
  domain_name = var.acm_domain_name

  # 와일드카드를 SANs에 자동 추가 (예: *.playdevops.click)
  subject_alternative_names = [
    "*.${var.acm_domain_name}"
  ]

  hosted_zone_id = var.hosted_zone_id
  tags           = local.common_tags
}
/*
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