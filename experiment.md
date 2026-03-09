

# KubeVirt 실험 보충 가이드: SUSE 환경 도구 반입 전략 --- ## 1. 문제 정의 SUSE(SLES/openSUSE) 환경에서는 벤치마크 도구를 자유롭게 설치할 수 없다. | 제약 | 상세 | |------|------| | 패키지 관리자 | zypper 기본 저장소에 sysbench, lmbench, stress-ng, iperf3 등 부재 | | 추가 저장소 | 서브스크립션 또는 보안 정책으로 외부 repo 추가 제한 가능 | | 직접 컴파일 | gcc/make 설치 여부 불확실, 의존성 해결 곤란 | |

pasted

해당 테스트를 자동화해주는 스크립트를 모두 만들어줘

오후 7:32
먼저 문서를 파악하고 적절한 스크립트 구조를 설계하겠습니다.


Check available skills
Check available skills
문서를 분석하고 스크립트를 만들겠습니다. 자동화해야 할 항목들을 정리하면:

사전 검증 (preflight check)
도구 컨테이너 이미지 빌드
Host 벤치마크 자동화 (네트워크 + CPU/Memory)
Guest(VM) 벤치마크 자동화
결과 수집 및 리포트

8개의 파일 생성됨, 명령 실행함
8개의 파일 생성됨, 명령 실행함
Claude의 응답이 중단되었습니다

# KubeVirt 최고 처리량 실험 계획서: Host Kernel + virtio 큐 최적화 --- ## 1. 개요 본 실험은 KubeVirt 환경에서 **Host Kernel 네트워크 파라미터 튜닝**과 **virtio-net Multi-queue 설정**이라는 두 가지 핵심 변수만을 대상으로, 네트워크 처리량 최대화를 위한 최적 조합을 도출한다. | 항목 | 내용 | |------|------| | 플랫폼 | Kubernetes + KubeVirt | | 가상화 스택 | QEMU/KVM (virt-launcher Pod

pasted

이게 내 테스트 실험 계획서인데.. 자동화 스크립트와 함께 실험 과정을 함께 적어줄래? 참고로 나는 harvester를 사용한다는 것을 명심해주고 나는 단순하게 네트워크 처리량만 판단한다는 것 또한 명심해야해.(네트워크에 포커싱을 맞춰야지 다른것에 신경쓰지 말고) 왜 튜닝 값을 그렇게 설정했는지도 함께 설명해줘야돼.. 모든 선택에는 이유가 있어야해!!!

오후 7:39
먼저 문서를 분석하고 스킬을 확인하겠습니다.


Check available skills
Check available skills
좋습니다. 이제 Harvester 환경에서 네트워크 처리량 최적화에 집중한 실험 계획서 + 자동화 스크립트를 docx로 만들겠습니다.


Check environment
Check environment
Claude의 응답이 중단되었습니다
이게 내 테스트 실험 계획서인데.. 자동화 스크립트와 함께 실험 과정을 마크다운 문서로적어줄래? 참고로 나는 harvester를 사용한다는 것을 명심해주고 나는 단순하게 네트워크 처리량만 판단한다는 것 또한 명심해야해.(네트워크에 포커싱을 맞춰야지 다른것에 신경쓰지 말고) 왜 튜닝 값을 그렇게 설정했는지도 함께 설명해줘야돼.. 모든 선택에는 이유가 있어야해!!!

오후 7:40
먼저 두 문서를 꼼꼼히 분석하고 작성하겠습니다.


명령 3개 실행함, 파일 생성됨, 파일 읽음
명령 3개 실행함, 파일 생성됨, 파일 읽음
약 1,300줄 분량의 문서입니다. 구성 핵심을 설명하면:

문서 구조 (7개 섹션)

1. 실험 개요 — "TCP 처리량 하나만" 측정한다는 원칙과 A/B/C/D 4개 구성 요약

2. Harvester 환경 특성 — Harvester 스택 구조 다이어그램, SUSE 제약으로 인해 도구를 컨테이너로 반입해야 하는 이유, 왜 두 VM을 다른 노드에 배치해야 하는지 설명

3. 실험 구성 설계 — 큐 수 서브 구성(C-1~C-4, D-1~D-4) 표와 "왜 큐 수 = vCPU가 이론적 최적인가" 설명

4. 튜닝 값 선정 근거 ← 가장 중요한 섹션. 각 파라미터마다 이유를 명시

rmem_max=64MiB → BDP 계산 근거로 설명
netdev_max_backlog=65536 → 기본값 1000이 버스트에서 드롭 발생하는 이유
busy_poll=50 → vhost-net 환경에서 왜 50μs인지
modprobe vhost_net → 커널 우회 경로의 처리량 차이
5. 실험 절차 — Phase 0~5 단계별 스크립트 포함. 특히 Phase 3 시작 시 기본값 복원이 왜 필수인지 강조

6. 자동화 스크립트 전체 — run_single_test.sh, verify_queues.sh, run_all_experiments.sh, summarize.sh 4개

7. 결과 판단 기준 — H1~H4 가설 채택/보류/기각 기준표, 최종 권고 판단표

Harvester network experiment
문서 · MD 
kubevirt인데 왜 컨테이너 디스크를써? 그게 더 현실성에 떨어지지 않나?

오후 7:50
맞는 지적입니다. 정확히 짚으셨어요.

containerDisk의 문제점:

매 VMI 기동 시마다 이미지를 새로 pull → 초기화 상태로 리셋됨
실제 운영 VM은 PVC(Persistent Volume)에 OS가 설치된 상태로 운영
Harvester 환경에서 실제 워크로드는 Longhorn PVC 기반이 표준
containerDisk는 CI/CD 테스트용이지, 성능 실험의 "현실 재현"과는 거리가 있음
실험 목적에 맞는 올바른 방법:

Harvester에서는 DataVolume + PVC 방식이 현실적입니다.

Harvester 표준 흐름:
  base image (qcow2/iso)
       │
       ▼
  DataVolume (CDI가 PVC로 임포트)
       │
       ▼
  Longhorn PVC (실제 블록 디바이스)
       │
       ▼
  VMI spec.volumes.dataVolume 으로 마운트
다만 실험 전에 먼저 확인하셔야 할 것이 있습니다.

도구(iperf3, ethtool 등)를 어떻게 VM 안에 넣을 계획인가요?

