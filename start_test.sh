#!/bin/bash
# =================================================================
# start_test.sh — 실험 실행 (큐 구성별로 선택 가능)
#
# 사용법:
#   ./start_test.sh [큐모드]
#   큐모드: 1 | 2 | 4 | all
#     1   — 단일 큐만 (A: 기본값+큐1, B: 튜닝+큐1)
#     2   — 큐 2개만 (C-1: 기본값+큐2, D-1: 튜닝+큐2)
#     4   — 큐 4개만 (C-2: 기본값+큐4, D-2: 튜닝+큐4)
#     all — 전체 (기본값)
#
#   환경 변수: CLIENT_IP, SERVER_IP, CLIENT_NODE_IP, SERVER_NODE_IP
#   SKIP_QUEUE_SET=1 이면 VM 큐 설정 생략
#   RUN_NUM=2 이면 2번만 실행 (1,3 건너뜀). 기존 결과 폴더에 넣으려면 RESULT_BASE=result/날짜_시간 지정
#   또는 test/env.sh 에 정의
# =================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/test"

# 선택: test/env.sh 있으면 로드 (CLIENT_IP, SERVER_IP, CLIENT_NODE_IP, SERVER_NODE_IP)
if [[ -f "${TEST_DIR}/env.sh" ]]; then
  echo "[start_test] ${TEST_DIR}/env.sh 로드"
  set +u
  source "${TEST_DIR}/env.sh"
  set -u
fi

missing=""
[[ -z "${CLIENT_IP:-}" ]]      && missing="${missing} CLIENT_IP"
[[ -z "${SERVER_IP:-}" ]]      && missing="${missing} SERVER_IP"
[[ -z "${CLIENT_NODE_IP:-}" ]] && missing="${missing} CLIENT_NODE_IP"
[[ -z "${SERVER_NODE_IP:-}" ]] && missing="${missing} SERVER_NODE_IP"

if [[ -n "${missing}" ]]; then
  echo "오류: 다음 환경 변수가 필요합니다:${missing}"
  echo ""
  echo "사용법: ./start_test.sh [1|2|4|all]"
  echo "  1   단일 큐 (A, B)"
  echo "  2   큐 2개 (C-1, D-1)"
  echo "  4   큐 4개 (C-2, D-2)"
  echo "  all 전체 (기본값)"
  exit 1
fi

QUEUE_MODE="${1:-all}"
case "${QUEUE_MODE}" in
  1|2|4|all) ;;
  *)
    echo "오류: 큐모드는 1, 2, 4, all 중 하나여야 합니다. (입력: ${QUEUE_MODE})"
    echo "  ./start_test.sh 1   # 단일 큐"
    echo "  ./start_test.sh 2   # 큐 2개"
    echo "  ./start_test.sh 4   # 큐 4개"
    echo "  ./start_test.sh all # 전체"
    exit 1
    ;;
esac

export QUEUE_MODE
[[ -n "${SKIP_QUEUE_SET:-}" ]] && export SKIP_QUEUE_SET
[[ -n "${RUN_NUM:-}" ]] && export RUN_NUM
[[ -n "${RESULT_BASE:-}" ]] && export RESULT_BASE
echo "[start_test] CLIENT_IP=${CLIENT_IP} SERVER_IP=${SERVER_IP}"
echo "[start_test] CLIENT_NODE_IP=${CLIENT_NODE_IP} SERVER_NODE_IP=${SERVER_NODE_IP}"
echo "[start_test] VM_ETH=${VM_ETH:-enp2s0}  (큐 설정 시 사용, env.sh 에서 변경 가능)"
echo "[start_test] 큐모드=${QUEUE_MODE}"
[[ -n "${RUN_NUM:-}" ]] && echo "[start_test] RUN_NUM=${RUN_NUM} (이 번호만 실행)"
echo "[start_test] 실험 시작 — ${TEST_DIR}/04_run_all.sh"
echo ""

cd "${TEST_DIR}"
exec bash ./04_run_all.sh
