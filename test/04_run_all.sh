#!/bin/bash
# =================================================================
# 04_run_all.sh — 전체 실험 자동 실행
# VM 스펙 고정: 4vCPU / 8GB
#
# 측정 구성:
#   A        : sysctl 기본값 + 큐 1개 (Baseline)
#   B        : sysctl 튜닝  + 큐 1개 (커널 튜닝 단독 효과)
#   C-1      : sysctl 기본값 + 큐 2개 (큐 < vCPU)
#   C-2      : sysctl 기본값 + 큐 4개 (큐 = vCPU, 이론적 최적)
#   D-1      : sysctl 튜닝  + 큐 2개
#   D-2      : sysctl 튜닝  + 큐 4개 (큐 = vCPU, 이론적 최적)
#
# 사용법:
#   QUEUE_MODE=1|2|4|all (기본: all)
#   SKIP_QUEUE_SET=1 이면 큐 설정 생략, iperf3 네트워크 측정만 수행 (VM SSH 불가 시 사용)
#   export CLIENT_IP=... SERVER_IP=... CLIENT_NODE_IP=... SERVER_NODE_IP=...
#   bash 04_run_all.sh
#   또는 start_test.sh [1|2|4|all] 로 실행
# =================================================================
set -euo pipefail

: "${CLIENT_IP:?필요}"
: "${SERVER_IP:?필요}"
: "${CLIENT_NODE_IP:?필요}"
: "${SERVER_NODE_IP:?필요}"

QUEUE_MODE="${QUEUE_MODE:-all}"
case "${QUEUE_MODE}" in 1|2|4|all) ;; *)
  echo "오류: QUEUE_MODE는 1, 2, 4, all 중 하나여야 합니다. (현재: ${QUEUE_MODE})"
  exit 1
  ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_ROOT="${SCRIPT_DIR}/../result"
# RESULT_BASE가 이미 있으면 사용 (RUN_NUM으로 기존 폴더에 추가할 때)
if [[ -z "${RESULT_BASE:-}" ]]; then
  RESULT_BASE="${RESULT_ROOT}/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "${RESULT_BASE}"
export RESULT_BASE

# ConnectTimeout 60초: VM SSH 지연/타임아웃 완화
SSH="ssh -i ${HOME}/.ssh/dagyeong-sample -o StrictHostKeyChecking=no -o ConnectTimeout=60 -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
# VM 내부 NIC 이름 (env.sh 에서 VM_ETH 로 변경 가능)
VM_ETH="${VM_ETH:-enp2s0}"
LOG="${RESULT_BASE}/run.log"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "${LOG}"; }

# 실패/중단 시 호스트 sysctl을 원본 값으로 복원
do_cleanup() {
  [[ -n "${CLEANUP_DONE:-}" ]] && return
  CLEANUP_DONE=1
  [[ -z "${SCRIPT_DIR:-}" ]] && return
  echo "[$(date +%H:%M:%S)] 호스트 원본 값 복원 중..." | tee -a "${LOG:-/dev/null}" 2>/dev/null || true
  bash "${SCRIPT_DIR}/02_restore_defaults.sh" 2>&1 | tee -a "${LOG:-/dev/null}" 2>/dev/null || true
}
trap do_cleanup EXIT ERR INT TERM

set_queues() {
  local Q=$1
  if [[ -n "${SKIP_QUEUE_SET:-}" ]]; then
    log "큐 설정 생략 (SKIP_QUEUE_SET=1) — 네트워크 측정만 수행"
    return 0
  fi
  # NIC 최대 큐 수 확인 (Pre-set maximums / Combined). n/a 이면 1로 간주
  local MAX_COMBINED
  MAX_COMBINED=$($SSH ubuntu@${CLIENT_IP} \
    "ethtool -l ${VM_ETH} 2>/dev/null | grep -A5 'Pre-set maximums' | grep Combined | head -1 | awk '{print \$2}'" 2>> "${LOG}" || true)
  if [[ -z "${MAX_COMBINED}" || "${MAX_COMBINED}" == "n/a" ]]; then
    MAX_COMBINED=1
  fi
  if [[ "${Q}" -gt "${MAX_COMBINED}" ]]; then
    log "[WARN] ${VM_ETH} 최대 큐 수가 ${MAX_COMBINED}개라 ${Q}개로 변경 불가. 현재 큐(${MAX_COMBINED}개)로 측정합니다."
    return 0
  fi
  log "큐 설정: ${Q}개 (ubuntu@${CLIENT_IP}, NIC=${VM_ETH}, 최대=${MAX_COMBINED})"
  if ! $SSH ubuntu@${CLIENT_IP} "sudo ethtool -L ${VM_ETH} combined ${Q}" 2>> "${LOG}"; then
    log "[ERROR] 큐 설정 실패. 실제 오류 (run.log 끝):"
    tail -5 "${LOG}" | while read -r line; do log "  $line"; done
    log "가능한 원인: 1) VM에 ${VM_ETH} 없음 2) sudo 권한 3) ethtool -L 미지원"
    log "측정만 하려면: SKIP_QUEUE_SET=1 ./start_test.sh [1|2|4]"
    exit 1
  fi
  # Current hardware settings 아래 Combined 값 (RX/TX/Other 다음 줄이므로 -A5)
  ACTUAL=$($SSH ubuntu@${CLIENT_IP} \
    "ethtool -l ${VM_ETH} 2>/dev/null | grep -A5 'Current hardware' | grep Combined | head -1 | awk '{print \$2}'" 2>> "${LOG}" || true)
  ACTUAL="${ACTUAL:-}"
  if [[ -z "${ACTUAL}" || "${ACTUAL}" == "n/a" ]]; then
    log "[WARN] 큐 수 검증 스킵 (ethtool Combined 값 없음). 측정 계속합니다."
    return 0
  fi
  if [[ "${ACTUAL}" != "${Q}" ]]; then
    log "[ERROR] 큐 불일치: 요청=${Q} 실제=${ACTUAL}"
    exit 1
  fi
  log "큐 검증 OK: ${ACTUAL}개"
}