사전에 도구가 설치된 qcow2 이미지를 Harvester에 임포트 (권장 — 현실적이고 재현성 있음)
기본 Ubuntu/CentOS cloud image를 쓰고 cloud-init으로 부팅 시 설치 (인터넷 필요)
기본 이미지 + 별도 data disk에 바이너리 배치
어떤 환경인지에 따라 VMI YAML 구조가 완전히 달라지기 때문에, 이 부분 먼저 알려주시면 해당 방식으로 문서를 다시 작성하겠습니다.

vm이 아니라 그냥 파드 안에 ... 아 그렇네.. 그냥  VM 만들어서 ssh로 하면 되잖아? 굳이?

오후 7:51
맞아요, 정확히 그겁니다.

굳이 복잡하게 할 필요가 없죠.

그냥 하면 되는 것:

VM 두 대 만들기 (Harvester UI 또는 YAML)
       │
       ▼
SSH 접속해서 iperf3 설치
       │
       ▼
iperf3 -s / iperf3 -c 실행
containerDisk, DataVolume, 도구 반입 전략... 이런 복잡한 것들은 "SUSE 노드에 도구를 못 넣는다"는 제약을 VM에까지 잘못 확장해서 생긴 불필요한 복잡도였습니다.

제약 사항을 정리하면:

위치	제약	해결
Harvester 노드 (Host)	SUSE라 패키지 설치 제한	특권 Pod 또는 SSH + sysctl만
VM 내부 (Guest)	제약 없음	그냥 apt/yum으로 설치
실제로 해야 할 것은 딱 세 가지입니다:

Harvester에서 VM 두 대 생성 (Ubuntu cloud image)
SSH 접속 후 apt install -y iperf3 netperf ethtool
스크립트 실행
문서를 이 방향으로 다시 깔끔하게 정리해드릴까요?

다시 보고서 수정해줘

오후 7:52
기존 문서를 먼저 읽고 수정하겠습니다.


Read existing document
Read existing document
전체 구조를 파악했습니다. containerDisk 관련 내용을 모두 제거하고 "VM 직접 생성 → SSH → apt install" 방식으로 전면 재작성하겠습니다.


파일 생성됨, 명령 실행함, 파일 읽음
파일 생성됨, 명령 실행함, 파일 읽음
v2로 전면 재작성했습니다. 핵심 변경 사항은 다음과 같습니다.

제거한 것들

containerDisk 관련 모든 내용 (Dockerfile 빌드, tarball 반입, 에어갭 전략)
도구 컨테이너 이미지 빌드 과정 전체
cloud-init runcmd로 ethtool 설정하는 복잡한 방식
바꾼 것들

이전	이후
containerDisk (ephemeral)	DataVolume + PVC (실제 운영 환경과 동일)
컨테이너 이미지로 도구 반입	cloud-init packages: 로 부팅 시 apt 설치
VMI마다 재생성	VM 한 대 유지하고 SSH로 ethtool -L만 변경
vCPU 변경 시 복잡한 처리	set_vcpu() 함수로 VMI 재생성 명확화
그대로 유지한 것들

튜닝 값별 근거 설명 (BDP 계산, busy_poll 50μs 이유 등)
구성 A/B/C/D 실험 설계 구조
가설 H1~H4 판단 기준
sysctl 기본값 복원이 Phase 3에서 필수인 이유 설명
Harvester network experiment v2
문서 · MD 
그냥 VM안에 직접 접속할때니 그냥 자동화 스크립트를 줘..

오후 8:07
핵심만 뽑아서 실제로 돌리는 스크립트만 드리겠습니다.


5개의 파일 생성됨
5개의 파일 생성됨
이제 01_02_tuning.sh를 apply/restore 두 기능으로 분리하고, 스크립트들을 하나로 묶겠습니다.


명령 2개 실행함, 파일 읽음
명령 2개 실행함, 파일 읽음
총 6개 스크립트입니다. 실행 순서는 이렇습니다.

bash
# 1. 환경변수 설정
export CLIENT_IP=192.168.1.10        # 클라이언트 VM IP
export SERVER_IP=192.168.1.11        # 서버 VM IP
export CLIENT_NODE_IP=10.0.0.1       # 클라이언트 VM이 올라간 Harvester 노드 IP
export SERVER_NODE_IP=10.0.0.2       # 서버 VM이 올라간 Harvester 노드 IP

# 2. 사전 검증 (도구 설치 + sysctl 기준값 저장)
bash 00_preflight.sh

# 3. 전체 실험 자동 실행 (A → B → C → D)
bash 04_run_all.sh

# 4. 결과만 다시 보고 싶을 때
bash 05_summarize.sh /tmp/bench-results
각 스크립트 역할은 다음과 같습니다.

파일	역할
00_preflight.sh	VM에 iperf3/ethtool 설치, sysctl 기준값 저장, vhost_net 확인
01_apply_tuning.sh	Harvester 노드에 sysctl 튜닝 적용 (구성 B, D)
02_restore_defaults.sh	sysctl 기본값 복원 (구성 A, C)
03_run_test.sh	단일 구성 1회 측정 (P=1/4/8 스트림, JSON 저장)
04_run_all.sh	A→B→C→D 전체 자동 실행 오케스트레이터
05_summarize.sh	결과 CSV 취합 + 중앙값 비교표 + 가설 검증 출력
vCPU=8 구성(C-3/C-4, D-3/D-4) 은 04_run_all.sh 안에 주석 처리되어 있습니다. VMI를 vCPU=8로 재생성한 뒤 해당 주석을 풀고 실행하면 됩니다.

00 preflight
SH 
01 apply tuning
SH 
02 restore defaults
SH 
03 run test
SH 
04 run all
SH 
05 summarize
SH 
그냥 테스트는 4vCPU 8GB로만 할건데

오후 8:16

Read current run_all script
Read current run_all script
4vCPU 고정이면 구성도 단순해집니다. vCPU 변경 없이 큐는 1, 2, 4만 테스트하면 됩니다.


Simplify to 4vCPU only - remove all vCPU=8 configs
Simplify to 4vCPU only - remove all vCPU=8 configs
05_summarize.sh도 구성 목록에서 C-3/C-4, D-3/D-4 제거하겠습니다.


파일 수정됨, 명령 실행함, 파일 읽음
파일 수정됨, 명령 실행함, 파일 읽음
4vCPU 고정 기준으로 정리된 최종 구성입니다.

