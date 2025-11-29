# (Root Module) Dev Network - Backend
# (Important) State file is isolated by environment and layer
terraform {
  backend "s3" {
    bucket       = "plydevops-infra-tf-dev"           # bucket = "{org}-{team}-tf-{env}"
    key          = "dev/01-network/terraform.tfstate" # key = "{environment}/{layer}/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}