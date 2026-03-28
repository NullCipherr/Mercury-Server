#!/usr/bin/env bash
set -euo pipefail

if ! command -v wrk >/dev/null 2>&1; then
  echo "Instale o wrk para executar benchmark" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Instale o curl para validar endpoints antes do benchmark" >&2
  exit 1
fi

THREADS="${THREADS:-8}"
CONNECTIONS="${CONNECTIONS:-128}"
DURATION="${DURATION:-20s}"
WARMUP="${WARMUP:-5s}"
ROUNDS="${ROUNDS:-3}"
CLOSE_CONNECTION="${CLOSE_CONNECTION:-1}"
MERCURY_URL="${MERCURY_URL:-http://127.0.0.1:8080/health}"
GO_URL="${GO_URL:-http://127.0.0.1:8081/health}"
NODE_URL="${NODE_URL:-http://127.0.0.1:8082/health}"

RESULTS_DIR="benchmarks/results"
mkdir -p "${RESULTS_DIR}"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RAW_FILE="${RESULTS_DIR}/benchmark_${RUN_ID}.raw.log"
SUMMARY_FILE="${RESULTS_DIR}/benchmark_${RUN_ID}.summary.log"

CASES=(
  "Mercury Server|${MERCURY_URL}"
  "Go|${GO_URL}"
  "Node|${NODE_URL}"
)

ENABLED_CASES=()

declare -A RPS_VALUES
declare -A LAT_VALUES
declare -A ERR_VALUES
declare -A ERR_RATE_VALUES
declare -A P50_VALUES
declare -A P90_VALUES
declare -A P99_VALUES
declare -A OK_RUNS

to_ms() {
  local value="$1"
  awk -v v="$value" 'BEGIN {
    unit = v
    gsub(/[0-9.]/, "", unit)
    num = v
    gsub(/[a-zA-Z]/, "", num)

    if (num == "") {
      print "0"
      exit
    }

    if (unit == "us") {
      printf "%.6f", num / 1000.0
    } else if (unit == "ms") {
      printf "%.6f", num
    } else if (unit == "s") {
      printf "%.6f", num * 1000.0
    } else {
      printf "%.6f", num
    }
  }'
}

avg_of_list() {
  local list="$1"
  if [[ -z "${list// }" ]]; then
    echo "n/a"
    return
  fi

  tr ' ' '\n' <<<"$list" | sed '/^$/d' | awk '
    BEGIN { n = 0; sum = 0 }
    { sum += $1; n += 1 }
    END {
      if (n == 0) print "n/a";
      else printf "%.2f", sum / n
    }
  '
}

median_of_list() {
  local list="$1"
  if [[ -z "${list// }" ]]; then
    echo "n/a"
    return
  fi

  tr ' ' '\n' <<<"$list" | sed '/^$/d' | sort -n | awk '
    { a[n++] = $1 }
    END {
      if (n == 0) {
        print "n/a"
      } else if (n % 2 == 1) {
        printf "%.2f", a[int(n / 2)]
      } else {
        printf "%.2f", (a[(n / 2) - 1] + a[n / 2]) / 2
      }
    }
  '
}

run_wrk() {
  local url="$1"
  local duration="$2"

  if [[ "$CLOSE_CONNECTION" == "1" ]]; then
    wrk --latency -t"${THREADS}" -c"${CONNECTIONS}" -d"${duration}" -H "Connection: close" "$url"
  else
    wrk --latency -t"${THREADS}" -c"${CONNECTIONS}" -d"${duration}" "$url"
  fi
}

extract_rps() {
  awk '/Requests\/sec:/ { print $2; exit }'
}

extract_latency_avg_ms() {
  awk '/Latency/ { print $2; exit }' | while read -r raw; do
    to_ms "$raw"
  done
}

extract_socket_errors_total() {
  awk '
    /Socket errors:/ {
      sum = 0
      for (i = 1; i <= NF; i++) {
        gsub(",", "", $i)
        if ($i ~ /^[0-9]+$/) sum += $i
      }
      print sum
      found = 1
      exit
    }
    END {
      if (!found) print 0
    }
  '
}

extract_total_requests() {
  awk '
    /requests in/ {
      gsub(",", "", $1);
      print $1;
      exit
    }
  '
}

extract_percentile_ms() {
  local percentile="$1"
  awk -v p="${percentile}" '
    $1 == p {
      print $2
      exit
    }
  ' | while read -r raw; do
    to_ms "$raw"
  done
}

calc_error_rate_pct() {
  local errors="$1"
  local requests="$2"
  awk -v e="$errors" -v r="$requests" 'BEGIN {
    if (r == 0 || r == "" || e == "") {
      print "0.0000"
      exit
    }
    printf "%.4f", (e / r) * 100.0
  }'
}