구성	sysctl	큐 수
A	기본값	1
B	튜닝	1
C-1	기본값	2
C-2	기본값	4 (= vCPU)
D-1	튜닝	2
D-2	튜닝	4 (= vCPU)
04 run all
SH 
05 summarize
SH 
참고로 우리 튜닝 기본값은 

세 노드 모두 **동일한 값**으로 기록됨.

| 파라미터 | 값 |
|----------|-----|
| `net.core.rmem_max` | 212992 |
| `net.core.wmem_max` | 212992 |
| `net.core.rmem_default` | 212992 |
| `net.core.wmem_default` | 212992 |
| `net.core.netdev_max_backlog` | 1000 |
| `net.core.busy_poll` | 0 |
| `net.ipv4.tcp_rmem` | 4096 131072 6291456 |
| `net.ipv4.tcp_wmem` | 4096 16384 4194304 | 이거야..
더 보기
오후 8:20
확인했습니다. 02_restore_defaults.sh를 파일 기반 복원 대신 이 값을 하드코딩으로 바꾸겠습니다. 더 안전하고 명확합니다.


Hardcode actual baseline sysctl values
Hardcode actual baseline sysctl values
00_preflight.sh에서도 이제 기준값 저장 부분은 불필요하니 제거합니다.


파일 수정됨, 명령 실행함, 파일 읽음
파일 수정됨, 명령 실행함, 파일 읽음
두 파일 업데이트했습니다.

02_restore_defaults.sh는 이제 파일 읽기 방식 대신 실제 기본값을 하드코딩해서 복원합니다. somaxconn은 기본값 제공이 없어서 일부러 빠뜨렸는데, 필요하시면 알려주세요. 00_preflight.sh에서는 기준값 저장 단계도 제거해서 더 간결해졌습니다.

02 restore defaults
SH 
00 preflight
SH 
해당 실험에 CPu도 측정해야 할까?

오후 8:24
아니요, 안 해도 됩니다.

이유:

목표가 "TCP 처리량 최대화"이면 CPU는 결과가 아니라 수단입니다. CPU를 얼마나 쓰든 처리량이 높으면 그 구성이 이기는 겁니다.

CPU 측정이 의미 있는 경우는 따로 있습니다:

처리량이 비슷할 때 — 예를 들어 C-2와 D-2가 둘 다 9.5 Gbps면 CPU를 덜 쓰는 쪽이 더 효율적이라는 판단을 내릴 수 있음
CPU가 병목인지 확인하고 싶을 때 — 처리량이 기대보다 낮게 나왔는데 왜 그런지 원인을 파야 할 때
지금 실험 설계는 구성 간 처리량 차이가 명확하게 날 가능성이 높아서 CPU까지 볼 필요가 없습니다. 처리량 결과가 나온 뒤에 "왜 이렇게 나왔지?"가 궁금해지면 그때 추가로 측정하는 게 낫습니다.

somaxconn은 기본값 제공이 없어서 일부러 빠뜨렸는데, 필요하시면 알려주세요 -> 이것도 굳이 설정해야 하니?

오후 8:28
필요 없습니다.

somaxconn은 서버가 accept 대기할 수 있는 연결 수 상한인데, iperf3는 연결을 한 번 맺고 60초 동안 데이터만 보냅니다. 연결이 폭발적으로 들어오는 웹서버 시나리오가 아니라서 기본값 128로도 전혀 문제없습니다.

01_apply_tuning.sh에서도 빼겠습니다.


명령 2개 실행함, 파일 수정됨, 파일 읽음
명령 2개 실행함, 파일 수정됨, 파일 읽음
제거했습니다. 최종 튜닝 파라미터는 이 6개만 남습니다.

파라미터	튜닝값	기본값
rmem_max / wmem_max	64 MiB	212992
rmem_default / wmem_default	32 MiB	212992
tcp_rmem / tcp_wmem	상한 64 MiB	상한 6/4 MiB
netdev_max_backlog	65536	1000
busy_poll / busy_read	50 μs	0
vhost_net	modprobe	(확인용)
01 apply tuning
SH 




Claude는 AI이며 실수할 수 있습니다. 응답을 다시 한번 확인해 주세요.
붙여넣은 내용
24.05 KB •803줄
•
원본과 형식이 일치하지 않을 수 있습니다
# KubeVirt 최고 처리량 실험 계획서: Host Kernel + virtio 큐 최적화

---

## 1. 개요

본 실험은 KubeVirt 환경에서 **Host Kernel 네트워크 파라미터 튜닝**과 **virtio-net Multi-queue 설정**이라는 두 가지 핵심 변수만을 대상으로, 네트워크 처리량 최대화를 위한 최적 조합을 도출한다.

| 항목 | 내용 |
|------|------|
| 플랫폼 | Kubernetes + KubeVirt |
| 가상화 스택 | QEMU/KVM (virt-launcher Pod) |
| 튜닝 대상 | Host Kernel sysctl / virtio-net queue 수 |
| Guest OS | Linux (Ubuntu 22.04 또는 CentOS Stream 9) |

---

## 2. 실험 목적

1. Host Kernel 튜닝과 virtio 큐 설정 각각의 **개별 효과**를 정량화한다.
2. 두 설정을 조합했을 때의 **복합 효과**를 측정한다.
3. 프로덕션에 즉시 적용 가능한 **최소한의 튜닝 셋**을 확정한다.

---

## 3. 의사결정 대상 정의

| 의사결정 항목 | 선택지 |
|--------------|--------|
| Host Kernel 네트워크 버퍼 튜닝 적용 여부 | Default vs Optimized sysctl |
| virtio-net Multi-queue 활성화 여부 | 단일 큐(1) vs Multi-queue(vCPU 수) |
| 최적 큐 개수 | 1 / 2 / 4 / 8 (vCPU 수 대비) |
| 두 설정의 동시 적용 필요성 | 개별 적용 충분 vs 반드시 조합 필요 |

---

## 4. 실험 범위 및 비교 대상

### 4.1 실험 범위

**In-Scope**: Host Kernel sysctl 파라미터, vhost-net 모듈, virtio-net 큐 수 설정

**Out-of-Scope**: CPU Pinning, Hugepages, NUMA, SR-IOV, 디스크 I/O, I/O 스케줄러, Guest Kernel 튜닝

### 4.2 비교 대상 (4개 구성)

