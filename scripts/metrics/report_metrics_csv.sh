#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="${1:-}"
if [[ -z "${INPUT_FILE}" ]]; then
  echo "Uso: $0 <arquivo_csv>" >&2
  exit 1
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "Arquivo nao encontrado: ${INPUT_FILE}" >&2
  exit 1
fi

awk -F',' '
NR == 1 { next }
$3 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/ && $5 ~ /^[0-9]+(\.[0-9]+)?$/ {
  samples += 1
  req = $3 + 0
  err = $4 + 0
  lat = $5 + 0

  if (samples == 1) {
    first_req = req
    first_err = err
    min_lat = lat
    max_lat = lat
  }

  last_req = req
  last_err = err
  sum_lat += lat

  if (lat < min_lat) min_lat = lat
  if (lat > max_lat) max_lat = lat
}
END {
  if (samples == 0) {
    print "Sem amostras validas no arquivo."
    exit 0
  }

  req_delta = last_req - first_req
  err_delta = last_err - first_err
  avg_lat = sum_lat / samples

  printf("Amostras validas: %d\n", samples)
  printf("Delta requests: %d\n", req_delta)
  printf("Delta errors: %d\n", err_delta)
  printf("Latencia media (ms): %.3f\n", avg_lat)
  printf("Latencia min (ms): %.3f\n", min_lat)
  printf("Latencia max (ms): %.3f\n", max_lat)
}
' "${INPUT_FILE}"
