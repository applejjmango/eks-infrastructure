# ============================================
# AWS Load Balancer Controller Module
# ============================================
# 용도: ALB/NLB를 Kubernetes Ingress/Service와 통합
# 기능: IAM Policy, IAM Role (IRSA), Helm 설치, IngressClass 생성

# ============================================
# Data Source: LBC IAM Policy (최신 버전)
# ============================================
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

# ============================================
# IAM Policy for AWS Load Balancer Controller
# ============================================
resource "aws_iam_policy" "lbc" {
  name        = "${var.name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lbc_iam_policy.response_body

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name}-lbc-iam-policy"
    }
  )
}

# ============================================
# IAM Role for AWS Load Balancer Controller (IRSA)
# ============================================
resource "aws_iam_role" "lbc" {
  name = "${var.name}-lbc-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:aud" = "sts.amazonaws.com",
            "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      },
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name}-lbc-iam-role"
    }
  )
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}


# Data Source: EKS Cluster Details
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

# ============================================
# Data Source: EKS Cluster Auth
# ============================================
data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
}

# ============================================
# Helm Release: AWS Load Balancer Controller
# ============================================
resource "helm_release" "lbc" {
  depends_on = [aws_iam_role_policy_attachment.lbc]

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.helm_chart_version
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName  = var.eks_cluster_name
      vpcId        = var.vpc_id
      region       = var.aws_region
      replicaCount = var.replica_count

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.lbc.arn
        }
      }

      image = {
        repository = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
      }
    })
  ]
}

# ============================================
# Kubernetes IngressClass (Default)
# ============================================
resource "kubernetes_ingress_class_v1" "default" {
  depends_on = [helm_release.lbc]

  metadata {
    name = var.ingress_class_name
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = var.is_default_class ? "true" : "false"
    }
    labels = merge(
      var.common_tags,
      {
        "app.kubernetes.io/name"       = "aws-load-balancer-controller"
        "app.kubernetes.io/managed-by" = "Terraform"
      }
    )
  }

  spec {
    controller = "ingress.k8s.aws/alb"
  }
}