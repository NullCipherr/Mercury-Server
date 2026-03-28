# Observabilidade e Benchmark

## Métricas disponíveis

Endpoint: `GET /metrics`

Exemplo:

```json
{"requests":1200,"errors":8,"avg_latency_ms":0.812,"connections_accepted":1205,"worker_failures":0,"error_breakdown":{"header_too_large":0,"payload_too_large":0,"header_fields_too_large":0,"bad_request":8},"response_status":{"2xx":1192,"4xx":8,"5xx":0}}
```

Interpretação:

- `requests`: volume total processado no uptime atual.
- `errors`: quantidade de processamentos marcados como falha.
- `avg_latency_ms`: média de latência acumulada (não percentil).
- `connections_accepted`: conexões aceitas no socket de listen.
- `worker_failures`: falhas de processamento capturadas no worker.
- `error_breakdown`: detalhamento de erros por categoria.
- `response_status`: contagem agregada por família de status HTTP.

## Métricas internas de memória

No encerramento do processo, o logger imprime:

- requests totais;
- erros totais;
- latência média;
- memória atual;
- pico de memória.

Esses dados vêm de `Metrics` + `TrackingAllocator`.

## Logs

Formato atual:

- timestamp em ms;
- nível (`DEBUG`, `INFO`, `WARN`, `ERROR`);
- mensagem textual.

Uso prático:

- validação rápida de startup (`Mercury Server ouvindo...`);
- diagnóstico de falhas em parse/accept/worker;
- inspeção de comportamento em ambiente local.

## Benchmark comparativo

Script: `benchmarks/run.sh`

Compara 3 alvos:

- Mercury Server (`127.0.0.1:8080`)
- Go (`127.0.0.1:8081`)
- Node (`127.0.0.1:8082`)

Os alvos também podem ser customizados via ambiente:

- `MERCURY_URL`
- `GO_URL`
- `NODE_URL`

Pré-requisitos:

- `wrk`
- `curl`

Execução:

```bash
bash benchmarks/run.sh
```

Com parâmetros customizados:

```bash
THREADS=8 CONNECTIONS=128 DURATION=20s WARMUP=5s ROUNDS=3 CLOSE_CONNECTION=0 bash benchmarks/run.sh
```

Saídas:

- `benchmarks/results/benchmark_<timestamp>.raw.log`
- `benchmarks/results/benchmark_<timestamp>.summary.log`

## Coleta automatizada de métricas (shell)

Scripts:

- `scripts/metrics/collect_metrics.sh`
- `scripts/metrics/report_metrics_csv.sh`
- `scripts/metrics/benchmark_with_metrics.sh`

Fluxo recomendado:

1. Executar benchmark com coleta acoplada (`make bench-metrics`).
2. Validar resumo final do CSV gerado.
3. Comparar latência média, delta de requests e delta de erros entre versões.

## Boas práticas para leitura de benchmark

- usar múltiplas rodadas (`ROUNDS>=3`);
- comparar mediana e média de RPS/latência;
- observar erro de socket médio;
- observar percentis (`P50`, `P90`, `P99`) e taxa de erro (`ErrPct`);
- manter condições estáveis entre execuções (máquina, carga, parâmetros).
