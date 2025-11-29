# ============================================
# Terraform Backend Configuration
# S3 Backend for Addons Layer State
# ============================================
terraform {
  backend "s3" {
    bucket       = "plydevops-infra-tf-dev"
    key          = "dev/03-addons/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
    # kms_key_id     = "arn:aws:kms:${var.region}:${var.account_id}:key/${var.kms_key_id}"
  }
}

