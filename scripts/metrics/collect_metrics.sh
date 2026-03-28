#!/usr/bin/env bash
set -euo pipefail

METRICS_URL="${METRICS_URL:-http://127.0.0.1:8080/metrics}"
DURATION_SEC="${DURATION_SEC:-30}"
INTERVAL_SEC="${INTERVAL_SEC:-1}"
OUTPUT_FILE="${OUTPUT_FILE:-benchmarks/results/metrics_$(date +%Y%m%d_%H%M%S).csv}"

mkdir -p "$(dirname "${OUTPUT_FILE}")"

echo "timestamp_iso,timestamp_epoch_ms,requests,errors,avg_latency_ms" > "${OUTPUT_FILE}"

START_TS="$(date +%s)"
END_TS=$((START_TS + DURATION_SEC))

echo "[INFO] coletando metricas de ${METRICS_URL} por ${DURATION_SEC}s (intervalo ${INTERVAL_SEC}s)"
echo "[INFO] arquivo de saida: ${OUTPUT_FILE}"

while (( $(date +%s) <= END_TS )); do
  NOW_ISO="$(date -Iseconds)"
  NOW_MS="$(( $(date +%s) * 1000 ))"

  PAYLOAD="$(curl -fsS --max-time 2 "${METRICS_URL}" || true)"

  REQUESTS="$(sed -n 's/.*"requests":\([0-9][0-9]*\).*/\1/p' <<<"${PAYLOAD}")"
  ERRORS="$(sed -n 's/.*"errors":\([0-9][0-9]*\).*/\1/p' <<<"${PAYLOAD}")"
  LATENCY="$(sed -n 's/.*"avg_latency_ms":\([0-9][0-9]*\(\.[0-9][0-9]*\)\?\).*/\1/p' <<<"${PAYLOAD}")"

  if [[ -z "${REQUESTS}" || -z "${ERRORS}" || -z "${LATENCY}" ]]; then
    echo "${NOW_ISO},${NOW_MS},NA,NA,NA" >> "${OUTPUT_FILE}"
  else
    echo "${NOW_ISO},${NOW_MS},${REQUESTS},${ERRORS},${LATENCY}" >> "${OUTPUT_FILE}"
  fi

  sleep "${INTERVAL_SEC}"
done

echo "[INFO] coleta concluida"
echo "[INFO] resumo rapido:"
bash scripts/metrics/report_metrics_csv.sh "${OUTPUT_FILE}"
