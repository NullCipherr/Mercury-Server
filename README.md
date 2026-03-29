<div align="center">
  <img src="docs/assets/mercury-logo.png" alt="Logo do Mercury Server" width="220" />
  <h1>☿️ Mercury Server</h1>
  <p><i>Servidor HTTP de baixo nível em Zig com parser manual, pool de conexões e métricas em tempo real</i></p>

  <p>
    <img src="https://img.shields.io/badge/Zig-0.15+-F7A41D?style=for-the-badge&logo=zig&logoColor=white" alt="Zig" />
    <img src="https://img.shields.io/badge/HTTP-1.1-1E88E5?style=for-the-badge" alt="HTTP/1.1" />
    <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Compose" />
    <img src="https://img.shields.io/badge/Make-Automa%C3%A7%C3%A3o-6D4C41?style=for-the-badge" alt="Make" />
  </p>
</div>

---

## 📚 Documentação Modular

A documentação técnica foi organizada em módulos para facilitar onboarding e manutenção:

- [docs/README.md](docs/README.md)
- [docs/ARQUITETURA.md](docs/ARQUITETURA.md)
- [docs/API.md](docs/API.md)
- [docs/OPERACAO_DEPLOY_MANUTENCAO.md](docs/OPERACAO_DEPLOY_MANUTENCAO.md)
- [docs/OBSERVABILIDADE_E_BENCHMARK.md](docs/OBSERVABILIDADE_E_BENCHMARK.md)
- [docs/TESTES_AUTOMATIZADOS.md](docs/TESTES_AUTOMATIZADOS.md)
- [docs/METRICAS_AUTOMACAO_SHELL.md](docs/METRICAS_AUTOMACAO_SHELL.md)
- [docs/ROADMAP_TECNICO.md](docs/ROADMAP_TECNICO.md)

---

## 🖼️ Preview

Interface estática servida pelo próprio Mercury Server em `GET /`:

- arquivo: `static/index.html`
- acesso local: `http://localhost:8080`

---

## ⚡ Visão Geral

O **Mercury Server** é um servidor HTTP escrito em Zig com foco em previsibilidade, baixo overhead e controle explícito de recursos.

O projeto prioriza:

- parser HTTP manual (sem framework web);
- fila thread-safe para desacoplar `accept` e processamento;
- workers fixos para reduzir churn de thread;
- métricas operacionais expostas por endpoint;
- serving de arquivos estáticos com validação de caminho.

---

## ✨ Principais Recursos

- **Parser HTTP manual** com limites de cabeçalho/corpo configuráveis.
- **Pool de conexões thread-safe** para distribuir sockets entre workers.
- **Métricas embutidas** (`/metrics`) com requests, erros e latência média.
- **Hardening básico de I/O** com timeout de leitura e escrita por conexão.
- **Fallback de porta automático** com `--port-retries`.
- **Servidor de arquivos estáticos** (`/` e `/static/*`) com proteção contra path traversal.
- **Execução local e containerizada** com `Makefile` e Docker Compose.

---

## 🧱 Arquitetura

Fluxo principal:

1. `main.zig` inicializa allocator, logger, métricas e configuração.
2. `server.zig` faz bind com retry, recebe conexões e empilha no pool.
3. Workers consomem a fila, aplicam timeouts de socket e processam requests.
4. `http_parser.zig` interpreta request line, headers e valida limites.
5. `router.zig` decide entre resposta JSON, métricas ou arquivo estático.
6. `http_response.zig` serializa resposta HTTP/1.1 e envia ao cliente.

---

## 📈 Performance

O projeto inclui benchmark comparativo contra Go e Node em `benchmarks/`.

- Script principal: `benchmarks/run.sh`
- Saídas: `benchmarks/results/benchmark_YYYYMMDD_HHMMSS.*`
- Métricas acompanhadas:
  - requests/segundo (via `wrk`);
  - latência média;
  - memória atual/pico (TrackingAllocator).

Execução de benchmark:

```bash
bash benchmarks/run.sh
```

Benchmark com parâmetros explícitos:

```bash
THREADS=8 CONNECTIONS=128 DURATION=20s WARMUP=5s ROUNDS=3 CLOSE_CONNECTION=0 bash benchmarks/run.sh
```

## 📊 Resultado Oficial de Benchmark

Pré-publicação (antes do GitHub), consideramos este como o benchmark oficial de referência.

- Data: `2026-03-28` (America/Sao_Paulo)
- Script: `benchmarks/run.sh`
- Parâmetros: `THREADS=4 CONNECTIONS=64 DURATION=8s WARMUP=3s ROUNDS=2 CLOSE_CONNECTION=0`
- Artefatos:
  - `benchmarks/results/benchmark_20260328_173418.raw.log`
  - `benchmarks/results/benchmark_20260328_173418.summary.log`

