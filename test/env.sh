# test/env.sh.example — 복사 후 env.sh 로 저장하고 IP 수정
# cp env.sh.example env.sh && vi env.sh
# ubuntu@VM 접속에는 ~/.ssh/dagyeong-sample 키 사용 (VM의 authorized_keys에 공개키 등록)

# Harvester 노드 IP (01/02 호스트 커널 적용용). 동일 노드면 둘 다 같은 값으로 해도 됨
export CLIENT_NODE_IP="10.161.96.32"
export SERVER_NODE_IP="10.161.96.33"

# 큐별 VM: 큐 1/2/4 각각 서버·클라이언트 2대씩 있으면 아래 설정 (vm-test/run.sh, run_all.sh 에서 사용)
export SERVER_IP_Q1="10.161.96.157"
export CLIENT_IP_Q1="10.161.96.174"
# export SERVER_IP_Q2="10.161.96.160"
# export CLIENT_IP_Q2="10.161.96.165"
# export SERVER_IP_Q4="192.168.1.15"
# export CLIENT_IP_Q4="10.161.96.181"
export SERVER_IP_Q4="10.161.96.160"
export CLIENT_IP_Q4="10.161.96.165"
# 공통 1쌍만 있으면 SERVER_IP, CLIENT_IP 만 설정하고 위 _Q1/_Q2/_Q4 는 비워도 됨 (그때 run.sh 에서 해당 큐의 서버 IP 로 pkill)

# VM NIC 이름 (큐 설정 시 사용). 기본값 enp2s0
# export VM_ETH="enp2s0"
