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

실무 적용 예시 (거래소 아키텍처)
업비트와 같은 거래소는 수백 개의 마이크로서비스로 구성되지만, 외부에서 보는 진입점(Endpoint)은 몇 개로 정리됩니다.
그룹 이름 (Ingress Group),포함된 서비스 (Namespaces),설명
public-api-alb,"user-service, market-service, wallet-service",일반 사용자용 REST API. 단 하나의 ALB로 통합하여 api.upbit.com 도메인 연결.
internal-admin-alb,"admin-console, backoffice, monitoring",사내망에서만 접근 가능한 관리자 도구. VPN IP 대역만 허용.
socket-service-nlb,"order-book, ticker",(참고) 실시간 호가창은 ALB(L7)보다 속도가 빠른 NLB(L4)를 별도로 사용.

**Senior DevOps Engineer**로서 답변드립니다.

네, 실무에서는 그렇게 **도메인(Host)과 경로(Path)를 조합**하여 트래픽을 분기하는 것이 **Layer 7 라우팅의 정석**입니다.

현재 자네가 구축한 `eks-infrastructure` 구조는 **AWS ALB의 "Host-based Routing"과 "Path-based Routing"** 기능을 완벽하게 지원합니다.

업비트의 사례를 **Dev(개발) 환경**에 맞게 `playdevops.click` 도메인으로 매핑하여, \*\*"단 하나의 ALB"\*\*로 이 모든 라우팅을 처리하는 설정을 작성해 드리겠습니다. (비용 절감 및 관리 효율성)

---

### 🏛️ 아키텍처 전략: "One ALB, Multi-Host" (Virtual Hosting)

AWS ALB는 들어오는 요청의 \*\*Host 헤더(도메인)\*\*를 보고 1차로 거르고, 그 다음 \*\*Path(경로)\*\*를 보고 2차로 걸러서 적절한 파드(Pod)로 보낼 수 있습니다.

**[매핑 계획]**

1.  `datalab.upbit.com` → `datalab.playdevops.click`
2.  `upbit.com` → `www.playdevops.click` (메인)
3.  `custody.upbit.com` → `custody.playdevops.click`

---

### 📝 `dev.auto.tfvars` 상세 구현 (더블 체크 완료)

이 설정 하나면 **ALB 하나**가 위 3개 사이트와 그 하위 API들을 모두 완벽하게 라우팅합니다.

```hcl
# =============================================================================
# 공통 설정
# =============================================================================
# [핵심] 모든 서비스를 하나의 ALB로 묶습니다. (비용 절감)
ingress_group_name = "dev-integrated-alb-group"
load_balancer_name = "dev-integrated-alb"

# 인증서에는 이 모든 도메인이 포함되어야 함 (*.playdevops.click 와일드카드 추천)
acm_domain_name               = "*.playdevops.click"
acm_subject_alternative_names = ["playdevops.click"]

microservices = {

  # ===========================================================================
  # [Domain 1] Datalab (데이터 분석 서비스)
  # Host: datalab.playdevops.click
  # ===========================================================================

  # 1-1. Datalab API (Backend)
  "datalab-api" = {
    image             = "my-repo/datalab-api:v1.0"
    replicas          = 2
    container_port    = 8080
    service_port      = 80
    health_check_path = "/health"

    expose_external   = true
    ingress_hosts     = ["datalab.playdevops.click"] # [Host 조건]
    ingress_path      = "/v1"                        # [Path 조건]
    ingress_path_type = "Prefix"
    ingress_order     = 10 # API가 먼저 매칭되도록 우선순위 높음
    is_default        = false
  }

  # 1-2. Datalab Frontend (SPA)
  "datalab-web" = {
    image             = "my-repo/datalab-react:v2.0"
    replicas          = 2
    container_port    = 80
    service_port      = 80
    health_check_path = "/"

    expose_external   = true
    ingress_hosts     = ["datalab.playdevops.click"] # [Host 조건]
    ingress_path      = "/"                          # [Path 조건] 나머지 전부
    ingress_path_type = "Prefix"
    ingress_order     = 20 # API 매칭 실패 시 여기로 (Fallback)
    is_default        = false
  }


  # ===========================================================================
  # [Domain 2] Custody (수탁 서비스)
  # Host: custody.playdevops.click
  # ===========================================================================

  # 2-1. Custody Frontend (완전히 다른 React 앱)
  "custody-web" = {
    image             = "my-repo/custody-react:v1.5"
    replicas          = 1
    container_port    = 80
    service_port      = 80
    health_check_path = "/"

    expose_external   = true
    ingress_hosts     = ["custody.playdevops.click"] # [Host 조건] 도메인이 다름!
    ingress_path      = "/"
    ingress_path_type = "Prefix"
    ingress_order     = 30
    is_default        = false
  }


  # ===========================================================================
  # [Domain 3] Main Upbit (거래소 메인)
  # Host: www.playdevops.click
  # ===========================================================================

  # 3-1. Main Backend (User/Auth/Exchange API)
  "upbit-core-api" = {
    image             = "my-repo/upbit-core-api:v4.2"
    replicas          = 5
    container_port    = 8080
    service_port      = 80
    health_check_path = "/actuator/health"

    expose_external   = true
    ingress_hosts     = ["www.playdevops.click"]
    ingress_path      = "/api"  # /api 로 시작하는 건 백엔드로
    ingress_path_type = "Prefix"
    ingress_order     = 40
    is_default        = false
  }

  # 3-2. Main Frontend (SPA)
  # /trends, /exchange 등은 모두 여기서 처리됨 (Client-Side Routing)
  "upbit-web" = {
    image             = "my-repo/upbit-main-react:v3.1"
    replicas          = 3
    container_port    = 80
    service_port      = 80
    health_check_path = "/"

    expose_external   = true
    ingress_hosts     = ["www.playdevops.click"]
    ingress_path      = "/"
    ingress_path_type = "Prefix"
    ingress_order     = 50
    is_default        = true # Default Backend로 설정 (매칭 안되는 모든 요청 처리)
  }
}
```

