#!/bin/bash
# [default] 큐 4 — CONFIG=C-2. test/common.sh 상수 사용.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../common.sh"
CONFIG="C-2"
OUTDIR="results_${CONFIG}"
: "${SERVER_IP:?SERVER_IP 설정 필요}"
NIC="${VM_ETH:-enp2s0}"
mkdir -p "${OUTDIR}"
echo "[default/queue4] CONFIG=${CONFIG} NIC=${NIC} 큐 4"
sudo ethtool -L "${NIC}" combined 4 2>/dev/null || true
for P in ${P_LIST}; do
  echo "[$(date +%H:%M:%S)] TCP P=${P} (${DURATION}s)..."
  iperf3 -c "${SERVER_IP}" -p "${PORT}" -t "${DURATION}" -P "${P}" --json > "${OUTDIR}/iperf3_tcp_P${P}.json.tmp" && mv "${OUTDIR}/iperf3_tcp_P${P}.json.tmp" "${OUTDIR}/iperf3_tcp_P${P}.json" || { echo "  → [실패] P=${P}"; rm -f "${OUTDIR}/iperf3_tcp_P${P}.json.tmp"; }
  TPUT=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' "${OUTDIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")
  echo "  → ${TPUT} Gbps"
  [ "${P}" != "6" ] && sleep ${COOLDOWN} || true
done
{
  echo "CONFIG=${CONFIG} RUN=1 TIME=$(date)"
  for P in ${P_LIST}; do
    T=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' "${OUTDIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")
    R=$(jq -r '.end.sum_sent.retransmits // 0' "${OUTDIR}/iperf3_tcp_P${P}.json" 2>/dev/null || echo "N/A")
    echo "P${P}: ${T} Gbps  retrans=${R}"
  done
} | tee "${OUTDIR}/summary.txt"
echo "[default/queue4] 결과: ${OUTDIR}/  (summary.txt 확인)"
