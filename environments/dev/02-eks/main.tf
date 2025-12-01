# ============================================
# EKS Layer - Main Configuration
# ============================================
# 리팩토링: Cluster와 Node Group을 별도 모듈로 분리
# 장점: 독립적 관리, 작은 Blast Radius, 유연한 Node Group 추가/삭제

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
# 1️⃣ EKS Cluster Module (Control Plane Only)
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

  # Logging
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  cluster_log_retention_in_days = var.cluster_log_retention_in_days

  # Tags
  tags = local.common_tags
}

# ============================================
# 2️⃣ Public Node Group (선택적 - 개발/테스트 용도)
# ============================================
module "node_group_public" {
  source = "../../../modules/eks/node-group/"
  count  = var.enable_public_node_group ? 1 : 0

  # Cluster Information (from cluster module)
  cluster_name    = module.eks_cluster.cluster_name
  cluster_version = module.eks_cluster.cluster_version

  # Node Group Configuration
  name            = local.name
  node_group_name = var.public_node_group_name
  node_group_type = "public"
  subnet_ids      = local.public_subnet_ids

  # Scaling
  desired_size = var.public_node_group_desired_size
  min_size     = var.public_node_group_min_size
  max_size     = var.public_node_group_max_size

  # Instance Configuration
  instance_types = var.public_node_group_instance_types
  capacity_type  = var.node_group_capacity_type
  ami_type       = var.node_group_ami_type
  disk_size      = var.node_group_disk_size

  # Update Configuration
  max_unavailable_percentage = var.node_group_max_unavailable

  # SSH Access
  ssh_key_name = var.bastion_instance_keypair

  # Features
  enable_ssm        = true
  enable_cloudwatch = true

  # Kubernetes Labels
  kubernetes_labels = {
    Environment  = var.environment
    WorkloadType = "general"
  }

  # Tags
  common_tags = local.common_tags

  # Dependency
  depends_on = [module.eks_cluster]
}

# ============================================
# 3️⃣ Private Node Group (권장 - Production 용도)
# ============================================
module "node_group_private" {
  source = "../../../modules/eks/node-group/"
  count  = var.enable_private_node_group ? 1 : 0

  # Cluster Information (from cluster module)
  cluster_name    = module.eks_cluster.cluster_name
  cluster_version = module.eks_cluster.cluster_version

  # Node Group Configuration
  name            = local.name
  node_group_name = var.private_node_group_name
  node_group_type = "private"
  subnet_ids      = local.private_subnet_ids

  # Scaling
  desired_size = var.private_node_group_desired_size
  min_size     = var.private_node_group_min_size
  max_size     = var.private_node_group_max_size

  # Instance Configuration
  instance_types = var.private_node_group_instance_types
  capacity_type  = var.node_group_capacity_type
  ami_type       = var.node_group_ami_type
  disk_size      = var.node_group_disk_size

  # Update Configuration
  max_unavailable_percentage = var.node_group_max_unavailable

  # SSH Access (Bastion을 통해서만)
  ssh_key_name                  = var.bastion_instance_keypair
  ssh_source_security_group_ids = var.enable_bastion ? [module.bastion[0].security_group_id] : []

  # Features
  enable_ssm        = true
  enable_cloudwatch = true

  # Kubernetes Labels
  kubernetes_labels = {
    Environment  = var.environment
    WorkloadType = "general"
  }

  # Tags
  common_tags = local.common_tags

  # Dependency
  depends_on = [module.eks_cluster]
}

# ============================================
# 4️⃣ Bastion Host Module (선택적)
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