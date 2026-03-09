#!/bin/bash
# =================================================================
# 05_summarize.sh — 결과 취합 및 비교표 출력
#
# 사용법: bash 05_summarize.sh [결과 디렉토리]
# =================================================================
set -euo pipefail

RESULT_BASE="${1:-}"
if [[ -z "${RESULT_BASE}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  RESULT_ROOT="${SCRIPT_DIR}/../result"
  # 인자 없으면 result 아래 최신 날짜_시간 폴더 사용
  LATEST=$(ls -td "${RESULT_ROOT}"/[0-9]*_[0-9]* 2>/dev/null | head -1)
  RESULT_BASE="${LATEST:-/tmp/bench-results}"
fi
mkdir -p "${RESULT_BASE}"
CSV="${RESULT_BASE}/results.csv"

# ── CSV 생성 ──────────────────────────────────────────────────────
echo "CONFIG,RUN,P1_Gbps,P4_Gbps,P6_Gbps,P4_retrans" > "${CSV}"

for CONFIG in A B C-1 C-2 D-1 D-2; do
  for RUN in 1 2 3; do
    DIR="${RESULT_BASE}/${CONFIG}/run${RUN}"
    [ -d "${DIR}" ] || continue

    P1=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' \
      "${DIR}/iperf3_tcp_P1.json" 2>/dev/null || echo "N/A")
    P4=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' \
      "${DIR}/iperf3_tcp_P4.json" 2>/dev/null || echo "N/A")
    P6=$(jq -r '.end.sum_received.bits_per_second / 1e9 | . * 100 | round | . / 100' \
      "${DIR}/iperf3_tcp_P6.json" 2>/dev/null || echo "N/A")
    RT=$(jq -r '.end.sum_sent.retransmits // 0' \
      "${DIR}/iperf3_tcp_P4.json" 2>/dev/null || echo "N/A")

    echo "${CONFIG},${RUN},${P1},${P4},${P6},${RT}" >> "${CSV}"
  done
done

# ── 중앙값 계산 함수 ──────────────────────────────────────────────
median() {
  # 쉼표로 구분된 숫자열에서 중앙값 반환
  echo "$1" | tr ',' '\n' | grep -v '^N/A$' | sort -n \
    | awk 'BEGIN{c=0} {a[c++]=$1} END{ if(c>0) print a[int(c/2)]; else print "N/A" }'
}

# 구성 A P4 중앙값 (기준) — grep 미매칭 시 종료 방지
A_VALS=$(grep "^A," "${CSV}" 2>/dev/null || true | awk -F',' '{printf "%s,", $4}')
A_P4=$(median "${A_VALS}")

# ── 비교표 출력 ───────────────────────────────────────────────────
echo ""
echo "=================================================================="
echo "  TCP 처리량 비교 (Harvester KubeVirt) — 3회 중앙값"
echo "  $(date)"
echo "=================================================================="
printf "\n%-8s | %-10s | %-10s | %-10s | %s\n" \
  "CONFIG" "P=1(Gbps)" "P=4(Gbps)" "P=6(Gbps)" "A 대비 향상(P=4)"
printf "%s\n" "----------------------------------------------------------"

for CONFIG in A B C-1 C-2 D-1 D-2; do
  LINES=$(grep "^${CONFIG}," "${CSV}" 2>/dev/null || true)
  [ -z "${LINES}" ] && continue

  P1_MED=$(median "$(echo "${LINES}" | awk -F',' '{printf "%s,", $3}')")
  P4_MED=$(median "$(echo "${LINES}" | awk -F',' '{printf "%s,", $4}')")
  P6_MED=$(median "$(echo "${LINES}" | awk -F',' '{printf "%s,", $5}')")

  if [[ "${P4_MED}" =~ ^[0-9.]+$ ]] && [[ "${A_P4}" =~ ^[0-9.]+$ ]] && awk "BEGIN{exit !(${A_P4}>0)}"; then
    IMPROVE=$(awk "BEGIN{printf \"+%.1f%%\", (${P4_MED}-${A_P4})/${A_P4}*100}")
  else
    IMPROVE="N/A"
  fi

  printf "%-8s | %-10s | %-10s | %-10s | %s\n" \
    "${CONFIG}" "${P1_MED}" "${P4_MED}" "${P6_MED}" "${IMPROVE}"
done

# ── 가설 검증 ─────────────────────────────────────────────────────
echo ""
echo "── 가설 검증 ──"

B_P4=$(median  "$(grep "^B,"   "${CSV}" 2>/dev/null || true | awk -F',' '{printf "%s,", $4}')")
C2_P4=$(median "$(grep "^C-2," "${CSV}" 2>/dev/null || true | awk -F',' '{printf "%s,", $4}')")
D2_P4=$(median "$(grep "^D-2," "${CSV}" 2>/dev/null || true | awk -F',' '{printf "%s,", $4}')")

judge_h1() { awk "BEGIN{print ($1>=20)?\"✅ 채택\":($1>=10)?\"⚠ 보류\":\"❌ 기각\"}"; }
judge_h2() { awk "BEGIN{print ($1>=40)?\"✅ 채택\":($1>=20)?\"⚠ 보류\":\"❌ 기각\"}"; }

if [[ "${B_P4}" =~ ^[0-9.]+$ ]] && [[ "${A_P4}" =~ ^[0-9.]+$ ]] && awk "BEGIN{exit !(${A_P4}>0)}"; then
  H1=$(awk "BEGIN{printf \"%.1f\", (${B_P4}-${A_P4})/${A_P4}*100}")
  echo "H1 커널 튜닝(B vs A):     ${B_P4}G vs ${A_P4}G = +${H1}%  $(judge_h1 ${H1})  (기준 ≥20%)"
fi

if [[ "${C2_P4}" =~ ^[0-9.]+$ ]] && [[ "${A_P4}" =~ ^[0-9.]+$ ]] && awk "BEGIN{exit !(${A_P4}>0)}"; then
  H2=$(awk "BEGIN{printf \"%.1f\", (${C2_P4}-${A_P4})/${A_P4}*100}")
  echo "H2 Multi-queue(C-2 vs A): ${C2_P4}G vs ${A_P4}G = +${H2}%  $(judge_h2 ${H2})  (기준 ≥40%)"
fi

if [[ "${D2_P4}" =~ ^[0-9.]+$ ]] && \
   [[ "${B_P4}"  =~ ^[0-9.]+$ ]] && \
   [[ "${C2_P4}" =~ ^[0-9.]+$ ]] && \
   [[ "${A_P4}"  =~ ^[0-9.]+$ ]]; then
  awk "BEGIN{
    additive = ${B_P4} + ${C2_P4} - ${A_P4}
    printf \"H3 시너지(D-2 vs B+C-A): %.2f vs %.2f → %s\n\",
      ${D2_P4}, additive,
      (${D2_P4} > additive) ? \"✅ 채택 (시너지 존재)\" : \"❌ 기각 (시너지 없음)\"
  }"
fi

echo ""
echo "결과 CSV: ${CSV}"