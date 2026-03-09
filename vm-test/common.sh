# vm-test/common.sh — test/common.sh 상수 사용 (같은 repo 내 test/ 와 동기화)
# VM에 test/ 없으면 기본값 사용
VM_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_COMMON="${VM_TEST_DIR}/../test/common.sh"
if [[ -f "${TEST_COMMON}" ]]; then
  source "${TEST_COMMON}"
else
  DURATION=60
  COOLDOWN=10
  PORT=5201
  P_LIST="1 4 6"
fi
# CONFIG는 각 client.sh에서 설정 (A, B, C-1, C-2, D-1, D-2)
