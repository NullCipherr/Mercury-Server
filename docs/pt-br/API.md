# API do Mercury Server

*[Read in English](../en/API.md)*

Base URL local: `http://127.0.0.1:8080`

## Endpoints

### `GET /health`

Health check básico da aplicação.

Resposta de sucesso (`200`):

```json
{"status":"ok"}
```

### `GET /api/hello`

Endpoint de verificação funcional.

Resposta de sucesso (`200`):

```json
{"message":"Mercury Server online"}
```

### `GET /metrics`

Retorna métricas agregadas do processo.

Resposta de sucesso (`200`):

```json
{"requests":12,"errors":1,"avg_latency_ms":0.423}
```

Campos:

- `requests`: total de requests processadas.
- `errors`: total de requests que terminaram com falha no processamento.
- `avg_latency_ms`: latência média acumulada em milissegundos.

### `GET /`

Serve `static/index.html`.

### `GET /static/<arquivo>`

Serve arquivos do diretório configurado em `--static-dir`.

Exemplo:

- `GET /static/index.html`

## Códigos de erro relevantes

- `400 Bad Request`
  - request malformada ou path inválido.
- `404 Not Found`
  - rota inexistente ou arquivo estático não encontrado.
- `413 Payload Too Large`
  - corpo excede `--max-body-bytes`.
- `431 Request Header Fields Too Large`
  - cabeçalho excede limites.
- `500 Internal Server Error`
  - falhas internas não recuperáveis na geração de resposta.

## Headers de resposta

As respostas incluem:

- `Content-Type`
- `Content-Length`
- `Connection: close`
- `Server: Mercury Server`
