#!/bin/bash
# 큐 1, 4 만 실행 (큐 2 제외). 사용: ./run_vm_test_1_4.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/vm-test/run_1_4.sh"
