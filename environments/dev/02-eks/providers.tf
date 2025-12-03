# ============================================
# AWS Provider
# ============================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}



# ============================================
# Kubernetes Provider  [To be Deleted]
# ============================================
# provider "kubernetes" {
#   host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
#   cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

# # ============================================
# # Helm Provider (Kubernetes 설정을 자동으로 사용)
# # ============================================
# provider "helm" {
#   kubernetes = {
#     host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
#     cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }