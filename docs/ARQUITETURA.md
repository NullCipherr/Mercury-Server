# Arquitetura do Mercury Server

## Objetivo técnico

O Mercury Server é um servidor HTTP/1.1 de baixo nível em Zig, com foco em:

- previsibilidade de uso de recursos;
- baixa sobrecarga de abstrações;
- controle explícito de memória e concorrência;
- superfície pequena e evolutiva.

## Componentes principais

- `src/main.zig`
  - bootstrap do processo, allocator, logger, métricas e ciclo de vida.
- `src/config.zig`
  - parsing de argumentos CLI e defaults operacionais.
- `src/server.zig`
  - bind com retry, accept loop, workers e orquestração da pipeline de request.
- `src/connection_pool.zig`
  - fila thread-safe de file descriptors (producer-consumer).
- `src/http_parser.zig`
  - parser manual da request line, headers e body com limites.
- `src/router.zig`
  - roteamento dos endpoints e delegação para resposta JSON/static.
- `src/http_response.zig`
  - serialização de resposta HTTP e entrega de arquivos estáticos.
- `src/metrics.zig`
  - contadores atômicos e `TrackingAllocator` para memória atual/pico.
- `src/logger.zig`
  - logger thread-safe com timestamp.
- `src/types.zig`
  - contratos de request/response e tipos de roteamento.

## Fluxo de request

1. O servidor faz `listen` em `host:port` com fallback configurável (`--port-retries`).
2. O loop de `accept` recebe conexões TCP e empilha o socket no `ConnectionPool`.
3. Workers consomem sockets da fila e aplicam timeout de leitura/escrita no socket.
4. A leitura ocorre até encontrar `\r\n\r\n`, respeitando limite máximo configurado de cabeçalho.
5. O parser processa método, target, versão, headers e `Content-Length`.
6. Para `/metrics`, a resposta é montada direto no `server.zig`.
7. Demais rotas vão para `router.zig`:
  - `/health`, `/api/hello` retornam JSON.
  - `/` e `/static/*` retornam arquivo estático.
  - demais paths retornam 404.
8. A conexão é encerrada após resposta (`Connection: close`).
9. Métricas atômicas são atualizadas ao final de cada processamento.

## Concorrência

- Modelo: thread pool fixo + fila compartilhada.
- Quantidade de workers:
  - `--threads` explícito, ou
  - fallback para quantidade de CPUs (mínimo 2).
- O `ConnectionPool` usa mutex + condition variable.
- Há compactação periódica do buffer interno da fila para evitar crescimento indefinido.

## Memória

- O servidor usa `GeneralPurposeAllocator` no processo principal.
- O `TrackingAllocator` encapsula o allocator base para medir:
  - memória atual (`current`);
  - pico (`peak`).
- No encerramento, o processo sinaliza vazamento se o GPA detectar leak.

## Limites e hardening já implementados

- limite de bytes para cabeçalho (`--max-header-bytes`);
- limite de bytes para corpo (`--max-body-bytes`);
- limite de tamanho de target e linha de header no parser;
- timeouts de leitura/escrita por conexão (`SO_RCVTIMEO`, `SO_SNDTIMEO`);
- proteção contra path traversal em static files (`..` bloqueado).

## Limitações atuais

- modelo simples HTTP/1.1 sem keep-alive persistente;
- leitura de arquivo estático inteira em memória (sem streaming);
- parser orientado a request completa, sem parsing incremental robusto para fragmentação extrema.
