#!/usr/bin/env bash
# =============================================================================
# deploy.sh - EKS Infrastructure 자동 배포 스크립트
# =============================================================================
# 용도: Terraform 레이어별 순차 배포/삭제 자동화
# 사용법: ./scripts/deploy.sh [apply|destroy|plan] [환경] [옵션]
#
# 실무 관점:
#   - 레이어 의존성 순서 보장 (Network → EKS → Platform → Workloads)
#   - 삭제 시 역순 보장 (Workloads → Platform → EKS → Network)
#   - 각 단계 실패 시 즉시 중단 (set -e)
#   - 상세 로깅 및 색상 출력
# =============================================================================

set -euo pipefail

# =============================================================================
# 설정
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 기본값
DEFAULT_ENV="dev"
DRY_RUN=false
SKIP_CONFIRM=false
VERBOSE=false
TARGET_LAYER=""

# 레이어 정의 (순서 중요!)
declare -a LAYERS=(
    "01-network"
    "02-eks"
    "03-platform"
    "04-workloads/app-tier"
)

# =============================================================================
# 유틸리티 함수
# =============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_step() {
    echo -e "\n${CYAN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════${NC}\n"
}

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║     ███████╗██╗  ██╗███████╗    ██████╗ ███████╗██████╗       ║"
    echo "║     ██╔════╝██║ ██╔╝██╔════╝    ██╔══██╗██╔════╝██╔══██╗      ║"
    echo "║     █████╗  █████╔╝ ███████╗    ██║  ██║█████╗  ██████╔╝      ║"
    echo "║     ██╔══╝  ██╔═██╗ ╚════██║    ██║  ██║██╔══╝  ██╔═══╝       ║"
    echo "║     ███████╗██║  ██╗███████║    ██████╔╝███████╗██║           ║"
    echo "║     ╚══════╝╚═╝  ╚═╝╚══════╝    ╚═════╝ ╚══════╝╚═╝           ║"
    echo "║                                                               ║"
    echo "║            Infrastructure Deployment Automation               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

usage() {
    cat << EOF
${BOLD}사용법:${NC}
    $(basename "$0") <command> [environment] [options]

${BOLD}Commands:${NC}
    apply       전체 인프라 배포 (01→02→03→04 순서)
    destroy     전체 인프라 삭제 (04→03→02→01 순서)
    plan        전체 인프라 Plan 확인 (배포 없음)
    status      각 레이어 상태 확인

${BOLD}Environment:${NC}
    dev         개발 환경 (기본값)
    staging     스테이징 환경
    prod        프로덕션 환경

${BOLD}Options:${NC}
    -l, --layer LAYER    특정 레이어만 실행 (예: 01-network, 02-eks)
    -y, --yes            확인 프롬프트 건너뛰기
    -d, --dry-run        실제 실행 없이 명령어만 출력
    -v, --verbose        상세 로그 출력
    -h, --help           도움말 출력

${BOLD}Examples:${NC}
    # 개발 환경 전체 배포
    $(basename "$0") apply dev

    # 프로덕션 환경 전체 삭제 (확인 프롬프트 포함)
    $(basename "$0") destroy prod

    # 특정 레이어만 배포
    $(basename "$0") apply dev --layer 02-eks

    # Dry-run 모드로 Plan 확인
    $(basename "$0") plan dev --dry-run

    # 확인 없이 삭제 (CI/CD용)
    $(basename "$0") destroy dev --yes

${BOLD}Layer 순서:${NC}
    배포(apply):  01-network → 02-eks → 03-platform → 04-workloads/app-tier
    삭제(destroy): 04-workloads/app-tier → 03-platform → 02-eks → 01-network

EOF
}

# =============================================================================
# 인자 파싱
# =============================================================================
parse_args() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi

    COMMAND="$1"
    shift

    # 환경 설정 (두 번째 인자가 옵션이 아니면 환경으로 처리)
    if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
        ENVIRONMENT="$1"
        shift
    else
        ENVIRONMENT="${DEFAULT_ENV}"
    fi

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--layer)
                TARGET_LAYER="$2"
                shift 2
                ;;
            -y|--yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                usage
                exit 1
                ;;
        esac
    done

    # 명령어 유효성 검사
    case "${COMMAND}" in
        apply|destroy|plan|status)
            ;;
        *)
            log_error "알 수 없는 명령어: ${COMMAND}"
            usage
            exit 1
            ;;
    esac

    # 환경 유효성 검사
    ENV_DIR="${PROJECT_ROOT}/environments/${ENVIRONMENT}"
    if [[ ! -d "${ENV_DIR}" ]]; then
        log_error "환경 디렉토리가 존재하지 않습니다: ${ENV_DIR}"
        exit 1
    fi
}

