
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
locals {
  name = "${var.environment}-${var.project_name}"

  common_tags = merge(
    var.tags,
    {
      Environment      = var.environment
      Project          = var.project_name
      BusinessDivision = var.development_division
      ManagedBy        = "Terraform"
      Layer            = "eks"
    }
  )

  # Network info from remote state
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
}

# ============================================
# EKS Cluster Module
# ============================================
module "eks_cluster" {
  source = "../../../modules/eks/cluster/"

  # General
  name            = local.name
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Network
  vpc_id             = local.vpc_id
  public_subnet_ids  = local.public_subnet_ids
  private_subnet_ids = local.private_subnet_ids

  # Cluster Configuration
  cluster_service_ipv4_cidr            = var.cluster_service_ipv4_cidr
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # OIDC Provider
  eks_oidc_root_ca_thumbprint = var.eks_oidc_root_ca_thumbprint

  # ============================================
  # Node Group Type Selection 
  # ============================================
  enable_public_node_group  = var.enable_public_node_group
  enable_private_node_group = var.enable_private_node_group

  # ============================================
  # Public Node Group Configuration 
  # ============================================
  public_node_group_name           = var.public_node_group_name
  public_node_group_desired_size   = var.public_node_group_desired_size
  public_node_group_min_size       = var.public_node_group_min_size
  public_node_group_max_size       = var.public_node_group_max_size
  public_node_group_instance_types = var.public_node_group_instance_types

  # ============================================
  # Private Node Group Configuration 
  # ============================================
  private_node_group_name           = var.private_node_group_name
  private_node_group_desired_size   = var.private_node_group_desired_size
  private_node_group_min_size       = var.private_node_group_min_size
  private_node_group_max_size       = var.private_node_group_max_size
  private_node_group_instance_types = var.private_node_group_instance_types

  # ============================================
  # Shared Node Group Configuration 
  # ============================================
  node_group_ami_type        = var.node_group_ami_type
  node_group_capacity_type   = var.node_group_capacity_type
  node_group_disk_size       = var.node_group_disk_size
  node_group_max_unavailable = var.node_group_max_unavailable
  node_group_keypair         = var.bastion_instance_keypair


  # Logging
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  cluster_log_retention_in_days = var.cluster_log_retention_in_days

  # Tags
  tags = local.common_tags
}

# ============================================
# Bastion Host Module
# ============================================
module "bastion" {
  source = "../../../modules/compute/bastion"
  count  = var.enable_bastion ? 1 : 0

  # General
  name = local.name

  # Network
  vpc_id           = local.vpc_id
  public_subnet_id = local.public_subnet_ids[0]

  # Instance Configuration
  instance_type    = var.bastion_instance_type
  instance_keypair = var.bastion_instance_keypair

  # Security
  ssh_cidr_blocks = var.bastion_ssh_cidr_blocks

  # Provisioning
  private_key_path = "private-key/${var.bastion_instance_keypair}.pem"

  # Tags
  tags = local.common_tags
}