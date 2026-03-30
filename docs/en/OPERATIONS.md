# Operations, Deployment, and Maintenance

*[Leia em Português](../pt-br/OPERACAO_DEPLOY_MANUTENCAO.md)*

## Prerequisites

- Zig `0.14+`
- Docker 24+ and Docker Compose v2 (optional)
- Make (optional)

## Local Execution (without Docker)

Build:

```bash
zig build
```

Default execution:

```bash
zig build run
```

Execution with parameters:

```bash
zig build run -- --host 0.0.0.0 --port 8080 --threads 8 --static-dir ./static
```

## Execution with Makefile

```bash
make build
make run PORT=8080 THREADS=8
make test-all
make smoke
```

Local quality pipeline:

```bash
make test-ci
```

## Execution with Docker

Build and start:

```bash
docker compose up -d --build
```

Logs and shutdown:

```bash
docker compose logs -f mercury-server
docker compose down
```

Makefile shortcuts:

```bash
make docker-build
make docker-up
make docker-logs
make docker-down
```

## Runtime Parameters (CLI)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--host` | `0.0.0.0` | Bind address |
| `--port` | `8080` | Listen port |
| `--port-retries` | `20` | Port fallback attempts |
| `--threads` | CPUs (min 2) | Worker thread count |
| `--read-timeout-ms` | `2000` | Socket read timeout |
| `--write-timeout-ms` | `2000` | Socket write timeout |
| `--max-header-bytes` | `16384` | Max header size |
| `--max-body-bytes` | `1048576` | Max body size |
| `--static-dir` | `./static` | Static file directory |
| `--log-level` | `debug` | Log level (`debug`, `info`, `warn`, `err`) |

## Troubleshooting

### Port in use

Typical error: `AddressInUse`.

Actions:

1. Change port at execution time (`--port`);
2. Increase `--port-retries`;
3. Free the process occupying the port.

### Docker won't start on port `8080`

If `8080` is already in use on the host, change the mapping in `docker-compose.yml` to something like `18080:8080`.

### Frequent 431/413 errors

- Review client payload and header sizes;
- Adjust `--max-header-bytes` and `--max-body-bytes` limits carefully;
- Monitor effects on memory and latency.

## Recommended Maintenance Routine

1. Run `zig build test` before each release.
2. Run `make smoke` after changes to parser/routing.
3. Record a reference benchmark after performance-related changes.
4. Review the technical roadmap after each significant increment.
5. Collect metrics with shell scripts during critical change scenarios.
