#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

PORT="${PORT:-18080}"
HOST="${HOST:-127.0.0.1}"
THREADS="${THREADS:-2}"
STARTUP_TIMEOUT_SEC="${STARTUP_TIMEOUT_SEC:-15}"
BASE_URL="http://${HOST}:${PORT}"

LOG_DIR="${ROOT_DIR}/benchmarks/results"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/integration_http_$(date +%Y%m%d_%H%M%S).log"

SERVER_PID=""
TMP_BODY="$(mktemp)"
trap 'rm -f "${TMP_BODY}"' EXIT

cleanup() {
  if [[ -n "${SERVER_PID}" ]] && kill -0 "${SERVER_PID}" >/dev/null 2>&1; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

fail() {
  echo "[FAIL] $1" >&2
  echo "--- Ultimas linhas do log do servidor ---" >&2
  tail -n 60 "${LOG_FILE}" >&2 || true
  exit 1
}

assert_status_and_body() {
  local path="$1"
  local expected_status="$2"
  local expected_body="$3"

  local status
  status="$(curl -sS -o "${TMP_BODY}" -w "%{http_code}" "${BASE_URL}${path}")" || fail "curl falhou em ${path}"

  [[ "${status}" == "${expected_status}" ]] || fail "status inesperado em ${path}: esperado=${expected_status} obtido=${status}"
  local body
  body="$(cat "${TMP_BODY}")"
  [[ "${body}" == "${expected_body}" ]] || fail "body inesperado em ${path}: esperado='${expected_body}' obtido='${body}'"

  echo "[OK] ${path} status=${status}"
}

assert_status_and_contains() {
  local path="$1"
  local expected_status="$2"
  local expected_fragment="$3"

  local status
  status="$(curl -sS -o "${TMP_BODY}" -w "%{http_code}" "${BASE_URL}${path}")" || fail "curl falhou em ${path}"

  [[ "${status}" == "${expected_status}" ]] || fail "status inesperado em ${path}: esperado=${expected_status} obtido=${status}"
  grep -Fq "${expected_fragment}" "${TMP_BODY}" || fail "fragmento '${expected_fragment}' nao encontrado no body de ${path}"

  echo "[OK] ${path} status=${status}"
}

assert_metrics_contract() {
  local status
  status="$(curl -sS -o "${TMP_BODY}" -w "%{http_code}" "${BASE_URL}/metrics")" || fail "curl falhou em /metrics"
  [[ "${status}" == "200" ]] || fail "status inesperado em /metrics: ${status}"

  local body
  body="$(cat "${TMP_BODY}")"
  local requests errors latency
  requests="$(sed -n 's/.*"requests":\([0-9][0-9]*\).*/\1/p' <<<"${body}")"
  errors="$(sed -n 's/.*"errors":\([0-9][0-9]*\).*/\1/p' <<<"${body}")"
  latency="$(sed -n 's/.*"avg_latency_ms":\([0-9][0-9]*\(\.[0-9][0-9]*\)\?\).*/\1/p' <<<"${body}")"

  [[ -n "${requests}" && -n "${errors}" && -n "${latency}" ]] || fail "payload de /metrics fora do contrato: ${body}"

  echo "[OK] /metrics contrato JSON"
}

assert_path_traversal_blocked() {
  local status
  status="$(curl -sS --path-as-is -o "${TMP_BODY}" -w "%{http_code}" "${BASE_URL}/static/../README.md")" || fail "curl falhou no teste de path traversal"
  [[ "${status}" == "400" ]] || fail "path traversal deveria retornar 400, retornou ${status}"

  local body
  body="$(cat "${TMP_BODY}")"
  [[ "${body}" == "{\"error\":\"bad path\"}" ]] || fail "body inesperado para path traversal: ${body}"

  echo "[OK] bloqueio path traversal"
}

assert_large_header_rejected() {
  local big_header
  big_header="$(head -c 20000 < /dev/zero | tr '\0' 'a')"

  local status
  status="$(curl -sS -o "${TMP_BODY}" -w "%{http_code}" -H "X-Large: ${big_header}" "${BASE_URL}/health")" || fail "curl falhou no teste de header grande"
  [[ "${status}" == "431" ]] || fail "header grande deveria retornar 431, retornou ${status}"

  local body
  body="$(cat "${TMP_BODY}")"
  [[ "${body}" == "{\"error\":\"header too large\"}" ]] || fail "body inesperado para header grande: ${body}"

  echo "[OK] limite de header"
}

start_server() {
  echo "[INFO] iniciando Mercury Server para testes de integracao em ${BASE_URL}"
  zig build run -- \
    --host "${HOST}" \
    --port "${PORT}" \
    --port-retries 0 \
    --threads "${THREADS}" \
    --static-dir ./static \
    --read-timeout-ms 2000 \
    --write-timeout-ms 2000 \
    --max-header-bytes 16384 \
    --max-body-bytes 1048576 \
    >"${LOG_FILE}" 2>&1 &
  SERVER_PID="$!"

  local elapsed=0
  until curl -fsS "${BASE_URL}/health" >/dev/null 2>&1; do
    sleep 1
    elapsed=$((elapsed + 1))
    if (( elapsed >= STARTUP_TIMEOUT_SEC )); then
      fail "timeout aguardando startup do servidor"
    fi
  done

  echo "[INFO] servidor pronto"
}

start_server

assert_status_and_body "/health" "200" "{\"status\":\"ok\"}"
assert_status_and_body "/api/hello" "200" "{\"message\":\"Mercury Server online\"}"
assert_metrics_contract
assert_status_and_body "/rota-inexistente" "404" "{\"error\":\"not found\"}"
assert_status_and_contains "/" "200" "Mercury Server"
assert_status_and_contains "/static/index.html" "200" "Mercury Server"
assert_path_traversal_blocked
assert_large_header_rejected

echo "[PASS] suite de integracao HTTP concluida com sucesso"
