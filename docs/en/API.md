# Mercury Server API

*[Leia em Português](../pt-br/API.md)*

Base URL: `http://127.0.0.1:8080`

## Endpoints

### `GET /health`

Basic application health check.

Success response (`200`):

```json
{"status":"ok"}
```

### `GET /api/hello`

Functional verification endpoint.

Success response (`200`):

```json
{"message":"Mercury Server online"}
```

### `GET /metrics`

Returns aggregated process metrics.

Success response (`200`):

```json
{
  "requests": 12,
  "errors": 1,
  "avg_latency_ms": 0.423,
  "connections_accepted": 13,
  "worker_failures": 0,
  "error_breakdown": {
    "header_too_large": 0,
    "payload_too_large": 0,
    "header_fields_too_large": 0,
    "bad_request": 1
  },
  "response_status": {
    "2xx": 11,
    "4xx": 1,
    "5xx": 0
  }
}
```

Fields:

- `requests`: total requests processed.
- `errors`: total requests that ended with a processing failure.
- `avg_latency_ms`: cumulative average latency in milliseconds.
- `connections_accepted`: connections accepted on the listen socket.
- `worker_failures`: processing failures caught at the worker level.
- `error_breakdown`: error count by category.
- `response_status`: aggregated count by HTTP status family.

### `GET /`

Serves `static/index.html`.

### `GET /static/<file>`

Serves files from the directory configured via `--static-dir`.

Example:

- `GET /static/index.html`

## Error Codes

- `400 Bad Request`
  - Malformed request or invalid path.
- `404 Not Found`
  - Unknown route or static file not found.
- `413 Payload Too Large`
  - Body exceeds `--max-body-bytes`.
- `431 Request Header Fields Too Large`
  - Headers exceed configured limits.
- `500 Internal Server Error`
  - Unrecoverable internal failures during response generation.

## Response Headers

All responses include:

- `Content-Type`
- `Content-Length`
- `Connection: close`
- `Server: Mercury Server`