| # | 구성명 | Host Kernel | virtio 큐 | 설명 |
|---|--------|------------|-----------|------|
| A | Baseline | Default | 단일 큐 (1) | KubeVirt 기본 설치 상태 |
| B | Kernel Only | **Optimized** | 단일 큐 (1) | Host sysctl만 튜닝 |
| C | Queue Only | Default | **Multi-queue** | virtio 큐만 활성화 |
| D | Kernel + Queue | **Optimized** | **Multi-queue** | 두 설정 동시 적용 |

추가로 구성 C, D에서 큐 개수를 변화시켜 최적 값을 탐색한다.

| 서브 구성 | vCPU | 큐 수 |
|-----------|------|-------|
| C-1 / D-1 | 4 | 2 |
| C-2 / D-2 | 4 | 4 |
| C-3 / D-3 | 8 | 4 |
| C-4 / D-4 | 8 | 8 |

---

## 5. 실험 가설

| 가설 | 내용 | 채택 기준 |
|------|------|----------|
| H1 | Host Kernel 튜닝(B)은 Baseline(A) 대비 처리량 **20% 이상** 향상시킨다 | ΔThroughput ≥ 20% |
| H2 | Multi-queue(C)는 Baseline(A) 대비 처리량 **40% 이상** 향상시킨다 (4+ vCPU) | ΔThroughput ≥ 40% |
| H3 | Kernel + Queue(D)의 복합 효과는 개별 효과의 합보다 크다 (시너지 존재) | D > B + C - A |
| H4 | 최적 큐 수는 vCPU 수와 동일할 때 처리량이 최대이다 | queue=vCPU일 때 max throughput |

---

## 6. 측정 항목 및 측정 방법

### 6.1 측정 항목 총괄표

| # | 측정 항목 | 단위 | 도구 | 수집 위치 | 수집 주기 |
|---|----------|------|------|----------|----------|
| M1 | TCP 처리량 | Gbps | iperf3 | Guest (송신/수신) | 테스트당 1회 (60초 평균) |
| M2 | UDP 처리량 / PPS | Gbps / Mpps | iperf3 | Guest (송신/수신) | 테스트당 1회 (60초 평균) |
| M3 | 요청-응답 지연시간 | μs | netperf TCP_RR | Guest | 테스트당 1회 (P50/P99/P99.9) |
| M4 | Host CPU 사용률 | % (per core) | mpstat | Host | 1초 간격 연속 수집 |
| M5 | Guest CPU 사용률 | % (per vCPU) | mpstat | Guest | 1초 간격 연속 수집 |
| M6 | 인터럽트 카운트 | count/core | /proc/interrupts | Host + Guest | 테스트 전/후 스냅샷 (delta 계산) |
| M7 | 소프트IRQ 처리량 | count/core | /proc/softirqs | Host + Guest | 테스트 전/후 스냅샷 (delta 계산) |
| M8 | 패킷 드롭/에러 | count | ethtool -S / /proc/net/dev | Host + Guest | 테스트 전/후 스냅샷 (delta 계산) |
| M9 | virtio 큐 상태 | count/queue | ethtool -S (per-queue stats) | Guest | 테스트 전/후 스냅샷 (delta 계산) |
| M10 | vhost 스레드 CPU 사용 | % | pidstat | Host (vhost-net PID) | 1초 간격 연속 수집 |

### 6.2 각 측정 항목별 상세 측정 방법

#### M1: TCP 처리량 측정

**목적**: 다양한 병렬 스트림 수에서 최대 TCP 대역폭 확인

**수신 VM (서버)**:

```bash
# 포트 5201에서 대기
iperf3 -s -p 5201 --json --logfile /tmp/iperf3_server_${CONFIG}_${RUN}.json
```

**송신 VM (클라이언트)**:

```bash
# 단일 스트림
iperf3 -c ${SERVER_IP} -p 5201 -t 60 -P 1 --json \
  > /tmp/iperf3_tcp_P1_${CONFIG}_${RUN}.json

# 4 병렬 스트림
iperf3 -c ${SERVER_IP} -p 5201 -t 60 -P 4 --json \
  > /tmp/iperf3_tcp_P4_${CONFIG}_${RUN}.json

# 8 병렬 스트림
iperf3 -c ${SERVER_IP} -p 5201 -t 60 -P 8 --json \
  > /tmp/iperf3_tcp_P8_${CONFIG}_${RUN}.json
```

**결과 추출**:

```bash
# JSON에서 처리량 추출 (bits_per_second → Gbps 변환)
jq '.end.sum_received.bits_per_second / 1e9' /tmp/iperf3_tcp_P4_${CONFIG}_${RUN}.json
```

**기록 형식**:

| 구성 | 스트림 수 | Run# | Throughput(Gbps) | Retransmits | CPU Sender(%) | CPU Receiver(%) |
|------|----------|------|-----------------|-------------|--------------|----------------|
| A | 1 | 1 | | | | |

---

#### M2: UDP 처리량 / PPS 측정

**목적**: 소형 패킷에서의 패킷 처리 능력 및 손실률 확인

**수신 VM**:

```bash
iperf3 -s -p 5202 --json --logfile /tmp/iperf3_udp_server_${CONFIG}_${RUN}.json
```

**송신 VM**:

```bash
# 64바이트 패킷, 대역폭 제한 없음
iperf3 -c ${SERVER_IP} -p 5202 -u -l 64 -b 0 -t 60 --json \
  > /tmp/iperf3_udp_64B_${CONFIG}_${RUN}.json

# 1400바이트 패킷 (MTU 근접)
iperf3 -c ${SERVER_IP} -p 5202 -u -l 1400 -b 0 -t 60 --json \
  > /tmp/iperf3_udp_1400B_${CONFIG}_${RUN}.json
```

**결과 추출**:

```bash
# 처리량 (Gbps)
jq '.end.sum.bits_per_second / 1e9' /tmp/iperf3_udp_64B_${CONFIG}_${RUN}.json

# PPS 계산: bits_per_second / (packet_size_bits)
jq '.end.sum.bits_per_second / (64 * 8)' /tmp/iperf3_udp_64B_${CONFIG}_${RUN}.json

# 패킷 손실률
jq '.end.sum.lost_percent' /tmp/iperf3_udp_64B_${CONFIG}_${RUN}.json
```

**기록 형식**:

| 구성 | 패킷 크기 | Run# | Throughput(Gbps) | PPS(Mpps) | Lost(%) | Jitter(ms) |
|------|----------|------|-----------------|-----------|---------|-----------|
| A | 64B | 1 | | | | |

---

#### M3: 요청-응답 지연시간 측정

**목적**: 단일 요청-응답 왕복 지연시간의 분포(P50/P99/P99.9) 확인

