# Operação, Deploy e Manutenção

*[Read in English](../en/OPERATIONS.md)*

## Pré-requisitos

- Zig `0.15+`
- Docker 24+ e Docker Compose v2 (opcional)
- Make (opcional)

## Execução local (sem Docker)

Build:

```bash
zig build
```

Execução padrão:

```bash
zig build run
```

Execução com parâmetros:

```bash
zig build run -- --host 0.0.0.0 --port 8080 --threads 8 --static-dir ./static
```

## Execução com Makefile

```bash
make build
make run PORT=8080 THREADS=8
make test-all
make smoke
```

Pipeline local de qualidade:

```bash
make test-ci
```

## Execução com Docker

Build e subida:

```bash
docker compose up -d --build
```

Logs e parada:

```bash
docker compose logs -f mercury-server
docker compose down
```

Atalhos via Make:

```bash
make docker-build
make docker-up
make docker-logs
make docker-down
```

## Parâmetros de runtime (CLI)

- `--host` (default: `0.0.0.0`)
- `--port` (default: `8080`)
- `--port-retries` (default: `20`)
- `--threads` (default: CPUs, mínimo 2)
- `--read-timeout-ms` (default: `2000`)
- `--write-timeout-ms` (default: `2000`)
- `--max-header-bytes` (default: `16384`)
- `--max-body-bytes` (default: `1048576`)
- `--static-dir` (default: `./static`)

## Troubleshooting

### Porta em uso

Erro típico: `AddressInUse`.

Ações:

1. trocar porta na execução (`--port`);
2. aumentar `--port-retries`;
3. liberar processo que ocupa a porta.

### Docker não sobe em `8080`

Se `8080` já estiver em uso no host, ajuste o mapeamento em `docker-compose.yml` para algo como `18080:8080`.

### Erros 431/413 frequentes

- revisar payload e tamanho de headers do cliente;
- ajustar limites de `--max-header-bytes` e `--max-body-bytes` com critério;
- monitorar efeitos em memória e latência.

## Rotina de manutenção recomendada

1. Executar `zig build test` antes de cada release.
2. Rodar `make smoke` após mudanças em parser/roteamento.
3. Registrar benchmark de referência após alterações de performance.
4. Revisar roadmap técnico a cada incremento relevante.
5. Coletar métricas com shell script em cenários críticos de mudança.
