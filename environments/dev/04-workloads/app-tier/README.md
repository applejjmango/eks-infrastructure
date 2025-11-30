3. 배포 가이드
   배포 순서

# 1. 디렉토리 이동

cd environments/dev/04-workloads/app-tier/

# 2. Terraform 초기화

terraform init

# 3. 배포 계획 확인 (중요!)

# 실무: 반드시 plan으로 변경 사항 검토

terraform plan -out=tfplan

# 4. 배포 실행

terraform apply tfplan

# 5. 배포 확인

kubectl get pods -n default -l app=playdevops-webapp
kubectl get svc -n default
kubectl get pvc -n default

배포 후 검증
bash# Pod 상태 확인
kubectl get pods -n default -l app=playdevops-webapp -w

# Service LoadBalancer 주소 확인

kubectl get svc playdevops-webapp -n default

# LoadBalancer URL 확인

LB_URL=$(kubectl get svc playdevops-webapp -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$LB_URL"

# 애플리케이션 접속 테스트

curl http://$LB_URL

# PVC 상태 확인

kubectl get pvc -n default
kubectl describe pvc playdevops-webapp-pvc -n default

# Pod 로그 확인

kubectl logs -n default -l app=playdevops-webapp --tail=50

```

---

## 시니어의 핵심 조언

### **1. 모듈 구조 원칙**
```

✅ 올바른 구조:
modules/kubernetes/
├── app/ # Deployment (Stateless)
├── statefulset/ # StatefulSet (Stateful DB)
├── cronjob/ # CronJob (배치 작업)
└── daemonset/ # DaemonSet (노드별 에이전트)

각 모듈:
├── main.tf
├── variables.tf
└── outputs.tf

### **2. 확장성 고려사항**

```

현재: app/ 모듈만 생성
향후:

- statefulset/ (MySQL, Redis 등)
- cronjob/ (배치 작업)
- daemonset/ (로그 수집기 등)
- job/ (일회성 작업)

```