run_case() {
  local name="$1"
  local url="$2"

  {
    echo "=================================================="
    echo "Benchmark ${name} (${url})"
    echo "Threads=${THREADS} Connections=${CONNECTIONS} Duration=${DURATION} Warmup=${WARMUP} Rounds=${ROUNDS}"
  } | tee -a "${RAW_FILE}"

  if ! curl -fsS --max-time 2 "$url" >/dev/null; then
    {
      echo "ERRO: endpoint indisponivel para ${name}: ${url}"
      echo "Dica: suba o servidor correspondente e rode novamente."
      echo
    } | tee -a "${RAW_FILE}"
    return
  fi

  {
    echo "Warmup ${WARMUP}..."
  } | tee -a "${RAW_FILE}"
  run_wrk "$url" "$WARMUP" >>"${RAW_FILE}" 2>&1

  local i
  for ((i = 1; i <= ROUNDS; i += 1)); do
    local tmp_file
    tmp_file="$(mktemp)"

    {
      echo
      echo "Rodada ${i}/${ROUNDS}"
    } | tee -a "${RAW_FILE}"

    run_wrk "$url" "$DURATION" | tee -a "${RAW_FILE}" >"${tmp_file}"

    local rps
    local lat_ms
    local err_total
    local req_total
    local err_rate_pct
    local p50_ms
    local p90_ms
    local p99_ms
    rps="$(extract_rps <"${tmp_file}")"
    lat_ms="$(extract_latency_avg_ms <"${tmp_file}")"
    err_total="$(extract_socket_errors_total <"${tmp_file}")"
    req_total="$(extract_total_requests <"${tmp_file}")"
    err_rate_pct="$(calc_error_rate_pct "${err_total}" "${req_total}")"
    p50_ms="$(extract_percentile_ms "50%" <"${tmp_file}")"
    p90_ms="$(extract_percentile_ms "90%" <"${tmp_file}")"
    p99_ms="$(extract_percentile_ms "99%" <"${tmp_file}")"

    if [[ -n "$rps" && -n "$lat_ms" ]]; then
      RPS_VALUES["$name"]+="${rps} "
      LAT_VALUES["$name"]+="${lat_ms} "
      ERR_VALUES["$name"]+="${err_total} "
      ERR_RATE_VALUES["$name"]+="${err_rate_pct} "
      P50_VALUES["$name"]+="${p50_ms} "
      P90_VALUES["$name"]+="${p90_ms} "
      P99_VALUES["$name"]+="${p99_ms} "
      OK_RUNS["$name"]=$(( ${OK_RUNS["$name"]:-0} + 1 ))
    fi

    rm -f "${tmp_file}"
  done

  echo | tee -a "${RAW_FILE}"
}

print_summary() {
  {
    echo "Resumo consolidado"
    echo "Data: $(date -Is)"
    echo "Host: $(hostname)"
    echo "Parametros: THREADS=${THREADS} CONNECTIONS=${CONNECTIONS} DURATION=${DURATION} WARMUP=${WARMUP} ROUNDS=${ROUNDS} CLOSE_CONNECTION=${CLOSE_CONNECTION}"
    echo
  } >"${SUMMARY_FILE}"

  printf "%-14s | %-11s | %-11s | %-11s | %-10s | %-10s | %-10s | %-11s | %-10s\n" \
    "Servidor" "Rodadas OK" "RPS medio" "Lat ms med" "P50 ms" "P90 ms" "P99 ms" "SockErr med" "ErrPct med" | tee -a "${SUMMARY_FILE}"
  printf -- "%.0s-" {1..130} | tee -a "${SUMMARY_FILE}"
  echo | tee -a "${SUMMARY_FILE}"

  local entry
  for entry in "${ENABLED_CASES[@]}"; do
    local name="${entry%%|*}"
    local rps_list="${RPS_VALUES["$name"]:-}"
    local lat_list="${LAT_VALUES["$name"]:-}"
    local err_list="${ERR_VALUES["$name"]:-}"
    local err_rate_list="${ERR_RATE_VALUES["$name"]:-}"
    local p50_list="${P50_VALUES["$name"]:-}"
    local p90_list="${P90_VALUES["$name"]:-}"
    local p99_list="${P99_VALUES["$name"]:-}"
    local ok_runs="${OK_RUNS["$name"]:-0}"

    local rps_avg lat_med err_avg err_rate_avg p50_med p90_med p99_med
    rps_avg="$(avg_of_list "$rps_list")"
    lat_med="$(median_of_list "$lat_list")"
    err_avg="$(avg_of_list "$err_list")"
    err_rate_avg="$(avg_of_list "$err_rate_list")"
    p50_med="$(median_of_list "$p50_list")"
    p90_med="$(median_of_list "$p90_list")"
    p99_med="$(median_of_list "$p99_list")"

    printf "%-14s | %-11s | %-11s | %-11s | %-10s | %-10s | %-10s | %-11s | %-10s\n" \
      "$name" "$ok_runs" "$rps_avg" "$lat_med" "$p50_med" "$p90_med" "$p99_med" "$err_avg" "$err_rate_avg" | tee -a "${SUMMARY_FILE}"
  done

  {
    echo
    echo "Raw log: ${RAW_FILE}"
    echo "Summary: ${SUMMARY_FILE}"
  } | tee -a "${SUMMARY_FILE}"
}

echo "Arquivo bruto: ${RAW_FILE}"
echo "Iniciando benchmark comparativo..."

for entry in "${CASES[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  if curl -fsS --max-time 2 "$url" >/dev/null; then
    ENABLED_CASES+=("$entry")
  else
    {
      echo "AVISO: caso ${name} removido automaticamente (endpoint indisponivel: ${url})"
    } | tee -a "${RAW_FILE}"
  fi
done

if [[ "${#ENABLED_CASES[@]}" -eq 0 ]]; then
  echo "Nenhum servidor disponivel para benchmark." | tee -a "${RAW_FILE}"
  exit 1
fi

for entry in "${ENABLED_CASES[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  run_case "$name" "$url"
done

print_summary

echo
echo "Benchmark concluido."
echo "Resumo: ${SUMMARY_FILE}"
echo "Bruto: ${RAW_FILE}"
