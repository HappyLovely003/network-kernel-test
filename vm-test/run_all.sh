#!/bin/bash
# vm-test/run_all.sh — 큐 1 → 2 → 4 순서로 전부 진행 (각 큐별 VM 2대씩 사용, 측정 끝날 때마다 서버 iperf3 자동 종료)
# 사용: ./run_all.sh
set -euo pipefail

VM_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========== vm-test 전체: queue 1 → 2 → 4 (각 큐 default → tuned, 서버 iperf3 측정 후 자동 종료) =========="
for q in 1 2 4; do
  echo ""
  echo ">>>>>>>>>> 큐 ${q} 시작 <<<<<<<<<<"
  bash "${VM_TEST_DIR}/run.sh" "${q}"
  echo ""
  echo ">>>>>>>>>> 큐 ${q} 완료 <<<<<<<<<<"
done
echo "========== 전체 완료 =========="
