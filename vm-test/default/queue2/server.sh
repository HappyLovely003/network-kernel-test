#!/bin/bash
# [default] 큐 2 — CONFIG=C-1. 서버 VM에서 실행. test/common.sh 상수 사용.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common.sh"
NIC="${VM_ETH:-enp2s0}"
echo "[default/queue2] CONFIG=C-1 NIC=${NIC} 큐 2 (포트 ${PORT})"
sudo ethtool -L "${NIC}" combined 2 2>/dev/null || true
sudo pkill iperf3 2>/dev/null || true
sleep 1
iperf3 -s -p "${PORT}" -D
echo "[default/queue2] iperf3 서버 대기 (포트 ${PORT})."
