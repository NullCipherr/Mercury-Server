# Mercury Server Architecture

*[Leia em Português](../pt-br/ARQUITETURA.md)*

## Technical Goals

Mercury Server is a low-level HTTP/1.1 server in Zig, focused on:

- Predictable resource usage;
- Low abstraction overhead;
- Explicit memory and concurrency control;
- Small, evolvable surface area.

## Core Components

- `src/main.zig`
  - Process bootstrap, allocator, logger, metrics, and lifecycle management.
- `src/config.zig`
  - CLI argument parsing and operational defaults.
- `src/server.zig`
  - Bind with retry, accept loop, workers, and request pipeline orchestration.
- `src/connection_pool.zig`
  - Thread-safe file descriptor queue (producer-consumer).
- `src/http_parser.zig`
  - Hand-written parser for request line, headers, and body with limits.
- `src/router.zig`
  - Endpoint routing and delegation to JSON/static responses.
- `src/http_response.zig`
  - HTTP response serialization and static file delivery.
- `src/metrics.zig`
  - Atomic counters and `TrackingAllocator` for current/peak memory.
- `src/logger.zig`
  - Thread-safe logger with timestamps and level filtering.
- `src/types.zig`
  - Request/response contracts and routing types.

## Request Flow

1. The server listens on `host:port` with configurable fallback (`--port-retries`).
2. The accept loop receives TCP connections and pushes the socket into `ConnectionPool`.
3. Workers consume sockets from the queue and apply read/write timeouts.
4. Reading continues until `\r\n\r\n` is found, respecting the configured header size limit.
5. The parser processes method, target, version, headers, and `Content-Length`.
6. For `/metrics`, the response is built directly in `server.zig`.
7. All other routes go through `router.zig`:
   - `/health`, `/api/hello` return JSON.
   - `/` and `/static/*` serve static files.
   - Other paths return 404.
8. The connection is closed after the response (`Connection: close`).
9. Atomic metrics are updated at the end of each request.

## Concurrency

- Model: fixed thread pool + shared queue.
- Worker count:
  - Explicit via `--threads`, or
  - Falls back to CPU count (minimum 2).
- `ConnectionPool` uses mutex + condition variable.
- Periodic compaction of the internal queue buffer prevents unbounded growth.

## Memory

- The server uses `GeneralPurposeAllocator` in the main process.
- `TrackingAllocator` wraps the base allocator to measure:
  - Current memory (`current`);
  - Peak memory (`peak`).
- On shutdown, the process signals a leak if GPA detects one.

## Limits and Hardening

- Header byte limit (`--max-header-bytes`);
- Body byte limit (`--max-body-bytes`);
- Target and header line size limits in the parser;
- Per-connection read/write timeouts (`SO_RCVTIMEO`, `SO_SNDTIMEO`);
- Path traversal protection on static files (percent-decoded `..` and `\` blocked);
- Graceful shutdown via POSIX signal handling (SIGINT/SIGTERM).

## Current Limitations

- Simple HTTP/1.1 model without persistent keep-alive;
- Static file reads load the entire file into memory (no streaming);
- Parser requires complete headers buffered, no robust incremental parsing for extreme fragmentation.
