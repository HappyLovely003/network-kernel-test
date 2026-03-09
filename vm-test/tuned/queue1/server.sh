#!/bin/bash
# [tuned] 큐 1 — CONFIG=B. 서버 VM에서 실행. test/common.sh 상수 사용.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common.sh"
NIC="${VM_ETH:-enp2s0}"
echo "[tuned/queue1] CONFIG=B NIC=${NIC} 큐 1 (포트 ${PORT})"
sudo ethtool -L "${NIC}" combined 1 2>/dev/null || true
sudo pkill iperf3 2>/dev/null || true
sleep 1
iperf3 -s -p "${PORT}" -D
echo "[tuned/queue1] iperf3 서버 대기 (포트 ${PORT}). 클라이언트에서 client.sh 실행."
