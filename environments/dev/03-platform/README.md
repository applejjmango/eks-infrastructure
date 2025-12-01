# ============================================

# Prerequisites Check

# ============================================

# Step 1: 사전 확인

### 1. Network Layer 확인

cd eks-infrastructure/environments/dev/01-network
terraform output vpc_id

### 2. EKS Layer 확인

cd ../02-eks
terraform output cluster_name
terraform output oidc_provider_arn

### 3. kubectl 설정

aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region us-east-1

### 4. 현재 Add-ons 확인

aws eks list-addons --cluster-name $(terraform output -raw cluster_name)

# Step 2: EBS CSI Driver 배포

# ============================================

# Deploy EBS CSI Driver

# ============================================

cd eks-infrastructure/environments/dev/03-addons

# Initialize

terraform init

# Validate

terraform validate

# Format

terraform fmt -recursive

# Plan

terraform plan

# Apply

terraform apply -auto-approve

# Outputs 확인

terraform output

# Step 3: 검증

# ============================================

# Verification

# ============================================

# 1. EKS Add-on 상태 확인

aws eks describe-addon \
 --cluster-name dev-playdevops-eks \
 --addon-name aws-ebs-csi-driver \
 --query 'addon.{Status:status,Version:addonVersion,Health:health}' \
 --output table

# Expected Output:

---

| DescribeAddon |
+---------+----------------------+
| Status | Version |
+---------+----------------------+
| ACTIVE | v1.53.0-eksbuild.1 |
+---------+----------------------+
|| Health ||
|+------------------------------+

# 2. Kubernetes Pods 확인

kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-ebs-csi-driver

# Expected Output:

# NAME READY STATUS RESTARTS AGE

# ebs-csi-controller-xxx-xxx 6/6 Running 0 2m

# ebs-csi-controller-xxx-yyy 6/6 Running 0 2m

# ebs-csi-node-xxx 3/3 Running 0 2m

# ebs-csi-node-yyy 3/3 Running 0 2m

# 3. Service Account 확인

kubectl -n kube-system describe sa ebs-csi-controller-sa

# Expected Output:

Name: ebs-csi-controller-sa
Namespace: kube-system
Labels: app.kubernetes.io/component=csi-driver
app.kubernetes.io/managed-by=EKS
app.kubernetes.io/name=aws-ebs-csi-driver
app.kubernetes.io/version=1.53.0
Annotations: eks.amazonaws.com/role-arn: arn:aws:iam::346135039532:role/dev-playdevops-ebs-csi-driver-ebs-csi-driver-role
Image pull secrets: <none>
Mountable secrets: <none>
Tokens: <none>
Events: <none>

# 4. IAM Role Annotation 확인

kubectl -n kube-system get sa ebs-csi-controller-sa \
 -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'

# Expected Output:

# arn:aws:iam::346135039532:role/dev-playdevops-ebs-csi-driver-ebs-csi-driver-role

# 5. Storage Class 확인

kubectl get storageclass

# Expected Output:

# NAME PROVISIONER RECLAIMPOLICY VOLUMEBINDINGMODE ALLOWVOLUMEEXPANSION AGE

# gp2 (default) kubernetes.io/aws-ebs Delete WaitForFirstConsumer false 10d

# gp3 ebs.csi.aws.com Delete WaitForFirstConsumer true 2m

5️⃣ 트러블슈팅
문제 1: Add-on이 DEGRADED 상태
bash# 상세 로그 확인
kubectl -n kube-system logs -l app=ebs-csi-controller

# Controller Pod 상태 확인

kubectl -n kube-system describe pod -l app=ebs-csi-controller

# IAM Role 확인

aws iam get-role --role-name dev-myapp-ebs-csi-driver-role
문제 2: PVC가 Pending 상태
bash# PVC 이벤트 확인
kubectl describe pvc test-ebs-pvc

# CSI Driver 로그

kubectl -n kube-system logs -l app=ebs-csi-controller -c csi-provisioner

# 일반적인 원인:

# 1. Pod가 없어서 WaitForFirstConsumer

# 2. IAM 권한 부족

# 3. 가용 영역 불일치

문제 3: IAM 권한 오류
bash# Service Account 확인
kubectl -n kube-system get sa ebs-csi-controller-sa -o yaml

# IAM Role Policy 확인

aws iam list-attached-role-policies \
 --role-name dev-myapp-ebs-csi-driver-role

# OIDC 연결 확인

aws iam get-role --role-name dev-myapp-ebs-csi-driver-role \
 --query 'Role.AssumeRolePolicyDocument'

6️⃣ 버전 업그레이드
bash# ============================================

# Upgrade EBS CSI Driver

# ============================================

# 1. 사용 가능한 버전 확인

aws eks describe-addon-versions \
 --addon-name aws-ebs-csi-driver \
 --kubernetes-version 1.31 \
 --query 'addons[0].addonVersions[].addonVersion' \
 --output table

# 2. dev.auto.tfvars 수정

ebs_csi_driver_addon_version = "v1.28.0-eksbuild.1"

# 3. Apply

terraform plan
terraform apply -auto-approve

# 4. 확인

kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-ebs-csi-driver

7️⃣ Cleanup
bash# ============================================

# Remove EBS CSI Driver

# ============================================

# 1. 테스트 리소스 삭제

kubectl delete pod test-ebs-pod
kubectl delete pvc test-ebs-pvc

# 2. Terraform Destroy

cd environments/dev/03-addons
terraform destroy -auto-approve

# 3. Verify

aws eks list-addons --cluster-name dev-myapp-eks

1. Ingress 리소스 생성
   ↓
2. AWS LB Controller가 Ingress Spec 감지
   ↓
3. Service Account의 IAM Role로 AWS API 호출
   ↓
4. ALB/NLB, Target Group, Listener Rule 생성
   ↓
5. Pod IP를 Target Group에 등록
   ↓
6. 트래픽 라우팅 시작
