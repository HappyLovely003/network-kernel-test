# VM 안에서 직접 네트워크 테스트

**파라미터는 큐 번호 하나만:** `./run.sh 1` / `./run.sh 2` / `./run.sh 4`

호스트에서 `run.sh` 실행 → default 측정(3분 대기) → VM에서 default 측정 → Enter → tuned 측정(3분 대기) → VM에서 tuned 측정.  
`test/01_apply_tuning.sh`, `test/02_restore_defaults.sh` 를 그대로 사용합니다.

## 준비

- `test/env.sh` 에 `CLIENT_NODE_IP`, `SERVER_NODE_IP` 설정 (호스트용)
- 두 VM에 **iperf3**, **jq** 설치: `sudo apt install -y iperf3 jq`
- NIC가 enp2s0가 아니면: `export VM_ETH=본인NIC`

---

## 실행 (호스트 → VM)

### 1) 호스트에서

```bash
cd vm-test
./run.sh 1
```

- 큐 **1** → default(CONFIG=A) 후 tuned(CONFIG=B)
- 큐 **2** → default(C-1) 후 tuned(D-1)
- 큐 **4** → default(C-2) 후 tuned(D-2)

스크립트가 `test/02_restore_defaults.sh` 실행 후 **3분 대기** → default 측정 안내 출력.

### 2) VM에서 default 측정

- **서버 VM:** 안내된 폴더에서 `./server.sh`
- **클라이언트 VM:** 같은 폴더에서 `export SERVER_IP=<서버IP>` 후 `./client.sh`

측정이 끝나면 **호스트 터미널에서 Enter** 입력.

### 3) 호스트에서 tuned 적용

스크립트가 `test/01_apply_tuning.sh` 실행 후 **3분 대기** → tuned 측정 안내 출력.

### 4) VM에서 tuned 측정

- **서버 VM:** 안내된 tuned 폴더에서 `./server.sh`
- **클라이언트 VM:** 같은 폴더에서 `export SERVER_IP=<서버IP>` 후 `./client.sh`

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
`test/05_summarize.sh` 를 쓰려면 `result/날짜_시간/CONFIG/run1/` 아래에 이 JSON들을 복사한 뒤 `./test/05_summarize.sh` 실행.

## NIC 이름

기본값은 `enp2s0`. 다르면 서버/클라이언트 VM 모두 `export VM_ETH=ens3` 등으로 설정 후 `./server.sh`, `./client.sh` 실행.
