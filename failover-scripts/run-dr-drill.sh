#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ID="$(date '+%Y%m%d-%H%M%S')"

export SCENARIO="dr-drill"
export RUN_ID

source "${SCRIPT_DIR}/00-failover-common.sh"

echo "DR drill start (RUN_ID=${RUN_ID})"

# 실제 장애 주입 명령으로 교체
run_step \
  "inject_eks_a_failure" \
  "eks-a" \
  kubectl --context "$CTX_A" -n "$CLOUDFLARED_NAMESPACE" \
    scale deployment "$CLOUDFLARED_DEPLOYMENT" --replicas=0

record_marker \
  "T0_FAILURE_INJECTED" \
  "controller" \
  "eks-a" \
  "Fault injection completed"

RUN_ID="$RUN_ID" "${SCRIPT_DIR}/01-switch-to-onprem.sh" &
PID_ONPREM=$!

RUN_ID="$RUN_ID" "${SCRIPT_DIR}/02-provision-dr.sh" &
PID_DR=$!

wait "$PID_ONPREM"; RESULT_ONPREM=$?
wait "$PID_DR"; RESULT_DR=$?

if [[ "$RESULT_ONPREM" -ne 0 || "$RESULT_DR" -ne 0 ]]; then
  echo "DR drill failed: onprem=${RESULT_ONPREM}, dr=${RESULT_DR}"
  exit 1
fi

echo "DR drill completed. RUN_ID=${RUN_ID}"
echo "결과: ${SCRIPT_DIR}/logs/dr-timeline.csv 에서 RUN_ID=${RUN_ID} 필터링"