run_3x() {
  local CONFIG=$1
  # RUN_NUM=2 이면 2번만 실행 (예: RUN_NUM=2 ./start_test.sh 1)
  local run_list="1 2 3"
  [[ -n "${RUN_NUM:-}" ]] && [[ "${RUN_NUM}" =~ ^[123]$ ]] && run_list="${RUN_NUM}"
  for RUN in ${run_list}; do
    log "-- ${CONFIG} Run ${RUN}/3 --"
    local ok=0
    for attempt in 1 2 3; do
      if bash "${SCRIPT_DIR}/03_run_test.sh" "${CONFIG}" "${RUN}" "${SERVER_IP}" "${CLIENT_IP}" 2>&1 | tee -a "${LOG}"; then
        ok=1
        break
      fi
      if [[ ${attempt} -lt 3 ]]; then
        log "[WARN] Run ${RUN} 실패. 90초 대기 후 재시도 (${attempt}/3)..."
        sleep 90
      else
        log "[ERROR] Run ${RUN} 3회 시도 후 실패. SSH 타임아웃이면 VM 부하 직후 일시적일 수 있음."
        exit 1
      fi
    done
    [ ${RUN} -lt 3 ] && sleep 60
  done
  # 측정 결과 요약을 로그에 남김
  for RUN in ${run_list}; do
    SUM="${RESULT_BASE}/${CONFIG}/run${RUN}/summary.txt"
    if [[ -f "${SUM}" ]]; then
      log "[${CONFIG} run${RUN}] $(cat "${SUM}")"
    fi
  done
  sleep 90
}

apply_tuning()    { bash "${SCRIPT_DIR}/01_apply_tuning.sh";    }
restore_defaults() { bash "${SCRIPT_DIR}/02_restore_defaults.sh"; }

# ══════════════════════════════════════════════════════════════════
# RUN_NUM 있으면 해당 번호만 실행 (예: RUN_NUM=2)
[[ -n "${RUN_NUM:-}" ]] && log "RUN ${RUN_NUM}만 실행 (RUN_NUM=${RUN_NUM})"
log "========== 실험 시작 (4vCPU / 8GB 고정) | 큐모드=${QUEUE_MODE} =========="
log "CLIENT=${CLIENT_IP}  SERVER=${SERVER_IP}"

# SSH 연결 대기 (VM 응답 지연 시 재시도). 실험 전 서버/클라이언트 모두 접속 가능할 때까지 대기
wait_for_ssh() {
  for IP in ${SERVER_IP} ${CLIENT_IP}; do
    local attempt=1
    while [[ ${attempt} -le 5 ]]; do
      if $SSH -o ConnectTimeout=60 ubuntu@${IP} "exit 0" 2>/dev/null; then
        log "ubuntu@${IP} SSH 연결 OK (시도 ${attempt}/5)"
        break
      fi
      if [[ ${attempt} -eq 5 ]]; then
        log "[ERROR] ubuntu@${IP} SSH 5회 시도 후 실패. VM 전원/네트워크 확인, 또는 테스트를 VM과 같은 네트워크의 호스트에서 실행해 보세요."
        exit 1
      fi
      log "[WARN] ubuntu@${IP} SSH 타임아웃. 45초 후 재시도 (${attempt}/5)..."
      sleep 45
      attempt=$((attempt + 1))
    done
  done
  log "SSH 연결 확인 완료 (서버/클라이언트)"
}
wait_for_ssh

# iperf3는 VM에 설치되어 있다고 가정 (확인 생략)

run_queue_1() {
  log "===== A: Baseline (기본값, 큐=1) ====="
  restore_defaults
  set_queues 1
  run_3x "A"
  log "===== B: Kernel Only (튜닝, 큐=1) ====="
  apply_tuning
  set_queues 1
  run_3x "B"
}
run_queue_2() {
  log "===== C-1: Queue Only (기본값, 큐=2) ====="
  restore_defaults
  set_queues 2
  run_3x "C-1"
  log "===== D-1: Kernel+Queue (튜닝, 큐=2) ====="
  apply_tuning
  set_queues 2
  run_3x "D-1"
}
run_queue_4() {
  log "===== C-2: Queue Only (기본값, 큐=4) ====="
  restore_defaults
  set_queues 4
  run_3x "C-2"
  log "===== D-2: Kernel+Queue (튜닝, 큐=4) ====="
  apply_tuning
  set_queues 4
  run_3x "D-2"
}

case "${QUEUE_MODE}" in
  1)  run_queue_1 ;;
  2)  run_queue_2 ;;
  4)  run_queue_4 ;;
  all)
    run_queue_1
    run_queue_2
    run_queue_4
    ;;
esac

log "========== 측정 완료 — 결과 분석 =========="
bash "${SCRIPT_DIR}/05_summarize.sh" "${RESULT_BASE}"

log "========== 전체 완료 | 로그: ${LOG} =========="