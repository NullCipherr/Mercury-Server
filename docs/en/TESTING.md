# Automated Testing

*[Leia em Português](../pt-br/TESTES_AUTOMATIZADOS.md)*

## Strategy

Test automation is split into layers to reduce regressions and simplify local CI execution:

- Unit tests in Zig (`zig build test`);
- HTTP integration tests with a real server (`scripts/tests/integration_http.sh`);
- Full local validation pipeline (`make test-ci`).

## Makefile Test Targets

- `make test` or `make test-unit`
  - Runs unit tests.
- `make test-integration`
  - Starts a temporary server and validates real HTTP contracts.
- `make test-all`
  - Runs unit + integration tests.
- `make test-ci`
  - Runs `fmt + build + test-all`.

## HTTP Integration Suite

Script: `scripts/tests/integration_http.sh`

Current coverage:

- `GET /health` returns `200` with expected payload;
- `GET /api/hello` returns `200` with expected payload;
- `GET /metrics` respects expected JSON contract;
- Unknown route returns `404`;
- `GET /` and `GET /static/index.html` serve static content;
- Path traversal blocking (`/static/../...`) returns `400`;
- Oversized header rejection returns `431`.

## Incorporated Best Practices

- Scripts use `set -euo pipefail`;
- Automatic process cleanup via `trap`;
- Execution logs for troubleshooting;
- Fail-fast with clear messages and context;
- Integration tests isolated by port (`TEST_PORT`, default `18080`).

## Recommended Day-to-Day Workflow

1. `make test-all` before merging.
2. `make test-ci` before releasing.
3. On API incidents, run `make test-integration` in isolation for quick diagnosis.
