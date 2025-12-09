[TO-DO]

1. Public ALB → Private ALB + API Gateway

# EKS Infrastructure Project (Terraform)

This repository contains Terraform code to build and manage a production-ready EKS (Elastic Kubernetes Service) cluster on AWS.

## 🚀 Project Structure

- **`.github/workflows`**: CI/CD pipelines (Terraform Plan/Apply).
- **`modules/`**: Reusable infrastructure "Blueprints" (VPC, EKS Cluster, Node Groups, Addons).
- **`environments/`**: Environment-specific "Root Modules" (dev, staging, prod) where `terraform apply` is executed.

## 🏛️ Architecture: Layers

The infrastructure is split into independent layers to manage blast radius and dependencies:

1.  **`01-network`**: The foundational network (VPC, Subnets, NAT, Endpoints).
2.  **`02-eks`**: The EKS Control Plane, Node Groups, and IAM/RBAC settings.
3.  **`03-addons`**: Core Kubernetes addons (e.g., `aws-load-balancer-controller`, `ebs-csi-driver`, `cluster-autoscaler`).

## 🛠️ Usage

### Prerequisites

- Terraform v1.5.0+
- AWS Account with credentials
- S3 Bucket and DynamoDB Table for Terraform remote state.

### Deployment (Example: `dev` environment)

**Warning:** Layers must be deployed in order.

```bash
# 1. Deploy Network
cd environments/dev/01-network
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply -auto-approve -out=tfplan
terraform destroy -auto-approve

# 2. Deploy EKS
cd ../02-eks
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars" -auto-approve

# 3. Deploy Addons
cd ../03-addons
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars" -auto-approve
```

Git에 올리는 것

✅ Terraform 코드
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── backend.tf

✅ 변수 파일
├── dev.auto.tfvars
├── staging.auto.tfvars
└── prod.auto.tfvars (민감 정보 제외)

✅ 문서
├── README.md
└── CHANGELOG.md

✅ CI/CD 설정
├── .github/workflows/terraform.yml
└── .gitlab-ci.yml

✅ 기타
├── .gitignore
└── .terraform.lock.hcl (의존성 고정)

❌ Git에 절대 안 올리는 것

❌ Plan 파일
├── tfplan
├── dev.tfplan
└── \*.tfplan

❌ State 파일
├── terraform.tfstate
├── terraform.tfstate.backup
└── _.tfstate_

❌ Terraform 캐시
├── .terraform/
└── .terraform.lock.hcl (경우에 따라)

❌ 민감 정보
├── _.pem
├── _.key
├── secrets.tfvars
└── 환경 변수에 들어갈 비밀번호

❌ 로그 파일
├── crash.log
└── \*.log

📋 사용법 요약
명령어 설명순서
./scripts/apply.sh dev - 전체 배포 01→02→03→04
./scripts/destroy.sh dev - 전체 삭제 04→03→02→01

AWS Organization
├── Shared Account (ECR, ArgoCD)
├── Dev Account (EKS Dev Cluster)
└── Prod Account (EKS Prod Cluster)
├── VPC (Private Subnet Only for Nodes)
│ ├── Node Group [General]: Web, App
│ ├── Node Group [Core]: Order, Wallet (Tainted)
│ └── Node Group [System]: Logging, Ingress
│
├── Network
│ ├── Public ALB (WAF) -> User Traffic
│ └── Private ALB (VPN) -> Admin Traffic
│
└── Security
├── IAM Roles for Service Accounts (IRSA)
├── Secrets Manager + External Secrets
└── Network Policies (Deny-All by default)
