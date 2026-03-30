<div align="center">
  <img src="docs/assets/mercury-logo.png" alt="Mercury Server Logo" width="220" />
  <h1>Mercury Server</h1>
  <p><i>A low-level HTTP/1.1 server in Zig with a hand-written parser, connection pooling, and real-time metrics</i></p>

  <p>
    <a href="https://github.com/NullCipherr/Mercury-Server/actions/workflows/ci.yml"><img src="https://github.com/NullCipherr/Mercury-Server/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/github/license/NullCipherr/Mercury-Server?style=flat-square" alt="License" /></a>
    <img src="https://img.shields.io/badge/Zig-0.14+-F7A41D?style=flat-square&logo=zig&logoColor=white" alt="Zig" />
    <img src="https://img.shields.io/badge/HTTP-1.1-1E88E5?style=flat-square" alt="HTTP/1.1" />
  </p>
</div>

---

## Documentation

Technical documentation is organized into modules for easy onboarding and maintenance.
English is the primary language; Portuguese translations are available under `docs/pt-br/`.

- [Documentation Index](docs/README.md)
- [Architecture](docs/en/ARCHITECTURE.md)
- [API](docs/en/API.md)
- [Operations](docs/en/OPERATIONS.md)
- [Observability & Benchmark](docs/en/OBSERVABILITY.md)
- [Testing](docs/en/TESTING.md)
- [Metrics Automation](docs/en/METRICS_AUTOMATION.md)
- [Roadmap](docs/en/ROADMAP.md)

---

## Preview

Static interface served by Mercury Server itself at `GET /`:

- File: `static/index.html`
- Local access: `http://localhost:8080`

---

## Overview

**Mercury Server** is an HTTP server written in Zig focused on predictability, low overhead, and explicit resource control.

The project prioritizes:

- Hand-written HTTP parser (no web framework);
- Thread-safe queue to decouple `accept` from processing;
- Fixed worker threads to reduce thread churn;
- Operational metrics exposed via endpoint;
- Static file serving with path traversal protection.

---

## Features

- **Hand-written HTTP parser** with configurable header/body size limits.
- **Thread-safe connection pool** to distribute sockets across workers.
- **Built-in metrics** (`/metrics`) with requests, errors, and average latency.
- **Basic I/O hardening** with per-connection read/write timeouts.
- **Automatic port fallback** with `--port-retries`.
- **Static file server** (`/` and `/static/*`) with path traversal protection.
- **Graceful shutdown** via POSIX signal handling (SIGINT/SIGTERM).
- **Runtime log level filtering** via `--log-level`.
- **Local and containerized execution** with `Makefile` and Docker Compose.

---

## Architecture

Main request flow:

1. `main.zig` initializes allocator, logger, metrics, and configuration.
2. `server.zig` binds with retry, accepts connections, and pushes them to the pool.
3. Workers consume the queue, apply socket timeouts, and process requests.
4. `http_parser.zig` parses the request line, headers, and validates limits.
5. `router.zig` dispatches to JSON response, metrics, or static file serving.
6. `http_response.zig` serializes the HTTP/1.1 response and sends it to the client.

---

## Performance

The project includes a comparative benchmark against Go and Node in `benchmarks/`.

- Main script: `benchmarks/run.sh`
- Output: `benchmarks/results/benchmark_YYYYMMDD_HHMMSS.*`
- Tracked metrics:
  - requests/second (via `wrk`);
  - average latency;
  - current/peak memory (TrackingAllocator).

Run benchmark:

```bash
bash benchmarks/run.sh
```

Benchmark with explicit parameters:

```bash
THREADS=8 CONNECTIONS=128 DURATION=20s WARMUP=5s ROUNDS=3 CLOSE_CONNECTION=0 bash benchmarks/run.sh
```

## Official Benchmark Results

Pre-publication reference benchmark.

- Date: `2026-03-28` (America/Sao_Paulo)
- Script: `benchmarks/run.sh`
- Parameters: `THREADS=4 CONNECTIONS=64 DURATION=8s WARMUP=3s ROUNDS=2 CLOSE_CONNECTION=0`
- Artefatos:
  - `benchmarks/results/benchmark_20260328_173418.raw.log`
  - `benchmarks/results/benchmark_20260328_173418.summary.log`

| Server | Rounds OK | Avg RPS | Avg Lat ms | P50 ms | P90 ms | P99 ms | Avg SockErr | Avg ErrPct |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Mercury Server | 2 | 34645.01 | 1.75 | 1.65 | 2.13 | 2.73 | 0.00 | 0.00 |
| Go | 2 | 145293.38 | 0.63 | 0.24 | 1.71 | 3.64 | 0.00 | 0.00 |
| Node | 2 | 74361.76 | 0.90 | 0.77 | 1.15 | 2.52 | 0.00 | 0.00 |

