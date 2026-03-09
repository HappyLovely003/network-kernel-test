#!/bin/bash
# =================================================================
# 03_run_test.sh — 단일 구성·단일 실행 TCP 처리량 측정
#
# 사용법:
#   bash 03_run_test.sh <CONFIG> <RUN> <SERVER_IP> <CLIENT_IP>
#
# 예시:
#   bash 03_run_test.sh A 1 192.168.1.11 192.168.1.10
#   bash 03_run_test.sh C-2 2 192.168.1.11 192.168.1.10
# =================================================================
set -euo pipefail

CONFIG="${1:?CONFIG 필요 (A/B/C-1/C-2/C-3/C-4/D-1/D-2/D-3/D-4)}"
RUN="${2:?RUN 번호 필요 (1/2/3)}"
SERVER_IP="${3:?SERVER_IP 필요}"
CLIENT_IP="${4:?CLIENT_IP 필요}"

# ConnectTimeout 60초: VM SSH 지연/타임아웃 완화
SSH="ssh -i ${HOME}/.ssh/dagyeong-sample -o StrictHostKeyChecking=no -o ConnectTimeout=60 -o ServerAliveInterval=30 -o ServerAliveCountMax=3"

# 04_run_all.sh에서 호출 시 RESULT_BASE가 설정됨. 단독 실행 시 result/날짜_시간 생성
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 공통 상수 (DURATION, COOLDOWN, P_LIST, PORT)
source "${SCRIPT_DIR}/common.sh"
RESULT_ROOT="${SCRIPT_DIR}/../result"
if [[ -z "${RESULT_BASE:-}" ]]; then
  RESULT_BASE="${RESULT_ROOT}/$(date +%Y%m%d_%H%M%S)"
  mkdir -p "${RESULT_BASE}"
fi
RESULT_DIR="${RESULT_BASE}/${CONFIG}/run${RUN}"
mkdir -p "${RESULT_DIR}"

echo "=============================="
echo " CONFIG=${CONFIG}  RUN=${RUN}"
echo " CLIENT=${CLIENT_IP}  SERVER=${SERVER_IP}"
echo " $(date)"
echo "=============================="

# 서버 iperf3 재시작 (PATH 지정해 비대화형 셸에서도 iperf3 찾음)
$SSH ubuntu@${SERVER_IP} \
  "export PATH=/usr/local/bin:/usr/bin:/bin; sudo pkill iperf3 2>/dev/null; sleep 1; iperf3 -s -p ${PORT} -D"
sleep 2

for P in ${P_LIST}; do
  echo ""
  echo "[$(date +%H:%M:%S)] TCP P=${P} 측정 (${DURATION}s)..."

  $SSH ubuntu@${CLIENT_IP} \
    "export PATH=/usr/local/bin:/usr/bin:/bin; iperf3 -c ${SERVER_IP} -p ${PORT} -t ${DURATION} -P ${P} --json" \
    > "${RESULT_DIR}/iperf3_tcp_P${P}.json"

  TPUT=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' \
    "${RESULT_DIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")
  RETRANS=$(jq -r '.end.sum_sent.retransmits // 0' \
    "${RESULT_DIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")

  echo "  → ${TPUT} Gbps  (재전송: ${RETRANS})"
  sleep ${COOLDOWN}
done

# 서버 종료
$SSH ubuntu@${SERVER_IP} "export PATH=/usr/local/bin:/usr/bin:/bin; sudo pkill iperf3 2>/dev/null || true"

# 요약 저장
{
  echo "CONFIG=${CONFIG} RUN=${RUN} TIME=$(date)"
  for P in ${P_LIST}; do
    T=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' \
      "${RESULT_DIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")
    R=$(jq -r '.end.sum_sent.retransmits // 0' \
      "${RESULT_DIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")
    echo "P${P}: ${T} Gbps  retrans=${R}"
  done
} | tee "${RESULT_DIR}/summary.txt"