#!/bin/bash
# 프로젝트 루트에서 vm-test 전체 실행 (큐 1 → 2 → 4, default/tuned 각각, 서버 iperf3 자동 종료)
# 사용: ./run_vm_test.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/vm-test/run_all.sh"
