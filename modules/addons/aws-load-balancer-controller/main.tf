# ============================================
# AWS Load Balancer Controller Module
# ============================================

# ============================================
# 1. IAM Policy (LBC 고유 정책)
# ============================================
# 최신 IAM Policy 다운로드 (또는 로컬 파일 사용 권장)
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

# 정책 생성
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
# 2. IRSA Role (모듈 호출로 대체!)
# ============================================
module "irsa_role" {
  source = "../../iam/irsa" # 공통 IRSA 모듈 경로

  name = "${var.name}-lbc-iam-role"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider     = var.oidc_provider

  # LBC는 kube-system 네임스페이스 사용
  namespace            = var.namespace
  service_account_name = var.service_account_name

  # Service Account는 Helm Chart가 만들도록 설정할 것이므로, 
  # IRSA 모듈에서는 SA 생성 안 함 (create_service_account = false)
  create_service_account = false

  # 정책은 별도로 만들어서 붙일 것이므로 빈 리스트 전달
  iam_policy_statements = []

  tags = var.common_tags
}

# ============================================
# 3. Policy Attachment (Role <-> Policy 연결)
# ============================================
resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = module.irsa_role.iam_role_name # 모듈 Output 사용
}

# ============================================
# 4. Helm Release (LBC 배포)
# ============================================
resource "helm_release" "lbc" {
  # Role 생성 후 배포
  depends_on = [aws_iam_role_policy_attachment.lbc]

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.helm_chart_version
  namespace  = var.namespace

  # Modern Terraform Style (yamlencode)
  values = [
    yamlencode({
      clusterName  = var.eks_cluster_name
      vpcId        = var.vpc_id
      region       = var.aws_region
      replicaCount = var.replica_count

      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          # 모듈에서 생성된 Role ARN 주입
          "eks.amazonaws.com/role-arn" = module.irsa_role.iam_role_arn
        }
      }

      image = {
        repository = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
      }

      # IngressClass 설정 (기존 로직 유지)
      ingressClass = var.ingress_class_name
      ingressClassConfig = {
        default = var.is_default_class
      }
      createIngressClassResource = true

      # (선택) WAF/Shield 기능 활성화
      enableWaf    = var.enable_waf
      enableWafv2  = var.enable_wafv2
      enableShield = var.enable_shield
    })
  ]
}