## Node Group 전환 가이드

### 시나리오 1: Public Node Group으로 전환 (개발/테스트)

```bash
# dev.auto.tfvars 수정
enable_public_node_group  = true
enable_private_node_group = false

# outputs.tf 주석 전환
# Public outputs 주석 해제
# Private outputs 주석 처리

# Apply
terraform plan
terraform apply -auto-approve
```

### 시나리오 2: Private Node Group으로 전환 (프로덕션)

```bash
# dev.auto.tfvars 수정
enable_public_node_group  = false
enable_private_node_group = true

# outputs.tf 주석 전환
# Public outputs 주석 처리
# Private outputs 주석 해제

# Apply
terraform plan
terraform apply -auto-approve
```

### 실무 권장사항

**Dev 환경**

- Public Node Group: 테스트/디버깅 용이
- 비용 절감: desired_size = 1

**Staging/Prod 환경**

- Private Node Group: 보안 강화
- HA: desired_size = 2+, Multi-AZ
