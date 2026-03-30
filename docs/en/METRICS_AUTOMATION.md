# Metrics Automation via Shell

*[Leia em Português](../pt-br/METRICAS_AUTOMACAO_SHELL.md)*

## Purpose

Standardize collection and reading of metrics from the `/metrics` endpoint without depending on an external stack.

## Available Scripts

- `scripts/metrics/collect_metrics.sh`
  - Periodic collection, writes to CSV.
- `scripts/metrics/report_metrics_csv.sh`
  - Generates an analytical summary from a CSV file.
- `scripts/metrics/benchmark_with_metrics.sh`
  - Runs `wrk` and collects metrics in parallel.

## Direct Script Usage

Collect for 30 seconds:

```bash
METRICS_URL=http://127.0.0.1:8080/metrics DURATION_SEC=30 INTERVAL_SEC=1 bash scripts/metrics/collect_metrics.sh
```

Summary of a collected file:

```bash
bash scripts/metrics/report_metrics_csv.sh benchmarks/results/metrics_YYYYMMDD_HHMMSS.csv
```

Benchmark with coupled collection:

```bash
TARGET_URL=http://127.0.0.1:8080/health DURATION=20s DURATION_SEC=20 THREADS=8 CONNECTIONS=128 bash scripts/metrics/benchmark_with_metrics.sh
```

## Usage via Makefile

- `make metrics-collect`
- `make metrics-report METRICS_FILE=<file.csv>`
- `make bench-metrics`

Useful variables:

- `METRICS_URL`
- `METRICS_DURATION_SEC`
- `METRICS_INTERVAL_SEC`
- `METRICS_OUTPUT`
- `METRICS_FILE`

## CSV Format

Header:

```text
timestamp_iso,timestamp_epoch_ms,requests,errors,avg_latency_ms
```

Notes:

- When there is no valid response, the row is recorded with `NA`.
- The report automatically ignores invalid rows.