**수신 VM**:

```bash
netserver -p 12865
```

**송신 VM**:

```bash
# TCP Request-Response (1바이트 요청, 1바이트 응답)
netperf -H ${SERVER_IP} -p 12865 -t TCP_RR -l 60 \
  -- -o min_latency,mean_latency,p50_latency,p99_latency,p999_latency,max_latency,stddev_latency \
  > /tmp/netperf_tcprr_${CONFIG}_${RUN}.txt

# 트랜잭션 레이트 (TPS)도 함께 기록
netperf -H ${SERVER_IP} -p 12865 -t TCP_RR -l 60 \
  > /tmp/netperf_tcprr_tps_${CONFIG}_${RUN}.txt
```

**대안: sockperf를 사용한 정밀 측정 (μs 단위)**:

```bash
# 수신 VM
sockperf sr --tcp -p 11111

# 송신 VM: ping-pong 모드
sockperf pp --tcp -i ${SERVER_IP} -p 11111 -t 60 \
  --full-log /tmp/sockperf_${CONFIG}_${RUN}.csv

# 결과에서 백분위수 추출
sockperf pp --tcp -i ${SERVER_IP} -p 11111 -t 60 2>&1 | \
  grep -E "percentile|avg-latency|max-latency"
```

**기록 형식**:

| 구성 | Run# | TPS | Avg(μs) | P50(μs) | P99(μs) | P99.9(μs) | Max(μs) | StdDev(μs) |
|------|------|-----|---------|---------|---------|-----------|---------|-----------|
| A | 1 | | | | | | | |

---

#### M4/M5: CPU 사용률 측정 (Host / Guest)

**목적**: 처리량 달성 시 소모되는 CPU 리소스를 파악하여 "Gbps per CPU%" 효율 비교

**Host 측 (테스트 시작 전 별도 터미널에서 실행)**:

```bash
# 1초 간격으로 코어별 CPU 사용률 수집, 테스트 종료 시 Ctrl+C
mpstat -P ALL 1 > /tmp/host_mpstat_${CONFIG}_${RUN}.log &
MPSTAT_HOST_PID=$!

# 테스트 종료 후
kill $MPSTAT_HOST_PID
```

**Guest 측 (VM 내부에서 실행)**:

```bash
mpstat -P ALL 1 > /tmp/guest_mpstat_${CONFIG}_${RUN}.log &
MPSTAT_GUEST_PID=$!

# 테스트 종료 후
kill $MPSTAT_GUEST_PID
```

**결과 추출**:

```bash
# 전체 코어 평균 사용률 (테스트 구간만 필터)
awk '/Average:/ && /all/' /tmp/host_mpstat_${CONFIG}_${RUN}.log

# 코어별 사용률 확인 (인터럽트 편중 여부)
awk '/Average:/ && !/all/' /tmp/host_mpstat_${CONFIG}_${RUN}.log | \
  sort -k3 -nr | head -5
```

**기록 형식**:

| 구성 | Run# | Host CPU Avg(%) | Host %soft(%) | Guest CPU Avg(%) | 처리량(Gbps) | 효율(Gbps/CPU%) |
|------|------|----------------|--------------|-----------------|-------------|----------------|
| A | 1 | | | | | |

---

#### M6/M7: 인터럽트 및 소프트IRQ 측정

**목적**: Multi-queue 활성화 시 인터럽트가 코어에 균등 분배되는지 확인

**수집 스크립트** (Host와 Guest 양쪽에서 실행):

```bash
#!/bin/bash
# collect_irq.sh - 테스트 전/후 스냅샷 수집
LABEL=$1  # "before" or "after"
CONFIG=$2
RUN=$3

# 하드 인터럽트
cat /proc/interrupts > /tmp/interrupts_${LABEL}_${CONFIG}_${RUN}.txt

# 소프트 인터럽트
cat /proc/softirqs > /tmp/softirqs_${LABEL}_${CONFIG}_${RUN}.txt
```

**실행 타이밍**:

```bash
# 1) 테스트 직전 스냅샷
./collect_irq.sh before ${CONFIG} ${RUN}

# 2) iperf3/netperf 테스트 실행 (60초)
iperf3 -c ${SERVER_IP} -t 60 -P 4 ...

# 3) 테스트 직후 스냅샷
./collect_irq.sh after ${CONFIG} ${RUN}
```

**delta 계산 스크립트**:

```bash
#!/bin/bash
# calc_irq_delta.sh - virtio 관련 인터럽트 delta 계산
CONFIG=$1
RUN=$2

echo "=== IRQ Delta (${CONFIG} Run${RUN}) ==="
paste \
  <(grep virtio /tmp/interrupts_before_${CONFIG}_${RUN}.txt) \
  <(grep virtio /tmp/interrupts_after_${CONFIG}_${RUN}.txt) | \
awk '{
  name = $NF;
  for (i=2; i<=NF/2-1; i++) {
    before[i] = $i;
    after[i] = $(i + NF/2);
    delta[i] = after[i] - before[i];
  }
  printf "%s: ", name;
  for (i=2; i<=NF/2-1; i++) printf "CPU%d=%d ", i-2, delta[i];
  print "";
}'
```

**기록 형식**:

| 구성 | Run# | virtio큐 | CPU0 IRQ | CPU1 IRQ | CPU2 IRQ | CPU3 IRQ | 분산 균등성(StdDev) |
|------|------|---------|---------|---------|---------|---------|-------------------|
| A (큐1) | 1 | | | | | | |
| C (큐4) | 1 | | | | | | |

---

#### M8: 패킷 드롭/에러 측정

**목적**: 튜닝 전후로 패킷 손실이 발생하는지 확인

**수집 스크립트** (Host와 Guest 양쪽):

```bash
#!/bin/bash
# collect_drop.sh
LABEL=$1; CONFIG=$2; RUN=$3

# /proc/net/dev 스냅샷
cat /proc/net/dev > /tmp/netdev_${LABEL}_${CONFIG}_${RUN}.txt

# ethtool 통계 (NIC 이름에 맞게 수정)
ethtool -S eth0 > /tmp/ethtool_${LABEL}_${CONFIG}_${RUN}.txt 2>/dev/null
```

**delta 계산**:

