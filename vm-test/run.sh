#!/bin/bash
# vm-test/run.sh — 호스트에서 실행. 큐 번호(1|2|4)만 받아서 default → 3분 대기 → tuned 순서로 진행
# 사용: ./run.sh 1   또는  ./run.sh 2   또는  ./run.sh 4
# queue1이면 default 측정 후 3분 대기, tuned 측정까지 한 번에 안내
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

echo "========== vm-test: queue=${QUEUE} (default=${CONFIG_DEFAULT} → tuned=${CONFIG_TUNED}) =========="

# --- 1) 기본값 복원, 3분 대기, default 측정 안내
echo "[호스트] 커널 기본값 복원 (test/02_restore_defaults.sh)"
(cd "${ROOT_DIR}" && bash "${TEST_DIR}/02_restore_defaults.sh")
echo "[호스트] default 측정 전 대기: ${WAIT_MIN}분"
sleep $((WAIT_MIN * 60))

echo ""
echo "--------- [1/2] default (CONFIG=${CONFIG_DEFAULT}) — VM에서 실행 ---------"
echo "  서버 VM: cd ${CASE_DEFAULT} && ./server.sh"
echo "  클라이언트 VM: cd ${CASE_DEFAULT} && export SERVER_IP=<서버IP> && ./client.sh"
echo "  결과: results_${CONFIG_DEFAULT}/"
echo ""
printf "default 측정 끝나면 Enter 입력 후 tuned 적용합니다... "
read -r

# --- 2) 튜닝 적용, 3분 대기, tuned 측정 안내
echo "[호스트] 커널 튜닝 적용 (test/01_apply_tuning.sh)"
(cd "${ROOT_DIR}" && bash "${TEST_DIR}/01_apply_tuning.sh")
echo "[호스트] tuned 측정 전 대기: ${WAIT_MIN}분"
sleep $((WAIT_MIN * 60))

echo ""
echo "--------- [2/2] tuned (CONFIG=${CONFIG_TUNED}) — VM에서 실행 ---------"
echo "  서버 VM: cd ${CASE_TUNED} && ./server.sh"
echo "  클라이언트 VM: cd ${CASE_TUNED} && export SERVER_IP=<서버IP> && ./client.sh"
echo "  결과: results_${CONFIG_TUNED}/"
echo ""
echo "05_summarize: result/날짜_시간/${CONFIG_DEFAULT}/run1, ${CONFIG_TUNED}/run1 에 JSON 복사 후 ./test/05_summarize.sh"
echo "=========="
