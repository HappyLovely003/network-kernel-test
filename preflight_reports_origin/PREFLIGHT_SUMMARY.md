# Harvester 노드 사전 검증 결과 요약

**검증 일시**: 사전 검증 스크립트 실행 시점  
**대상 노드**: 3대 (10.161.96.32, 10.161.96.33, 10.161.96.35)  
**스크립트**: `suse_preflight.sh`

---

## 1. 개요

| 항목 | 10.161.96.32 | 10.161.96.33 | 10.161.96.35 |
|------|--------------|--------------|--------------|
| **OS** | Harvester v1.7.0 | Harvester v1.7.0 | Harvester v1.7.0 |
| **커널** | 6.4.0-36-default | 6.4.0-36-default | 6.4.0-36-default |
| **vhost_net** | ✅ OK | ✅ OK | ✅ OK |
| **검증 완료** | ✅ | ✅ | ✅ |

세 노드 모두 동일한 Harvester 버전·커널을 사용하며, vhost_net 모듈이 정상 로드됨.

---

## 2. sysctl 기준값 (네트워크)

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
| `net.ipv4.tcp_wmem` | 4096 16384 4194304 |

→ 이후 튜닝 시 이 값을 baseline으로 비교하면 됨.

---

## 3. 물리 NIC (ethtool)

### 공통 구성 (3노드 동일)

| 인터페이스 | 드라이버 | RX 큐 | TX 큐 | 비고 |
|------------|----------|------|------|------|
| eno1 | tg3 | 4 | 1 | 1GbE (Broadcom) |
| eno2 | tg3 | 4 | 1 | 1GbE (Broadcom) |
| eno3 | tg3 | 4 | 1 | 1GbE (Broadcom) |
| eno4 | tg3 | 4 | 1 | 1GbE (Broadcom) |
| enp132s0f0 | ixgbe | n/a | n/a | 10GbE (Intel) |
| enp132s0f1 | ixgbe | n/a | n/a | 10GbE (Intel) |

### 가상/논리 인터페이스 (공통)

| 인터페이스 | 드라이버 | 용도 |
|------------|----------|------|
| mgmt-br | bridge | 관리 네트워크 브리지 |
| mgmt-bo | bonding | 관리 본딩 |
| provider-br | bridge | 프로바이더 브리지 |
| provider-bo | bonding | 프로바이더 본딩 |
| flannel.1 | vxlan | Flannel 오버레이 |

- **cali\***, **veth\***: Calico/파드용 가상 인터페이스 (노드별 개수 상이, ethtool 상세 미지원)

---

## 4. 노드별 인터페이스 개수 (참고)

| 구분 | 10.161.96.32 | 10.161.96.33 | 10.161.96.35 |
|------|--------------|--------------|--------------|
| 물리 NIC (eno* + enp*) | 6 | 6 | 6 |
| Calico/veth 등 가상 IF | ~50 | ~58 | ~48 |

---

## 5. 결론

- **OS/커널**: 3노드 동일 (Harvester v1.7.0, 6.4.0-36-default).
- **vhost_net**: 모두 로드됨.
- **sysctl**: 동일 baseline 기록 완료. 필요 시 이 값을 기준으로 튜닝 비교 가능.
- **물리 NIC**: eno1~4 (tg3), enp132s0f0/f1 (ixgbe) 구성 동일. mgmt/provider 브리지·본딩 및 flannel.1 구성 동일.

**상세 원문**:  
- `preflight_10.161.96.32.txt`  
- `preflight_10.161.96.33.txt`  
- `preflight_10.161.96.35.txt`
