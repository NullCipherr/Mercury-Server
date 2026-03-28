#!/usr/bin/env bash
set -euo pipefail

if ! command -v wrk >/dev/null 2>&1; then
  echo "Instale o wrk para executar benchmark com metricas" >&2
  exit 1
fi

TARGET_URL="${TARGET_URL:-http://127.0.0.1:8080/health}"
METRICS_URL="${METRICS_URL:-http://127.0.0.1:8080/metrics}"
THREADS="${THREADS:-8}"
CONNECTIONS="${CONNECTIONS:-128}"
DURATION="${DURATION:-20s}"
DURATION_SEC="${DURATION_SEC:-20}"

RESULTS_DIR="benchmarks/results"
mkdir -p "${RESULTS_DIR}"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
WRK_OUTPUT="${RESULTS_DIR}/wrk_with_metrics_${RUN_ID}.log"
METRICS_OUTPUT="${RESULTS_DIR}/metrics_during_wrk_${RUN_ID}.csv"

echo "[INFO] iniciando coleta de metricas em background"
METRICS_URL="${METRICS_URL}" DURATION_SEC="$((DURATION_SEC + 2))" INTERVAL_SEC=1 OUTPUT_FILE="${METRICS_OUTPUT}" \
  bash scripts/metrics/collect_metrics.sh >/dev/null 2>&1 &
COLLECT_PID="$!"

cleanup() {
  if kill -0 "${COLLECT_PID}" >/dev/null 2>&1; then
    wait "${COLLECT_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "[INFO] executando wrk em ${TARGET_URL}"
wrk --latency -t"${THREADS}" -c"${CONNECTIONS}" -d"${DURATION}" "${TARGET_URL}" | tee "${WRK_OUTPUT}"

wait "${COLLECT_PID}" || true

echo "[INFO] benchmark concluido"
echo "[INFO] wrk: ${WRK_OUTPUT}"
echo "[INFO] metricas: ${METRICS_OUTPUT}"
echo "[INFO] resumo de metricas:"
bash scripts/metrics/report_metrics_csv.sh "${METRICS_OUTPUT}"