| Servidor | Rodadas OK | RPS médio | Lat ms med | P50 ms | P90 ms | P99 ms | SockErr méd | ErrPct méd |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Mercury Server | 2 | 34645.01 | 1.75 | 1.65 | 2.13 | 2.73 | 0.00 | 0.00 |
| Go | 2 | 145293.38 | 0.63 | 0.24 | 1.71 | 3.64 | 0.00 | 0.00 |
| Node | 2 | 74361.76 | 0.90 | 0.77 | 1.15 | 2.52 | 0.00 | 0.00 |

---

## 🧪 Desafios Técnicos e Decisões

- **Controle de memória**: uso de `TrackingAllocator` para visibilidade de consumo em runtime.
- **Parser sem alocação no caminho quente**: leitura em buffer fixo para reduzir custo por request.
- **Confiabilidade operacional**: fallback de porta, limites de payload e timeouts de socket.
- **Simplicidade intencional**: escopo HTTP/1.1 essencial, sem abstrações desnecessárias.

---

## 🗺️ Roadmap

Próximos passos recomendados para maturidade de produção:

- suporte robusto a keep-alive e parsing incremental completo;
- streaming de arquivos estáticos para reduzir pico de memória;
- logs estruturados e integração com exportador Prometheus;
- suíte de testes de fuzzing para parser HTTP;
- estratégia de deploy com proxy reverso + TLS + health checks de orquestração.

---

## 🛠️ Stack Tecnológica

- **Linguagem**: Zig (0.15+)
- **Networking**: `std.net` (TCP + sockets)
- **Concorrência**: threads nativas + estrutura de pool
- **Build/Test**: Zig Build System (`zig build`, `zig build test`)
- **Automação local**: Makefile
- **Containerização**: Docker + Docker Compose

---

## 📂 Estrutura do Projeto

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
│   ├── API.md
│   ├── ARQUITETURA.md
│   ├── METRICAS_AUTOMACAO_SHELL.md
│   ├── OBSERVABILIDADE_E_BENCHMARK.md
│   ├── OPERACAO_DEPLOY_MANUTENCAO.md
│   ├── README.md
│   ├── ROADMAP_TECNICO.md
│   └── TESTES_AUTOMATIZADOS.md
├── Makefile
└── README.md
```

---

## 🚀 Como Rodar Localmente

### Pré-requisitos

- Zig `0.15+`
- Make (opcional, mas recomendado)
- Docker 24+ e Docker Compose v2 (opcional)

### Execução direta com Zig

```bash
zig build
zig build run
```

Com parâmetros explícitos:

```bash
zig build run -- --host 0.0.0.0 --port 8080 --threads 8 --static-dir ./static
```

### Execução com Makefile

```bash
make build
make run PORT=8080 THREADS=8
```

### Endpoints locais

- `GET /health`
- `GET /api/hello`
- `GET /metrics`
- `GET /`
- `GET /static/<arquivo>`

---

## 🐳 Deploy Local com Docker

### Build e subida

```bash
docker compose up -d --build
```

Ou via Makefile:

```bash
make docker-build
make docker-up
```

### Operação

```bash
docker compose logs -f mercury-server
docker compose down
```

Ou via Makefile:

```bash
make docker-logs
make docker-down
```

### Acesso

- aplicação: `http://localhost:8080`
- health check manual: `curl -i http://localhost:8080/health`

---

## 📜 Scripts Principais

- `make help`: lista comandos disponíveis.
- `make build`: compila o binário.
- `make run`: executa servidor com argumentos configuráveis por variáveis.
- `make test`: executa testes unitários (`zig build test`).
- `make test-unit`: executa testes unitários (`zig build test`).
- `make test-integration`: executa testes de integração HTTP com servidor real.
- `make test-all`: executa unitários + integração.
- `make test-ci`: executa validação completa local estilo CI (`fmt + build + test-all`).
- `make smoke`: valida `/health`, `/api/hello` e `/metrics`.
- `make bench`: benchmark Mercury x Go x Node.
- `make bench-metrics`: executa `wrk` junto com coleta automática de métricas.
- `make metrics-collect`: coleta `/metrics` em CSV por janela de tempo.
- `make metrics-report`: gera resumo de CSV de métricas.
- `make docker-build`: gera imagem Docker.
- `make docker-up`: sobe container via Docker Compose.
- `make docker-down`: remove stack local.
- `make docker-logs`: acompanha logs do container.

---

## 📦 Licença

Este projeto é **open source** sob a licença **MIT**.

Consulte o arquivo [LICENSE](LICENSE) para os termos completos.

---

<div align="center">
  Feito com Zig e foco em engenharia de baixo nível, observabilidade e evolução incremental.
</div>
