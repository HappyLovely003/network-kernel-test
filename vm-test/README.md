# VM 안에서 직접 네트워크 테스트

**큐 1 / 큐 2 / 큐 4 VM이 각각 2대씩(서버·클라이언트)** 있으면 `test/env.sh`에 큐별 IP를 넣고, `./run.sh 1|2|4` 또는 `./run_all.sh`로 진행.  
**서버는 측정 끝날 때마다 반드시 iperf3 프로세스 종료** — Enter 입력 시 호스트가 해당 서버 VM에 SSH로 `pkill iperf3` 실행.

## 준비

- **호스트용:** `test/env.sh` 에 `CLIENT_NODE_IP`, `SERVER_NODE_IP` (Harvester 노드 IP).  
  **큐별 VM 2대씩:** `SERVER_IP_Q1`, `CLIENT_IP_Q1`, `SERVER_IP_Q2`, `CLIENT_IP_Q2`, `SERVER_IP_Q4`, `CLIENT_IP_Q4` 설정. (공통 1쌍만 있으면 `SERVER_IP`, `CLIENT_IP` 만 넣어도 됨.)
- **VM:** iperf3, jq 설치. NIC가 enp2s0가 아니면 `export VM_ETH=본인NIC`

---

## 실행

### 한 큐만: `./run.sh 1` / `./run.sh 2` / `./run.sh 4`

1. 호스트에서 `./run.sh 1` (또는 2, 4) 실행  
2. 기본값 복원 후 **3분 대기** → 안내된 **서버 VM**에서 `./server.sh`, **클라이언트 VM**에서 `export SERVER_IP=해당서버IP && ./client.sh`  
3. **default 측정 끝나면 Enter** → 호스트가 **해당 큐 서버 VM에서 iperf3 자동 종료**  
4. 튜닝 적용 후 **3분 대기** → 같은 큐의 서버/클라이언트 VM에서 tuned 폴더로 `./server.sh`, `./client.sh`  
5. **tuned 측정 끝나면 Enter** → 호스트가 **다시 해당 서버 VM에서 iperf3 자동 종료**

### 전부 자동 순서 (한 번에 실행)

**프로젝트 루트에서:**
```bash
./run_vm_test.sh
```

**또는 vm-test 폴더에서:**
```bash
cd vm-test && ./run_all.sh
```

큐 1 (default → Enter → tuned → Enter) → 큐 2 → 큐 4 순서로 진행. 각 측정 끝날 때마다 Enter 시 **그 큐의 서버 VM에서 iperf3가 자동으로 종료**됨.

---

## 결과

| CONFIG | 의미           | 결과 폴더      |
|--------|----------------|----------------|
| A      | default, 큐 1  | `results_A/`   |
| B      | tuned, 큐 1    | `results_B/`   |
| C-1    | default, 큐 2  | `results_C-1/` |
| D-1    | tuned, 큐 2    | `results_D-1/` |
| C-2    | default, 큐 4  | `results_C-2/` |
| D-2    | tuned, 큐 4    | `results_D-2/` |

각 폴더에 `iperf3_tcp_P1.json`, `iperf3_tcp_P4.json`, `iperf3_tcp_P6.json` 생성.  
`test/05_summarize.sh` 사용 시 `result/날짜_시간/CONFIG/run1/` 아래에 JSON 복사 후 실행.

## NIC 이름

기본값 `enp2s0`. 다르면 서버/클라이언트 VM 모두 `export VM_ETH=ens3` 등 설정 후 `./server.sh`, `./client.sh` 실행.