# =============================================================================
# Terraform 실행 함수
# =============================================================================
run_terraform() {
    local layer_path="$1"
    local action="$2"
    local layer_name=$(basename "${layer_path}")
    
    log_step "Layer: ${layer_name} - ${action^^}"
    
    cd "${layer_path}"
    
    if [[ "${DRY_RUN}" == true ]]; then
        log_warn "[DRY-RUN] 다음 명령어가 실행될 예정입니다:"
        echo "  cd ${layer_path}"
        echo "  terraform init -input=false"
        echo "  terraform fmt -recursive"
        echo "  terraform validate"
        if [[ "${action}" == "apply" ]]; then
            echo "  terraform plan -out=tfplan"
            echo "  terraform apply -auto-approve tfplan"
        elif [[ "${action}" == "destroy" ]]; then
            echo "  terraform destroy -auto-approve"
        elif [[ "${action}" == "plan" ]]; then
            echo "  terraform plan"
        fi
        return 0
    fi

    # Terraform Init
    log_info "terraform init 실행 중..."
    if ! terraform init -input=false -upgrade; then
        log_error "terraform init 실패: ${layer_name}"
        return 1
    fi

    # Terraform Format
    log_info "terraform fmt 실행 중..."
    terraform fmt -recursive

    # Terraform Validate
    log_info "terraform validate 실행 중..."
    if ! terraform validate; then
        log_error "terraform validate 실패: ${layer_name}"
        return 1
    fi

    case "${action}" in
        apply)
            log_info "terraform plan 실행 중..."
            if ! terraform plan -out=tfplan; then
                log_error "terraform plan 실패: ${layer_name}"
                return 1
            fi

            log_info "terraform apply 실행 중..."
            if ! terraform apply -auto-approve tfplan; then
                log_error "terraform apply 실패: ${layer_name}"
                return 1
            fi
            
            # Plan 파일 정리
            rm -f tfplan
            ;;
        destroy)
            log_info "terraform destroy 실행 중..."
            if ! terraform destroy -auto-approve; then
                log_error "terraform destroy 실패: ${layer_name}"
                return 1
            fi
            ;;
        plan)
            log_info "terraform plan 실행 중..."
            terraform plan
            ;;
    esac

    log_success "Layer ${layer_name} ${action} 완료!"
    return 0
}

# =============================================================================
# 레이어 상태 확인
# =============================================================================
check_layer_status() {
    local layer_path="$1"
    local layer_name=$(basename "${layer_path}")
    
    cd "${layer_path}"
    
    if [[ ! -d ".terraform" ]]; then
        echo -e "  ${YELLOW}○${NC} ${layer_name}: 초기화 안됨"
        return
    fi

    # State 확인
    if terraform state list &>/dev/null; then
        local resource_count=$(terraform state list 2>/dev/null | wc -l)
        if [[ ${resource_count} -gt 0 ]]; then
            echo -e "  ${GREEN}●${NC} ${layer_name}: 배포됨 (${resource_count} resources)"
        else
            echo -e "  ${YELLOW}○${NC} ${layer_name}: 초기화됨 (리소스 없음)"
        fi
    else
        echo -e "  ${YELLOW}○${NC} ${layer_name}: State 없음"
    fi
}

