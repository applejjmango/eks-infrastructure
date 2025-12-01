# ============================================
# EKS Cluster Module - Main Configuration
# ============================================

# ============================================
# Local Values
# ============================================
locals {
  node_group_subnet_ids = length(var.node_group_subnet_ids) > 0 ? var.node_group_subnet_ids : var.public_subnet_ids

  # Extract OIDC provider from ARN
  oidc_provider = replace(aws_iam_openid_connect_provider.cluster.arn, "/^(.*provider/)/", "")
}

# ============================================
# Data Sources
# ============================================
data "aws_partition" "current" {}

# ============================================
# CloudWatch Log Group for EKS Cluster
# ============================================
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-logs"
    }
  )
}

# ============================================
# IAM Role for EKS Cluster
# ============================================
resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-cluster-role"
    }
  )
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ============================================
# EKS Cluster
# ============================================
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.cluster
  ]

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# ============================================
# OIDC Provider for IRSA
# ============================================
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
  thumbprint_list = [var.eks_oidc_root_ca_thumbprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-irsa"
    }
  )
}

# ============================================
# IAM Role for Node Group
# ============================================
resource "aws_iam_role" "node_group" {
  name = "${var.name}-eks-nodegroup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-nodegroup-role"
    }
  )
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# CloudWatch Agent for Container Insights
resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group.name
}

# ============================================
# EKS Node Group
# ============================================
# 실무 Note: Public Node Group은 개발/테스트 환경에서만 사용
# Production에서는 보안을 위해 Private Node Group만 사용
resource "aws_eks_node_group" "public" {
  count = var.enable_public_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.name}-${var.public_node_group_name}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.public_subnet_ids
  version         = var.cluster_version

  # Instance Configuration
  ami_type       = var.node_group_ami_type
  capacity_type  = var.node_group_capacity_type
  disk_size      = var.node_group_disk_size
  instance_types = var.public_node_group_instance_types

  # Scaling Configuration
  scaling_config {
    desired_size = var.public_node_group_desired_size
    min_size     = var.public_node_group_min_size
    max_size     = var.public_node_group_max_size
  }

  # Update Configuration

  update_config {
    max_unavailable = var.node_group_max_unavailable
  }

  # SSH Access (Public Node Group only)

  remote_access {
    ec2_ssh_key               = var.node_group_keypair
    source_security_group_ids = [] # 필요시 Bastion SG 추가
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    # aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore,
  ]

  tags = merge(
    var.tags,
    {
      Name                                            = "${var.name}-public-node-group"
      Type                                            = "Public"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# ============================================
# EKS Node Group - PRIVATE (REFACTORED)
# ============================================
# 실무 Best Practice: Private 서브넷에 배치 → ALB가 Public에서 트래픽 전달
resource "aws_eks_node_group" "private" {
  count = var.enable_private_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.name}-${var.private_node_group_name}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids # Private 서브넷
  version         = var.cluster_version

  # Instance Configuration
  ami_type       = var.node_group_ami_type
  capacity_type  = var.node_group_capacity_type
  disk_size      = var.node_group_disk_size
  instance_types = var.private_node_group_instance_types

  # Scaling Configuration
  scaling_config {
    desired_size = var.private_node_group_desired_size
    min_size     = var.private_node_group_min_size
    max_size     = var.private_node_group_max_size
  }

  # Update Configuration
  update_config {
    max_unavailable = var.node_group_max_unavailable
  }

  # SSH Access (Private - Bastion을 통해서만)
  remote_access {
    ec2_ssh_key               = var.node_group_keypair
    source_security_group_ids = [] # Bastion SG 추가 권장
  }

  # Dependencies
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-node-group"
      Type = "Private"
      # Cluster Autoscaler용 태그
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}