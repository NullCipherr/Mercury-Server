# Observability and Benchmark

*[Leia em Português](../pt-br/OBSERVABILIDADE_E_BENCHMARK.md)*

## Available Metrics

Endpoint: `GET /metrics`

Example:

```json
{
  "requests": 1200,
  "errors": 8,
  "avg_latency_ms": 0.812,
  "connections_accepted": 1205,
  "worker_failures": 0,
  "error_breakdown": {
    "header_too_large": 0,
    "payload_too_large": 0,
    "header_fields_too_large": 0,
    "bad_request": 8
  },
  "response_status": {
    "2xx": 1192,
    "4xx": 8,
    "5xx": 0
  }
}
```

Interpretation:

- `requests`: total volume processed during the current uptime.
- `errors`: number of processing events marked as failures.
- `avg_latency_ms`: cumulative average latency (not percentile-based).
- `connections_accepted`: connections accepted on the listen socket.
- `worker_failures`: processing failures caught in the worker pool.
- `error_breakdown`: error details broken down by category.
- `response_status`: aggregated count by HTTP status family.

## Internal Memory Metrics

On process shutdown, the logger prints:

- total requests;
- total errors;
- average latency;
- current memory usage;
- peak memory usage.

These values come from `Metrics` + `TrackingAllocator`.

## Logs

Current format:

- timestamp in milliseconds;
- level (`DEBUG`, `INFO`, `WARN`, `ERROR`);
- text message.

Practical use:

- quick startup validation (`Mercury Server listening...`);
- diagnosing parse/accept/worker failures;
- inspecting behavior in local environments.

## Comparative Benchmark

Script: `benchmarks/run.sh`

Compares 3 targets:

- Mercury Server (`127.0.0.1:8080`)
- Go (`127.0.0.1:8081`)
- Node (`127.0.0.1:8082`)

Targets can also be customized via environment variables:

- `MERCURY_URL`
- `GO_URL`
- `NODE_URL`

Prerequisites:

- `wrk`
- `curl`

Execution:

```bash
bash benchmarks/run.sh
```

With custom parameters:

```bash
THREADS=8 CONNECTIONS=128 DURATION=20s WARMUP=5s ROUNDS=3 CLOSE_CONNECTION=0 bash benchmarks/run.sh
```

Outputs:

- `benchmarks/results/benchmark_<timestamp>.raw.log`
- `benchmarks/results/benchmark_<timestamp>.summary.log`

## Automated Metrics Collection (Shell)

Scripts:

- `scripts/metrics/collect_metrics.sh`
- `scripts/metrics/report_metrics_csv.sh`
- `scripts/metrics/benchmark_with_metrics.sh`

Recommended workflow:

1. Run benchmark with coupled collection (`make bench-metrics`).
2. Validate the summary of the generated CSV.
3. Compare average latency, request delta, and error delta between versions.

## Benchmark Reading Best Practices

- Use multiple rounds (`ROUNDS>=3`).
- Compare median and average of RPS/latency.
- Observe average socket errors.
- Observe percentiles (`P50`, `P90`, `P99`) and error rate (`ErrPct`).
- Maintain stable conditions across runs (machine, load, parameters).
