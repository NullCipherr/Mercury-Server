SHELL := /usr/bin/env bash

ZIG ?= zig
NODE ?= node
GO ?= go

HOST ?= 0.0.0.0
PORT ?= 8080
PORT_RETRIES ?= 20
THREADS ?= 0
STATIC_DIR ?= ./static
READ_TIMEOUT_MS ?= 2000
WRITE_TIMEOUT_MS ?= 2000
MAX_HEADER_BYTES ?= 16384
MAX_BODY_BYTES ?= 1048576

BENCH_THREADS ?= 8
BENCH_CONNECTIONS ?= 128
BENCH_DURATION ?= 20s
BENCH_WARMUP ?= 5s
BENCH_ROUNDS ?= 5
BENCH_CLOSE_CONNECTION ?= 0
TEST_PORT ?= 18080
METRICS_URL ?= http://127.0.0.1:8080/metrics
METRICS_DURATION_SEC ?= 30
METRICS_INTERVAL_SEC ?= 1
METRICS_OUTPUT ?=
METRICS_FILE ?=

RUN_ARGS := --host $(HOST) --port $(PORT) --port-retries $(PORT_RETRIES) --threads $(THREADS) --static-dir $(STATIC_DIR) --read-timeout-ms $(READ_TIMEOUT_MS) --write-timeout-ms $(WRITE_TIMEOUT_MS) --max-header-bytes $(MAX_HEADER_BYTES) --max-body-bytes $(MAX_BODY_BYTES)

.PHONY: help build run test test-unit test-integration test-all test-ci fmt check smoke bench bench-quick bench-go bench-node bench-metrics metrics-collect metrics-report docker-build docker-up docker-down docker-logs clean clean-all

help:
	@echo "Mercury Server - comandos disponiveis"
	@echo
	@echo "  make build          Compila o projeto"
	@echo "  make run            Executa o servidor com parametros padrao/variaveis"
	@echo "  make test           Alias para make test-unit"
	@echo "  make test-unit      Roda testes unitarios (zig build test)"
	@echo "  make test-integration Roda testes de integracao HTTP com servidor real"
	@echo "  make test-all       Executa suite completa: unitario + integracao"
	@echo "  make test-ci        Pipeline local estilo CI (fmt + build + test-all)"
	@echo "  make fmt            Formata codigo Zig"
	@echo "  make check          Executa fmt + build + test-all"
	@echo "  make smoke          Sobe servidor temporario e testa /health /api/hello /metrics"
	@echo "  make bench          Executa benchmark comparativo (Mercury/Go/Node)"
	@echo "  make bench-quick    Benchmark rapido"
	@echo "  make bench-metrics  Executa wrk + coleta de metricas em paralelo"
	@echo "  make metrics-collect Coleta /metrics periodicamente em CSV"
	@echo "  make metrics-report Gera resumo de um CSV de metricas (METRICS_FILE=...)"
	@echo "  make bench-go       Sobe servidor Go de benchmark"
	@echo "  make bench-node     Sobe servidor Node de benchmark"
	@echo "  make docker-build   Gera imagem Docker do Mercury Server"
	@echo "  make docker-up      Sobe Mercury Server via Docker Compose (detached)"
	@echo "  make docker-down    Derruba stack Docker Compose"
	@echo "  make docker-logs    Acompanha logs do Mercury Server em Docker"
	@echo "  make clean          Remove artefatos locais"
	@echo "  make clean-all      Limpeza completa (inclui logs de benchmark)"
	@echo
	@echo "Variaveis uteis (exemplo):"
	@echo "  make run PORT=9090 THREADS=8"
	@echo "  make bench BENCH_THREADS=8 BENCH_CONNECTIONS=128 BENCH_ROUNDS=3"

build:
	$(ZIG) build

run:
	$(ZIG) build run -- $(RUN_ARGS)

test:
	$(MAKE) test-unit

test-unit:
	$(ZIG) build test

test-integration:
	PORT=$(TEST_PORT) bash scripts/tests/integration_http.sh

test-all: test-unit test-integration

test-ci: fmt build test-all

fmt:
	$(ZIG) fmt src/*.zig build.zig

check: fmt build test-all

smoke:
	@set -euo pipefail; \
	( $(ZIG) build run -- $(RUN_ARGS) > /tmp/mercury_smoke.log 2>&1 & ); \
	PID=$$!; \
	sleep 1; \
	curl -fsS http://127.0.0.1:$(PORT)/health; echo; \
	curl -fsS http://127.0.0.1:$(PORT)/api/hello; echo; \
	curl -fsS http://127.0.0.1:$(PORT)/metrics; echo; \
	kill $$PID >/dev/null 2>&1 || true; \
	wait $$PID >/dev/null 2>&1 || true; \
	echo "Smoke test concluido com sucesso."

bench:
	THREADS=$(BENCH_THREADS) CONNECTIONS=$(BENCH_CONNECTIONS) DURATION=$(BENCH_DURATION) WARMUP=$(BENCH_WARMUP) ROUNDS=$(BENCH_ROUNDS) CLOSE_CONNECTION=$(BENCH_CLOSE_CONNECTION) bash benchmarks/run.sh

bench-quick:
	THREADS=4 CONNECTIONS=64 DURATION=10s WARMUP=3s ROUNDS=2 CLOSE_CONNECTION=1 bash benchmarks/run.sh

bench-metrics:
	TARGET_URL=http://127.0.0.1:$(PORT)/health METRICS_URL=$(METRICS_URL) THREADS=$(BENCH_THREADS) CONNECTIONS=$(BENCH_CONNECTIONS) DURATION=$(BENCH_DURATION) DURATION_SEC=$(BENCH_DURATION:s=%) bash scripts/metrics/benchmark_with_metrics.sh

metrics-collect:
	METRICS_URL=$(METRICS_URL) DURATION_SEC=$(METRICS_DURATION_SEC) INTERVAL_SEC=$(METRICS_INTERVAL_SEC) OUTPUT_FILE="$(METRICS_OUTPUT)" bash scripts/metrics/collect_metrics.sh

metrics-report:
	@test -n "$(METRICS_FILE)" || (echo "Defina METRICS_FILE=<arquivo_csv>"; exit 1)
	bash scripts/metrics/report_metrics_csv.sh "$(METRICS_FILE)"

bench-go:
	$(GO) run benchmarks/go_server.go

bench-node:
	$(NODE) benchmarks/node_server.js

docker-build:
	docker compose build

docker-up:
	docker compose up -d --build

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f mercury-server

clean:
	rm -rf .zig-cache zig-out

clean-all: clean
	rm -rf benchmarks/results
