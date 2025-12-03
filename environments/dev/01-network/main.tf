
locals {
  name = "${var.environment}-${var.project_name}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      division    = var.division
      ManagedBy   = "Terraform"
      Layer       = "network"
    }
  )

  # EKS 태그 (클러스터 이름은 나중에 EKS에서 사용)
  eks_cluster_name = "${local.name}-eks"
}

# 2. Call the VPC module
module "vpc" {
  source = "../../../modules/networking/vpc"

  # General
  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  # Subnets
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  # NAT Gateway
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # EKS Cluster Name (for subnet tagging)
  eks_cluster_name = local.eks_cluster_name

  # Tags
  tags = local.common_tags
}