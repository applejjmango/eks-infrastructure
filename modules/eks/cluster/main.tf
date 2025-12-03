# ============================================
# EKS Cluster Module - Main Configuration
# ============================================
# 용도: EKS Control Plane만 관리 (Node Group은 별도 모듈로 분리)
# 리팩토링: Node Group 관련 코드 제거, Cluster + OIDC Provider만 관리

# ============================================
# Local Values
# ============================================
locals {
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
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  # VPC Configuration
  vpc_config {
    subnet_ids = concat(
      var.public_subnet_ids,
      var.private_subnet_ids
    )

    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  # Kubernetes Network Configuration
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # Control Plane Logging
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  # Dependencies
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.cluster,
  ]
}

# ============================================
# OIDC Provider for EKS
# ============================================
# 용도: IRSA (IAM Roles for Service Accounts) 지원
# Addons에서 Kubernetes Service Account에 IAM Role 연결시 필요

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-oidc-provider"
    }
  )
}