```bash
#!/bin/bash
# calc_drop_delta.sh
CONFIG=$1; RUN=$2

echo "=== Packet Drop Delta ==="
# 수신 드롭
RX_DROP_BEFORE=$(awk '/eth0/ {print $5}' /tmp/netdev_before_${CONFIG}_${RUN}.txt)
RX_DROP_AFTER=$(awk '/eth0/ {print $5}' /tmp/netdev_after_${CONFIG}_${RUN}.txt)
echo "RX drop: $((RX_DROP_AFTER - RX_DROP_BEFORE))"

# 송신 드롭
TX_DROP_BEFORE=$(awk '/eth0/ {print $13}' /tmp/netdev_before_${CONFIG}_${RUN}.txt)
TX_DROP_AFTER=$(awk '/eth0/ {print $13}' /tmp/netdev_after_${CONFIG}_${RUN}.txt)
echo "TX drop: $((TX_DROP_AFTER - TX_DROP_BEFORE))"

# ethtool에서 rx_dropped, tx_dropped 비교
diff \
  <(grep -E "rx_dropped|tx_dropped|rx_over_errors" /tmp/ethtool_before_${CONFIG}_${RUN}.txt) \
  <(grep -E "rx_dropped|tx_dropped|rx_over_errors" /tmp/ethtool_after_${CONFIG}_${RUN}.txt)
```

**기록 형식**:

| 구성 | Run# | RX Drop | TX Drop | RX Errors | RX Over Errors |
|------|------|---------|---------|-----------|---------------|
| A | 1 | 0 | 0 | 0 | 0 |

---

#### M9: virtio 큐별 통계 측정

**목적**: Multi-queue 활성화 시 큐 간 트래픽 분배 균형 확인

**Guest 내부에서 수집**:

```bash
#!/bin/bash
# collect_virtio_queue.sh
LABEL=$1; CONFIG=$2; RUN=$3

# ethtool per-queue 통계
ethtool -S eth0 | grep -E "^(rx|tx)_queue" \
  > /tmp/virtio_queue_${LABEL}_${CONFIG}_${RUN}.txt
```

**delta 계산 및 분석**:

```bash
#!/bin/bash
# calc_queue_balance.sh - 큐 간 균형도 계산
CONFIG=$1; RUN=$2

echo "=== Per-Queue RX Packets Delta ==="
paste \
  <(grep rx_queue /tmp/virtio_queue_before_${CONFIG}_${RUN}.txt | awk -F: '{print $2}') \
  <(grep rx_queue /tmp/virtio_queue_after_${CONFIG}_${RUN}.txt | awk -F: '{print $2}') | \
awk '{
  delta = $2 - $1;
  sum += delta;
  count++;
  values[count] = delta;
  printf "Queue %d: %d packets\n", count-1, delta;
}
END {
  mean = sum / count;
  for (i=1; i<=count; i++) sumsq += (values[i]-mean)^2;
  stddev = sqrt(sumsq/count);
  printf "Mean: %.0f, StdDev: %.0f, CV: %.2f%%\n", mean, stddev, (stddev/mean)*100;
}'
```

**기록 형식**:

| 구성 | 큐 수 | Run# | Q0 Pkts | Q1 Pkts | Q2 Pkts | Q3 Pkts | CV(%) |
|------|------|------|---------|---------|---------|---------|-------|
| C-2 | 4 | 1 | | | | | |

> CV(Coefficient of Variation)가 낮을수록 큐 간 분배가 균등함. 목표: CV < 20%

---

#### M10: vhost 스레드 CPU 사용 측정

**목적**: Host에서 vhost-net 커널 스레드의 CPU 소모량을 파악

**Host에서 실행**:

```bash
# vhost 스레드 PID 확인
VHOST_PIDS=$(pgrep -f "vhost-" | tr '\n' ',')
echo "vhost PIDs: ${VHOST_PIDS}"

# pidstat으로 1초 간격 수집
pidstat -p ${VHOST_PIDS} 1 > /tmp/vhost_pidstat_${CONFIG}_${RUN}.log &
PIDSTAT_PID=$!

# 테스트 종료 후
kill $PIDSTAT_PID
```

**결과 추출**:

```bash
# 평균 CPU 사용률
awk '/Average:/ && /vhost/' /tmp/vhost_pidstat_${CONFIG}_${RUN}.log
```

**기록 형식**:

| 구성 | Run# | vhost 스레드 수 | 총 vhost CPU(%) | Throughput(Gbps) | vhost 효율(Gbps/vhost%) |
|------|------|---------------|----------------|-----------------|----------------------|
| A | 1 | | | | |

---

### 6.3 전체 측정 자동화 통합 스크립트

아래 스크립트는 하나의 구성에 대해 전체 측정을 자동으로 수행한다.