# =============================================================================
# 확인 프롬프트
# =============================================================================
confirm_action() {
    local action="$1"
    local env="$2"
    
    if [[ "${SKIP_CONFIRM}" == true ]]; then
        return 0
    fi

    echo ""
    if [[ "${action}" == "destroy" ]]; then
        echo -e "${RED}${BOLD}⚠️  경고: 이 작업은 모든 인프라를 삭제합니다!${NC}"
        echo -e "${RED}   환경: ${env}${NC}"
        echo ""
    fi

    echo -e "${YELLOW}다음 작업을 수행합니다:${NC}"
    echo -e "  명령어: ${BOLD}${action}${NC}"
    echo -e "  환경: ${BOLD}${env}${NC}"
    
    if [[ -n "${TARGET_LAYER}" ]]; then
        echo -e "  대상 레이어: ${BOLD}${TARGET_LAYER}${NC}"
    else
        echo -e "  대상 레이어: ${BOLD}전체${NC}"
    fi
    
    echo ""
    
    if [[ "${action}" == "destroy" ]]; then
        read -p "정말로 삭제하시겠습니까? 환경 이름을 입력하세요 [${env}]: " confirm
        if [[ "${confirm}" != "${env}" ]]; then
            log_error "확인 실패. 작업을 취소합니다."
            exit 1
        fi
    else
        read -p "계속하시겠습니까? [y/N]: " confirm
        if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
            log_info "작업이 취소되었습니다."
            exit 0
        fi
    fi
}

# =============================================================================
# 메인 실행 로직
# =============================================================================
execute_layers() {
    local action="$1"
    local env_dir="${PROJECT_ROOT}/environments/${ENVIRONMENT}"
    local layers_to_run=()
    local start_time=$(date +%s)

    # 실행할 레이어 결정
    if [[ -n "${TARGET_LAYER}" ]]; then
        # 특정 레이어만 실행
        local layer_path="${env_dir}/${TARGET_LAYER}"
        if [[ ! -d "${layer_path}" ]]; then
            log_error "레이어 디렉토리가 존재하지 않습니다: ${layer_path}"
            exit 1
        fi
        layers_to_run=("${TARGET_LAYER}")
    else
        # 전체 레이어 실행
        layers_to_run=("${LAYERS[@]}")
    fi

    # destroy 시 역순으로 정렬
    if [[ "${action}" == "destroy" ]]; then
        local reversed=()
        for (( i=${#layers_to_run[@]}-1; i>=0; i-- )); do
            reversed+=("${layers_to_run[i]}")
        done
        layers_to_run=("${reversed[@]}")
    fi

    # 실행 순서 출력
    log_info "실행 순서:"
    local order=1
    for layer in "${layers_to_run[@]}"; do
        echo -e "  ${order}. ${layer}"
        ((order++))
    done
    echo ""

    # 각 레이어 실행
    local failed_layer=""
    for layer in "${layers_to_run[@]}"; do
        local layer_path="${env_dir}/${layer}"
        
        if [[ ! -d "${layer_path}" ]]; then
            log_warn "레이어 디렉토리가 존재하지 않습니다 (건너뜀): ${layer_path}"
            continue
        fi

        if ! run_terraform "${layer_path}" "${action}"; then
            failed_layer="${layer}"
            break
        fi
    done

    # 결과 출력
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo ""
    log_step "실행 결과"
    
    if [[ -n "${failed_layer}" ]]; then
        log_error "작업 실패!"
        log_error "실패한 레이어: ${failed_layer}"
        log_info "소요 시간: ${minutes}분 ${seconds}초"
        exit 1
    else
        log_success "모든 작업이 성공적으로 완료되었습니다!"
        log_info "소요 시간: ${minutes}분 ${seconds}초"
    fi
}

show_status() {
    local env_dir="${PROJECT_ROOT}/environments/${ENVIRONMENT}"
    
    log_step "인프라 상태 확인: ${ENVIRONMENT}"
    
    echo -e "\n${BOLD}레이어 상태:${NC}"
    for layer in "${LAYERS[@]}"; do
        local layer_path="${env_dir}/${layer}"
        if [[ -d "${layer_path}" ]]; then
            check_layer_status "${layer_path}"
        else
            echo -e "  ${RED}✗${NC} ${layer}: 디렉토리 없음"
        fi
    done
    echo ""
}

# =============================================================================
# 메인
# =============================================================================
main() {
    print_banner
    parse_args "$@"

    log_info "환경: ${ENVIRONMENT}"
    log_info "명령어: ${COMMAND}"
    
    if [[ "${DRY_RUN}" == true ]]; then
        log_warn "DRY-RUN 모드: 실제 실행 없이 명령어만 출력합니다."
    fi

    case "${COMMAND}" in
        apply|destroy|plan)
            confirm_action "${COMMAND}" "${ENVIRONMENT}"
            execute_layers "${COMMAND}"
            ;;
        status)
            show_status
            ;;
    esac
}

main "$@"