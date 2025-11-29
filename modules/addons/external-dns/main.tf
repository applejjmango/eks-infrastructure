# 1. IRSA Role for ExternalDNS
resource "aws_iam_role" "external_dns" {
  name = "${var.cluster_name}-external-dns"
  tags = var.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${replace(var.oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
          "${replace(var.oidc_issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# 2. Inline IAM Policy for Route 53
resource "aws_iam_policy" "external_dns" {
  name   = "${var.cluster_name}-external-dns-policy"
  policy = data.aws_iam_policy_document.external_dns.json
  tags   = var.common_tags
}

# 3. Attach Policy
resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}

# 4. Deploy Helm Chart
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = var.chart_version
  wait       = true

  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }
  
  # Provider settings
  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "aws.zoneType"
    value = "public"
  }
  set {
    name  = "zoneIdFilters[0]"
    value = var.hosted_zone_id
  }
  set {
    name  = "domainFilters[0]"
    value = var.domain_filter
  }
  set {
    name = "policy"
    value = "upsert-only" # (Safe) Only create/update, never delete
  }

  depends_on = [ aws_iam_role_policy_attachment.external_dns ]
}

# --- IAM Policy Document ---
data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "AllowRoute53List"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowRoute53Change"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    # (Security) Only allow changes to the specified Hosted Zone
    resources = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]
  }
}