```bash
#!/bin/bash
# run_test.sh - 단일 구성/단일 실행 전체 측정
# Usage: ./run_test.sh <CONFIG> <RUN> <SERVER_IP>

CONFIG=$1
RUN=$2
SERVER_IP=$3
DURATION=60
RESULT_DIR="/tmp/results/${CONFIG}/run${RUN}"
mkdir -p ${RESULT_DIR}

echo "=========================================="
echo " Config: ${CONFIG}, Run: ${RUN}"
echo " Target: ${SERVER_IP}"
echo "=========================================="

# --- (1) 테스트 전 스냅샷 수집 ---
echo "[PRE] Collecting pre-test snapshots..."
cat /proc/interrupts > ${RESULT_DIR}/interrupts_before.txt
cat /proc/softirqs > ${RESULT_DIR}/softirqs_before.txt
cat /proc/net/dev > ${RESULT_DIR}/netdev_before.txt
ethtool -S eth0 > ${RESULT_DIR}/ethtool_before.txt 2>/dev/null
ethtool -S eth0 | grep -E "^(rx|tx)_queue" > ${RESULT_DIR}/virtio_queue_before.txt 2>/dev/null

# --- (2) 백그라운드 모니터링 시작 ---
echo "[MON] Starting background monitors..."
mpstat -P ALL 1 > ${RESULT_DIR}/mpstat.log &
PID_MPSTAT=$!

VHOST_PIDS=$(pgrep -f "vhost-" | tr '\n' ',' | sed 's/,$//')
if [ -n "$VHOST_PIDS" ]; then
  pidstat -p ${VHOST_PIDS} 1 > ${RESULT_DIR}/vhost_pidstat.log &
  PID_PIDSTAT=$!
fi

# --- (3) 네트워크 테스트 실행 ---
echo "[TEST] Running TCP tests..."
for STREAMS in 1 4 8; do
  echo "  TCP P=${STREAMS}..."
  iperf3 -c ${SERVER_IP} -p 5201 -t ${DURATION} -P ${STREAMS} --json \
    > ${RESULT_DIR}/iperf3_tcp_P${STREAMS}.json
  sleep 10
done

echo "[TEST] Running UDP tests..."
for PKT_SIZE in 64 1400; do
  echo "  UDP ${PKT_SIZE}B..."
  iperf3 -c ${SERVER_IP} -p 5202 -u -l ${PKT_SIZE} -b 0 -t ${DURATION} --json \
    > ${RESULT_DIR}/iperf3_udp_${PKT_SIZE}B.json
  sleep 10
done

echo "[TEST] Running latency test..."
netperf -H ${SERVER_IP} -p 12865 -t TCP_RR -l ${DURATION} \
  -- -o min_latency,mean_latency,p50_latency,p99_latency,max_latency \
  > ${RESULT_DIR}/netperf_tcprr.txt
sleep 5

# --- (4) 백그라운드 모니터링 종료 ---
echo "[MON] Stopping monitors..."
kill $PID_MPSTAT 2>/dev/null
[ -n "$PID_PIDSTAT" ] && kill $PID_PIDSTAT 2>/dev/null

# --- (5) 테스트 후 스냅샷 수집 ---
echo "[POST] Collecting post-test snapshots..."
cat /proc/interrupts > ${RESULT_DIR}/interrupts_after.txt
cat /proc/softirqs > ${RESULT_DIR}/softirqs_after.txt
cat /proc/net/dev > ${RESULT_DIR}/netdev_after.txt
ethtool -S eth0 > ${RESULT_DIR}/ethtool_after.txt 2>/dev/null
ethtool -S eth0 | grep -E "^(rx|tx)_queue" > ${RESULT_DIR}/virtio_queue_after.txt 2>/dev/null

# --- (6) 결과 요약 출력 ---
echo ""
echo "========== SUMMARY =========="
echo "[TCP Throughput]"
for STREAMS in 1 4 8; do
  TPUT=$(jq '.end.sum_received.bits_per_second / 1e9' ${RESULT_DIR}/iperf3_tcp_P${STREAMS}.json 2>/dev/null)
  RETRANS=$(jq '.end.sum_sent.retransmits // 0' ${RESULT_DIR}/iperf3_tcp_P${STREAMS}.json 2>/dev/null)
  echo "  P=${STREAMS}: ${TPUT} Gbps, Retransmits: ${RETRANS}"
done

echo "[UDP]"
for PKT_SIZE in 64 1400; do
  TPUT=$(jq '.end.sum.bits_per_second / 1e9' ${RESULT_DIR}/iperf3_udp_${PKT_SIZE}B.json 2>/dev/null)
  LOSS=$(jq '.end.sum.lost_percent' ${RESULT_DIR}/iperf3_udp_${PKT_SIZE}B.json 2>/dev/null)
  echo "  ${PKT_SIZE}B: ${TPUT} Gbps, Loss: ${LOSS}%"
done

echo "[Latency]"
cat ${RESULT_DIR}/netperf_tcprr.txt

echo "[CPU Avg]"
awk '/Average:/ && /all/' ${RESULT_DIR}/mpstat.log

echo ""
echo "Results saved to: ${RESULT_DIR}/"
echo "=========================================="
```

### 6.4 수신 VM(서버) 측 준비 스크립트

```bash
#!/bin/bash
# start_servers.sh - 수신 VM에서 실행
echo "Starting iperf3 servers..."
iperf3 -s -p 5201 -D  # TCP용 (데몬 모드)
iperf3 -s -p 5202 -D  # UDP용

echo "Starting netserver..."
netserver -p 12865

echo "All servers ready."
echo "  iperf3 TCP: port 5201"
echo "  iperf3 UDP: port 5202"
echo "  netperf:    port 12865"
```

---

## 7. 실험 절차

### Phase 0: 환경 준비 (1~2일)

1. 테스트 노드 2대 확보 (동일 사양, 동일 NUMA 구성)
2. KubeVirt 설치 및 Guest OS 이미지 준비
3. Guest 내부에 도구 설치: `iperf3`, `netperf`, `sockperf`, `ethtool`, `sysstat(mpstat)`, `jq`
4. 위 섹션 6.3/6.4의 측정 스크립트를 Guest/Host에 배포
5. 예비 테스트 실행으로 스크립트 동작 검증

### Phase 1: Baseline 측정 — 구성 A (1일)

기본 VMI로 VM 생성:

```yaml
spec:
  domain:
    cpu:
      cores: 4    # 이후 8로 변경하여 반복
    memory:
      guest: 8Gi
    devices:
      interfaces:
        - name: default
          masquerade: {}
```

**측정 절차**:

```
1. 수신 VM: start_servers.sh 실행
2. Host: 현재 sysctl 값 기록 (sysctl -a > baseline_sysctl.txt)
3. Guest: ethtool -l eth0 로 현재 큐 수 확인/기록
4. 송신 VM: run_test.sh A 1 ${SERVER_IP}
5. 30초 쿨다운
6. 송신 VM: run_test.sh A 2 ${SERVER_IP}
7. 30초 쿨다운
8. 송신 VM: run_test.sh A 3 ${SERVER_IP}
9. vCPU=8로 VM 재생성 후 1~8 반복
```

### Phase 2: Host Kernel 튜닝 — 구성 B (1일)

**튜닝 적용**:

```bash
# tune_host_kernel.sh
sysctl -w net.core.rmem_max=67108864
sysctl -w net.core.wmem_max=67108864
sysctl -w net.core.rmem_default=33554432
sysctl -w net.core.wmem_default=33554432
sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
sysctl -w net.core.netdev_max_backlog=65536
sysctl -w net.core.somaxconn=65536
sysctl -w net.core.busy_poll=50
sysctl -w net.core.busy_read=50
modprobe vhost_net

# 적용 확인
sysctl net.core.rmem_max net.core.wmem_max net.core.netdev_max_backlog
lsmod | grep vhost
```

**측정**: 구성 A와 동일한 VMI(단일 큐)로 run_test.sh B {1,2,3} 실행

### Phase 3: virtio Multi-queue 단독 — 구성 C (1일)

**Host sysctl 복원**:

```bash
# restore_host_kernel.sh
sysctl -w net.core.rmem_max=212992        # 배포판 기본값 확인 후 설정
sysctl -w net.core.wmem_max=212992
# ... (Phase 0에서 기록한 baseline_sysctl.txt 기반 복원)
```

