# test/common.sh — 03_run_test.sh, vm-test, 05_summarize 와 공유하는 측정 상수
# 03_run_test.sh 및 vm-test 에서 source 로 사용

# iperf3 측정
DURATION=60
COOLDOWN=10
PORT=5201
# P=1: 단일 흐름, P=4: 핵심 지표, P=6: 중간 부하
P_LIST="1 4 6"

# CONFIG 이름 (05_summarize.sh 와 동일)
# A=기본+큐1, B=튜닝+큐1, C-1=기본+큐2, C-2=기본+큐4, D-1=튜닝+큐2, D-2=튜닝+큐4
