# Automação de Métricas via Shell

## Objetivo

Padronizar coleta e leitura de métricas do endpoint `/metrics` sem dependência de stack externa.

## Scripts disponíveis

- `scripts/metrics/collect_metrics.sh`
  - coleta periódica e grava CSV.
- `scripts/metrics/report_metrics_csv.sh`
  - gera resumo analítico a partir do CSV.
- `scripts/metrics/benchmark_with_metrics.sh`
  - executa `wrk` e coleta métricas em paralelo.

## Uso direto dos scripts

Coleta por 30 segundos:

```bash
METRICS_URL=http://127.0.0.1:8080/metrics DURATION_SEC=30 INTERVAL_SEC=1 bash scripts/metrics/collect_metrics.sh
```

Resumo de arquivo coletado:

```bash
bash scripts/metrics/report_metrics_csv.sh benchmarks/results/metrics_YYYYMMDD_HHMMSS.csv
```

Benchmark com coleta acoplada:

```bash
TARGET_URL=http://127.0.0.1:8080/health DURATION=20s DURATION_SEC=20 THREADS=8 CONNECTIONS=128 bash scripts/metrics/benchmark_with_metrics.sh
```

## Uso via Makefile

- `make metrics-collect`
- `make metrics-report METRICS_FILE=<arquivo.csv>`
- `make bench-metrics`

Variáveis úteis:

- `METRICS_URL`
- `METRICS_DURATION_SEC`
- `METRICS_INTERVAL_SEC`
- `METRICS_OUTPUT`
- `METRICS_FILE`

## Formato do CSV

Header:

```text
timestamp_iso,timestamp_epoch_ms,requests,errors,avg_latency_ms
```

Observações:

- quando não há resposta válida, a linha é registrada com `NA`;
- o relatório ignora linhas inválidas automaticamente.