**Multi-queue VMI 생성**:

```yaml
spec:
  domain:
    cpu:
      cores: 4
    memory:
      guest: 8Gi
    devices:
      networkInterfaceMultiqueue: true
      interfaces:
        - name: default
          model: virtio
          masquerade: {}
```

**큐 수 확인 및 조정**:

```bash
# Guest 내부
ethtool -l eth0                    # 현재/최대 큐 수 확인
ethtool -L eth0 combined 2         # 큐 2개로 설정 → 테스트
ethtool -L eth0 combined 4         # 큐 4개로 설정 → 테스트
```

**측정**: 큐 수(2, 4)별로 각각 run_test.sh C-1 {1,2,3}, run_test.sh C-2 {1,2,3} 실행. vCPU=8로 VM 재생성 후 큐 수(4, 8)별 반복.

### Phase 4: 복합 적용 — 구성 D (1일)

Phase 2의 `tune_host_kernel.sh` + Phase 3의 Multi-queue VMI를 동시 적용.

큐 수별로 run_test.sh D-1 ~ D-4 각 3회 실행.

### Phase 5: 결과 분석 (1일)

**결과 취합 스크립트**:

```bash
#!/bin/bash
# summarize_results.sh - 전체 결과를 CSV로 취합
echo "Config,Streams,Run,TCP_Gbps,Retransmits,UDP64_Gbps,UDP64_Loss,Latency_P99_us,Host_CPU,Guest_CPU"

for CONFIG in A B C-1 C-2 C-3 C-4 D-1 D-2 D-3 D-4; do
  for RUN in 1 2 3; do
    DIR="/tmp/results/${CONFIG}/run${RUN}"
    [ -d "$DIR" ] || continue

    for STREAMS in 1 4 8; do
      TCP=$(jq -r '.end.sum_received.bits_per_second / 1e9' ${DIR}/iperf3_tcp_P${STREAMS}.json 2>/dev/null)
      RETRANS=$(jq -r '.end.sum_sent.retransmits // 0' ${DIR}/iperf3_tcp_P${STREAMS}.json 2>/dev/null)
      UDP64=$(jq -r '.end.sum.bits_per_second / 1e9' ${DIR}/iperf3_udp_64B.json 2>/dev/null)
      UDP64_LOSS=$(jq -r '.end.sum.lost_percent' ${DIR}/iperf3_udp_64B.json 2>/dev/null)
      P99=$(awk 'NR==3 {print $4}' ${DIR}/netperf_tcprr.txt 2>/dev/null)
      HOST_CPU=$(awk '/Average:/ && /all/ {print $3+$5}' ${DIR}/mpstat.log 2>/dev/null | tail -1)

      echo "${CONFIG},${STREAMS},${RUN},${TCP},${RETRANS},${UDP64},${UDP64_LOSS},${P99},${HOST_CPU},"
    done
  done
done
```

**분석 항목**:

1. 구성 A/B/C/D 처리량 비교 표 및 그래프 작성
2. 가설 H1~H4 검증 (중앙값 기준)
3. 큐 수별 처리량 스케일링 곡선
4. 인터럽트 분배 균등성 비교 (단일 큐 vs Multi-queue)
5. CPU 효율 비교 (Gbps per CPU%)
6. 최적 구성 확정 및 권고안 도출

### 실험 제어 조건

| 항목 | 기준 |
|------|------|
| 반복 횟수 | 3회, 중앙값 채택 |
| 측정 시간 | 각 테스트 60초 (처음 10초는 워밍업으로 iperf3가 자동 제외) |
| 쿨다운 | 테스트 간 30초, 구성 변경 간 60초 대기 |
| 노이즈 제거 | 전용 노드, 타 워크로드 없음 |
| 변수 고정 | 한 번에 하나의 변수만 변경 |
| 유효성 검증 | 3회 측정의 표준편차가 평균의 5% 초과 시 추가 2회 반복 |

---

## 8. 판단 기준

### 8.1 가설 판단

| 가설 | 채택 | 보류 | 기각 |
|------|------|------|------|
| H1 (Kernel 튜닝) | ≥ 20% 향상 | 10~20% 향상 | < 10% 향상 |
| H2 (Multi-queue) | ≥ 40% 향상 | 20~40% 향상 | < 20% 향상 |
| H3 (시너지 효과) | D > B + C - A | D ≈ B + C - A | D < max(B, C) |
| H4 (최적 큐 = vCPU) | queue=vCPU에서 최대 | 차이 < 5% | 다른 큐 수가 더 높음 |

### 8.2 최종 권고 판단

| 결과 | 권고 |
|------|------|
| D가 A 대비 50%+ 향상 | Kernel + Queue 조합을 프로덕션 표준으로 적용 |
| B 또는 C 중 하나만으로 충분 | 효과가 큰 단일 설정만 적용 (운영 단순화) |
| D가 A 대비 30% 미만 향상 | CPU Pinning, Hugepages 등 추가 튜닝 실험 필요 |

---

## 9. 산출물

| # | 산출물 | 형식 | 설명 |
|---|--------|------|------|
| 1 | 실험 결과 보고서 | Markdown/PDF | 구성별 비교 결과, 가설 검증, 권고안 |
| 2 | 성능 비교 차트 | PNG/SVG | 구성 A~D 처리량/지연시간/CPU효율 비교 그래프 |
| 3 | 최적 설정 파일 | sysctl.conf + VMI YAML | 즉시 적용 가능한 설정 파일 |
| 4 | 테스트 자동화 스크립트 | Shell | run_test.sh + 수집/분석 스크립트 일체 |
| 5 | 원시 데이터 | JSON/CSV | iperf3 JSON, netperf txt, mpstat log 전체 |
| 6 | 큐 분배 분석 | CSV + 차트 | 큐별 패킷 분배 균등성 분석 |

### 일정 요약

| 단계 | 기간 | 산출물 |
|------|------|--------|
| Phase 0: 환경 준비 | 1~2일 | 환경 구성, 스크립트 검증 완료 |
| Phase 1~4: 측정 | 4일 | 원시 데이터 (JSON/CSV/log) |
| Phase 5: 분석 | 1일 | 최종 보고서 + 설정 파일 |
| **총 소요** | **약 1주** | |

---

> **문서 버전**: v2.0  
> **작성일**: 2026-02-22  
> **검토 상태**: 초안 (Draft)
Claude