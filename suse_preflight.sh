#!/bin/bash
# suse_preflight.sh — 설정된 Harvester 노드들에 SSH로 접속해 사전 검증 자동 실행
#
# 사용 전: sshpass 설치 필요 (macOS: brew install sshpass)
# 원격 검증(sysctl, lsmod, ethtool 등)은 sudo로 실행됩니다. SSH 사용자에게 비밀번호 없이 sudo 가능해야 합니다.
# 보안: 실제 운영에서는 비밀번호 대신 SSH 키 사용을 권장합니다.

# ========== 여기에 IP와 비밀번호 설정 ==========
SSH_USER="${SSH_USER:-rancher}"          # SSH 사용자 (기본: root)
SSH_PASSWORD="password003"                       # 공통 비밀번호 (비우면 SSH 키 사용)
NODES=(
  "10.161.96.32"
  "10.161.96.33"
  "10.161.96.35"
  # "192.168.1.12"
)

# 노드별로 다른 비밀번호를 쓰려면 아래 for 루프 안의 case에 IP별로 추가 (선택)
# ==============================================

set -e
REPORT_DIR="${REPORT_DIR:-./preflight_reports}"
mkdir -p "$REPORT_DIR"

# 원격에서 실행할 검증 스크립트 (각 노드에서 실행됨)
run_on_node() {
  local ip="$1"
  local pass="${2:-$SSH_PASSWORD}"
  local report_file="$REPORT_DIR/preflight_${ip}.txt"

  echo "[$ip] 연결 중..."
  {
    if [[ -n "$pass" ]]; then
      if ! command -v sshpass &>/dev/null; then
        echo "오류: sshpass가 필요합니다. (macOS: brew install sshpass)"
        exit 1
      fi
      sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -- "$SSH_USER@$ip" 'sudo bash -s'
    else
      ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -- "$SSH_USER@$ip" 'sudo bash -s'
    fi
  } <<'REMOTE_SCRIPT'
echo "=== Harvester 노드 사전 검증 ==="
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "커널: $(uname -r)"
echo ""
echo "--- vhost_net 모듈 ---"
lsmod | grep vhost_net && echo "[OK]" || echo "[WARN] 미로드 → modprobe vhost_net 필요"

echo ""
echo "--- 현재 sysctl 기준값 기록 ---"
: > /tmp/baseline_sysctl.txt
for key in net.core.rmem_max net.core.wmem_max \
           net.core.rmem_default net.core.wmem_default \
           net.core.netdev_max_backlog net.core.somaxconn net.core.busy_poll \
           net.ipv4.tcp_rmem net.ipv4.tcp_wmem; do
  sysctl "$key" 2>/dev/null >> /tmp/baseline_sysctl.txt || true
done
cat /tmp/baseline_sysctl.txt

echo ""
echo "--- ethtool (물리 NIC) ---"
for NIC in $(ip -br link show | grep -v '^lo' | awk '{print $1}'); do
  echo "  $NIC:"
  ethtool -i "$NIC" 2>/dev/null | grep driver || true
  ethtool -l "$NIC" 2>/dev/null | grep -A2 "Current hardware" || true
done
exit 0
REMOTE_SCRIPT

  local ret=$?
  if [[ $ret -eq 0 ]]; then
    echo "[$ip] 완료 → $report_file"
  else
    echo "[$ip] 실패 (exit $ret)"
    return $ret
  fi
}

echo "=== 대상 노드 ${#NODES[@]}대 사전 검증 시작 ==="
for ip in "${NODES[@]}"; do
  [[ -z "$ip" || "$ip" =~ ^[[:space:]]*# ]] && continue
  ip=$(echo "$ip" | tr -d ' ')
  pass="$SSH_PASSWORD"
  case "$ip" in
    # 192.168.1.10) pass="pass1" ;;
    # 192.168.1.11) pass="pass2" ;;
    *) ;;
  esac
  run_on_node "$ip" "$pass" | tee "$REPORT_DIR/preflight_${ip}.txt" || true
  echo ""
done
echo "=== 사전 검증 끝. 보고서: $REPORT_DIR/ ==="
