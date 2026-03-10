#!/bin/bash
# VM에서 실행: iperf3, jq 설치 (vm-test 측정용)
# 사용: sudo ./install_iperf.sh   또는  ./install_iperf.sh
set -e
echo "[install] apt-get update..."
apt-get update -qq
echo "[install] iperf3, jq 설치..."
apt-get install -y iperf3 jq
echo "[install] 완료: $(iperf3 --version | head -1), jq $(jq --version)"
