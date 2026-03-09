#!/bin/bash
# 02_restore_defaults.sh — Host sysctl 기본값 복원 (구성 A, C용)
# rancher 비밀번호: password003 고정 (sshpass 필요: brew install sshpass)
set -euo pipefail
: "${CLIENT_NODE_IP:?필요}" ; : "${SERVER_NODE_IP:?필요}"
RANCHER_PASSWORD="${RANCHER_PASSWORD:-password003}"

RESTORE_SCRIPT='
sysctl -w net.core.rmem_max=212992
sysctl -w net.core.wmem_max=212992
sysctl -w net.core.rmem_default=212992
sysctl -w net.core.wmem_default=212992
sysctl -w net.core.netdev_max_backlog=1000
sysctl -w net.core.somaxconn=4096
sysctl -w net.core.busy_poll=0
sysctl -w net.core.busy_read=0
sysctl -w net.ipv4.tcp_rmem="4096 131072 6291456"
sysctl -w net.ipv4.tcp_wmem="4096 16384 4194304"
echo "  완료: rmem_max=$(sysctl -n net.core.rmem_max)"
'
restore() {
  echo "복원: $1"
  printf '%s' "$RESTORE_SCRIPT" | sshpass -p "${RANCHER_PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "rancher@$1" 'sudo bash -s'
}
restore ${CLIENT_NODE_IP}
restore ${SERVER_NODE_IP}
echo "[완료] 기본값 복원"