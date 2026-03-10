#!/bin/bash
# vm-test/run_1_4.sh — 큐 1 → 4 만 진행 (큐 2 제외)
# 사용: ./run_1_4.sh
set -euo pipefail

VM_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========== vm-test: queue 1 → 4 (각 큐 default → tuned, 서버 iperf3 측정 후 자동 종료) =========="
for q in 1 4; do
  echo ""
  echo ">>>>>>>>>> 큐 ${q} 시작 <<<<<<<<<<"
  bash "${VM_TEST_DIR}/run.sh" "${q}"
  echo ""
  echo ">>>>>>>>>> 큐 ${q} 완료 <<<<<<<<<<"
done
echo "========== 전체 완료 =========="
