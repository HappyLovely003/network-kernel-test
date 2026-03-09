#!/bin/bash
# 01_apply_tuning.sh — Host sysctl 튜닝 적용 (구성 B, D용)
# rancher 비밀번호: password003 고정 (sshpass 필요: brew install sshpass)
set -euo pipefail
: "${CLIENT_NODE_IP:?필요}" ; : "${SERVER_NODE_IP:?필요}"
RANCHER_PASSWORD="${RANCHER_PASSWORD:-password003}"

TUNE_SCRIPT='
sysctl -w net.core.rmem_max=67108864
sysctl -w net.core.wmem_max=67108864
sysctl -w net.core.rmem_default=33554432
sysctl -w net.core.wmem_default=33554432
sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
sysctl -w net.core.netdev_max_backlog=65536
sysctl -w net.core.somaxconn=8192
sysctl -w net.core.busy_poll=50
sysctl -w net.core.busy_read=50
lsmod | grep -q vhost_net || modprobe vhost_net
echo "  완료: rmem_max=$(sysctl -n net.core.rmem_max)"
'
apply() {
  echo "튜닝 적용: $1"
  printf '%s' "$TUNE_SCRIPT" | sshpass -p "${RANCHER_PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "rancher@$1" 'sudo bash -s'
}
apply ${CLIENT_NODE_IP}
apply ${SERVER_NODE_IP}
echo "[완료] 튜닝 적용"