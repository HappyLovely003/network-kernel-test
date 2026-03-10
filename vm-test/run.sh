#!/bin/bash
# vm-test/run.sh — 호스트에서 실행. 큐(1|2|4)만 받아 default → 3분 대기 → tuned 진행
# 큐별 VM 2대(서버·클라이언트) 있으면 env 에 SERVER_IP_Q1, CLIENT_IP_Q1 등 설정
# 서버: 측정 끝날 때마다 반드시 iperf3 프로세스 종료 (Enter 시 호스트에서 pkill)
set -euo pipefail

QUEUE="${1:?사용: $0 1|2|4}"

case "${QUEUE}" in
  1|2|4) ;;
  *) echo "오류: 큐는 1, 2, 4 중 하나 (현재: ${QUEUE})"; exit 1 ;;
esac

VM_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${VM_TEST_DIR}/../test"
ROOT_DIR="$(cd "${VM_TEST_DIR}/.." && pwd)"
if [[ -f "${TEST_DIR}/env.sh" ]]; then
  source "${TEST_DIR}/env.sh"
fi

: "${CLIENT_NODE_IP:?CLIENT_NODE_IP 필요. test/env.sh 설정 또는 export 하세요.}"
: "${SERVER_NODE_IP:?SERVER_NODE_IP 필요. test/env.sh 설정 또는 export 하세요.}"

# 이 큐에 해당하는 VM IP (큐별 2대씩 있으면 _Q1/_Q2/_Q4, 없으면 SERVER_IP/CLIENT_IP)
eval "SERVER_IP_CUR=\${SERVER_IP_Q${QUEUE}:-\${SERVER_IP:-}}"
eval "CLIENT_IP_CUR=\${CLIENT_IP_Q${QUEUE}:-\${CLIENT_IP:-}}"

# CONFIG: default → A/C-1/C-2, tuned → B/D-1/D-2
get_config() {
  case "$1" in default_1) echo "A" ;; default_2) echo "C-1" ;; default_4) echo "C-2" ;;
    tuned_1) echo "B" ;; tuned_2) echo "D-1" ;; tuned_4) echo "D-2" ;; *) echo "?" ;; esac
}
CONFIG_DEFAULT=$(get_config "default_${QUEUE}")
CONFIG_TUNED=$(get_config "tuned_${QUEUE}")
CASE_DEFAULT="${VM_TEST_DIR}/default/queue${QUEUE}"
CASE_TUNED="${VM_TEST_DIR}/tuned/queue${QUEUE}"
WAIT_MIN=3

# N분 대기 (진행 메시지 출력해서 멈춘 것처럼 보이지 않게)
wait_minutes() {
  local n=$1
  local msg="${2:-대기 중}"
  local i
  for (( i = n * 60; i > 0; i -= 30 )); do
    echo "[$(date +%H:%M:%S)] ${msg} — ${i}초 남음..."
    sleep $(( i >= 30 ? 30 : i ))
  done
  echo "[$(date +%H:%M:%S)] 대기 완료."
}

# 서버 VM에서 iperf3 종료 (테스트 끝나면 반드시 호출)
kill_server_iperf() {
  local ip="${1:-}"
  if [[ -z "${ip}" ]]; then return; fi
  echo "[호스트] 서버 VM(${ip}) iperf3 종료 중..."
  ssh -i "${HOME}/.ssh/dagyeong-sample" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    "ubuntu@${ip}" "sudo pkill iperf3 2>/dev/null || true" 2>/dev/null || echo "  (SSH 실패 시 해당 서버 VM에서: sudo pkill iperf3)"
}

echo "========== vm-test: queue=${QUEUE} (default=${CONFIG_DEFAULT} → tuned=${CONFIG_TUNED}) =========="
if [[ -n "${SERVER_IP_CUR:-}" ]]; then
  echo "  이 큐 서버 VM: ${SERVER_IP_CUR}  클라이언트 VM: ${CLIENT_IP_CUR:-<설정 없음>}"
fi

# --- 1) 기본값 복원, 3분 대기, default 측정 안내
echo "[호스트] 커널 기본값 복원 (test/02_restore_defaults.sh) — 여기서 멈추면 NODE_IP/rancher SSH 확인"
(cd "${ROOT_DIR}" && bash "${TEST_DIR}/02_restore_defaults.sh")
echo "[호스트] default 측정 전 대기: ${WAIT_MIN}분 (30초마다 진행 출력)"
wait_minutes "${WAIT_MIN}" "default 측정 전"

echo ""
echo "--------- [1/2] default (CONFIG=${CONFIG_DEFAULT}) — VM에서 실행 ---------"
echo "  서버 VM (${SERVER_IP_CUR:-<SERVER_IP_Q${QUEUE} 또는 SERVER_IP 설정>}): cd ${CASE_DEFAULT} && ./server.sh"
echo "  클라이언트 VM: cd ${CASE_DEFAULT} && export SERVER_IP=${SERVER_IP_CUR:-<서버IP>} && ./client.sh"
echo "  결과: results_${CONFIG_DEFAULT}/"
echo ""
printf "default 측정 끝나면 Enter 입력 (입력 시 해당 서버 VM에서 iperf3 자동 종료)... "
read -r
kill_server_iperf "${SERVER_IP_CUR:-}"

# --- 2) 튜닝 적용, 3분 대기, tuned 측정 안내
echo "[호스트] 커널 튜닝 적용 (test/01_apply_tuning.sh)"
(cd "${ROOT_DIR}" && bash "${TEST_DIR}/01_apply_tuning.sh")
echo "[호스트] tuned 측정 전 대기: ${WAIT_MIN}분 (30초마다 진행 출력)"
wait_minutes "${WAIT_MIN}" "tuned 측정 전"

echo ""
echo "--------- [2/2] tuned (CONFIG=${CONFIG_TUNED}) — VM에서 실행 ---------"
echo "  서버 VM (${SERVER_IP_CUR:-<서버IP>}): cd ${CASE_TUNED} && ./server.sh"
echo "  클라이언트 VM: cd ${CASE_TUNED} && export SERVER_IP=${SERVER_IP_CUR:-<서버IP>} && ./client.sh"
echo "  결과: results_${CONFIG_TUNED}/"
echo ""
printf "tuned 측정 끝나면 Enter 입력 (입력 시 해당 서버 VM에서 iperf3 자동 종료)... "
read -r
kill_server_iperf "${SERVER_IP_CUR:-}"

echo ""
echo "05_summarize: result/날짜_시간/${CONFIG_DEFAULT}/run1, ${CONFIG_TUNED}/run1 에 JSON 복사 후 ./test/05_summarize.sh"
echo "=========="
