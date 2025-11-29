# ============================================
# IRSA Module - Generic Implementation
# 모든 EKS Add-ons에서 사용 가능
# ============================================

# ============================================
# IAM Policy Document
# ============================================
data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.iam_policy_statements

    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# ============================================
# IAM Policy
# ============================================
resource "aws_iam_policy" "this" {
  name        = "${var.name}-policy"
  path        = "/"
  description = "IAM Policy for ${var.name}"
  policy      = data.aws_iam_policy_document.this.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-policy"
    }
  )
}

# ============================================
# IAM Role for IRSA
# ============================================
resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${var.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-role"
    }
  )
}

# ============================================
# Attach Policy to Role
# ============================================
resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

# ============================================
# Kubernetes Service Account (Optional)
# ============================================
resource "kubernetes_service_account_v1" "this" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
  }
}