---

## Technical Decisions

- **Memory control**: `TrackingAllocator` for runtime memory visibility.
- **Zero-allocation hot path**: fixed-buffer reads to reduce per-request cost.
- **Operational reliability**: port fallback, payload limits, and socket timeouts.
- **Intentional simplicity**: essential HTTP/1.1 scope, no unnecessary abstractions.

---

## Roadmap

Recommended next steps for production maturity:

- Robust keep-alive support and full incremental parsing;
- Static file streaming to reduce peak memory usage;
- Structured logging and Prometheus exporter integration;
- HTTP parser fuzz testing suite;
- Deployment strategy with reverse proxy + TLS + orchestration health checks.

---

## Tech Stack

- **Language**: Zig (0.14+)
- **Networking**: `std.net` (TCP + sockets)
- **Concurrency**: native threads + connection pool
- **Build/Test**: Zig Build System (`zig build`, `zig build test`)
- **Automation**: Makefile
- **Containerization**: Docker + Docker Compose

---

## Project Structure

```text
.
├── benchmarks/
│   ├── go_server.go
│   ├── node_server.js
│   └── run.sh
├── examples/
│   └── curl-examples.sh
├── src/
│   ├── config.zig
│   ├── connection_pool.zig
│   ├── http_parser.zig
│   ├── http_response.zig
│   ├── logger.zig
│   ├── main.zig
│   ├── metrics.zig
│   ├── router.zig
│   ├── server.zig
│   └── types.zig
├── static/
│   └── index.html
├── .dockerignore
├── build.zig
├── Dockerfile
├── docker-compose.yml
├── docs/
│   ├── assets/
│   │   └── mercury-logo.png
│   ├── README.md
│   ├── en/
│   │   ├── API.md
│   │   ├── ARCHITECTURE.md
│   │   ├── METRICS_AUTOMATION.md
│   │   ├── OBSERVABILITY.md
│   │   ├── OPERATIONS.md
│   │   ├── ROADMAP.md
│   │   └── TESTING.md
│   └── pt-br/
│       ├── API.md
│       ├── ARQUITETURA.md
│       ├── METRICAS_AUTOMACAO_SHELL.md
│       ├── OBSERVABILIDADE_E_BENCHMARK.md
│       ├── OPERACAO_DEPLOY_MANUTENCAO.md
│       ├── ROADMAP_TECNICO.md
│       └── TESTES_AUTOMATIZADOS.md
├── Makefile
└── README.md
```

---

## Getting Started

### Prerequisites

- Zig `0.14+`
- Make (optional, but recommended)
- Docker 24+ and Docker Compose v2 (optional)

### Running with Zig

```bash
zig build
zig build run
```

With explicit parameters:

```bash
zig build run -- --host 0.0.0.0 --port 8080 --threads 8 --static-dir ./static
```

### Running with Makefile

```bash
make build
make run PORT=8080 THREADS=8
```

### Endpoints

- `GET /health`
- `GET /api/hello`
- `GET /metrics`
- `GET /`
- `GET /static/<file>`

---

## Docker Deployment

### Build and start

```bash
docker compose up -d --build
```

Or via Makefile:

```bash
make docker-build
make docker-up
```

### Operations

```bash
docker compose logs -f mercury-server
docker compose down
```

Or via Makefile:

```bash
make docker-logs
make docker-down
```

### Access

- Application: `http://localhost:8080`
- Health check: `curl -i http://localhost:8080/health`

---

## Make Targets

- `make help`: list available commands.
- `make build`: compile the binary.
- `make run`: run server with configurable variables.
- `make test`: run unit tests (`zig build test`).
- `make test-unit`: run unit tests (`zig build test`).
- `make test-integration`: run HTTP integration tests against a live server.
- `make test-all`: run unit + integration tests.
- `make test-ci`: full local CI pipeline (`fmt + build + test-all`).
- `make smoke`: validate `/health`, `/api/hello`, and `/metrics`.
- `make bench`: benchmark Mercury vs Go vs Node.
- `make bench-metrics`: run `wrk` with automatic metrics collection.
- `make metrics-collect`: collect `/metrics` to CSV over a time window.
- `make metrics-report`: generate summary from a metrics CSV.
- `make docker-build`: build Docker image.
- `make docker-up`: start container via Docker Compose.
- `make docker-down`: tear down local stack.
- `make docker-logs`: follow container logs.

---

## License

This project is **open source** under the **MIT License**.

See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before getting started.

For security vulnerabilities, please refer to our [Security Policy](SECURITY.md).

<div align="center">
  Built with Zig — focused on low-level engineering, observability, and incremental evolution.
</div>