---

### 🔍 상세 분석: 이 설정이 어떻게 동작하는가?

사용자가 요청을 보내면 ALB는 내부적으로 아래와 같은 \*\*논리 회로(Routing Table)\*\*를 거칩니다.

#### Case 1: `https://datalab.playdevops.click/v1/sector` 접속 시

1.  **ALB:** "Host 헤더가 `datalab.playdevops.click` 인 규칙을 보자."
2.  **규칙 1 (Order 10):** Path가 `/v1`으로 시작하나? -\> **YES**
3.  **Action:** `datalab-api` 파드로 트래픽 전송.
4.  **결과:** API 서버가 JSON 응답.

#### Case 2: `https://datalab.playdevops.click/sector` 접속 시

1.  **ALB:** "Host가 `datalab...`이다."
2.  **규칙 1 (Order 10):** Path가 `/v1`인가? -\> **NO** (`/sector`임)
3.  **규칙 2 (Order 20):** Path가 `/`인가? -\> **YES**
4.  **Action:** `datalab-web` 파드로 전송.
5.  **결과:** Nginx가 `index.html`을 주고, 브라우저에서 React가 `/sector` 화면을 그림.

#### Case 3: `https://www.playdevops.click/trends` 접속 시

1.  **ALB:** "Host가 `www.playdevops.click`이다."
2.  **규칙 3 (Order 40):** Path가 `/api`인가? -\> **NO** (`/trends`임)
3.  **규칙 4 (Order 50):** Path가 `/`인가? -\> **YES**
4.  **Action:** `upbit-web` 파드로 전송.
5.  **결과:** Nginx가 `index.html` 반환 -\> React Router가 "아, 트렌드 페이지네?" 하고 트렌드 화면 렌더링. (**별도 이미지가 필요 없습니다\!**)

#### Case 4: `https://custody.playdevops.click/` 접속 시

1.  **ALB:** "Host가 `custody...`다."
2.  **규칙 5 (Order 30):** Path가 `/`인가? -\> **YES**
3.  **Action:** `custody-web` (완전히 다른 React 앱)으로 전송.

---

### 🛡️ 더블 체크 (실무 팁)

1.  **Ingress Group 필수:** 위 모든 `microservices`가 하나의 `ingress_group_name`을 공유하고 있어야 합니다. 그래야 ALB 1개에 규칙(Rule)만 추가됩니다.
2.  **DNS 설정 (ExternalDNS):** ExternalDNS가 `ingress_hosts` 리스트를 보고 Route53에 `A 레코드`를 자동으로 생성해 줍니다. (`datalab`, `www`, `custody` 모두 동일한 ALB 주소를 가리키게 됨)
3.  **와일드카드 인증서:** 도메인이 여러 개(`*.playdevops.click`)이므로, ACM 인증서 하나로 모든 서브도메인을 커버해야 SSL 에러가 안 납니다.
4.  **Nginx SPA 설정:** 모든 `*-web` 서비스(React)의 Nginx 컨테이너에는 반드시 `try_files $uri /index.html;` 설정이 들어 있어야 `/trends`, `/exchange` 같은 경로 접속 시 404 에러가 안 납니다.

이 구성이 바로 **대규모 트래픽을 처리하는 금융권 서비스의 표준적인 인프라 라우팅 패턴**입니다. 현재 작성하신 테라폼 구조로 완벽하게 구현 가능합니다.
