# Testes Automatizados

*[Read in English](../en/TESTING.md)*

## Estratégia adotada

A automação de testes foi separada em camadas para reduzir regressões e facilitar execução em CI local:

- testes unitários em Zig (`zig build test`);
- testes de integração HTTP com servidor real (`scripts/tests/integration_http.sh`);
- pipeline local de validação completa (`make test-ci`).

## Targets de teste no Makefile

- `make test` ou `make test-unit`
  - executa testes unitários.
- `make test-integration`
  - sobe servidor temporário e valida contrato HTTP real.
- `make test-all`
  - executa unitário + integração.
- `make test-ci`
  - executa `fmt + build + test-all`.

## Suite de integração HTTP

Script: `scripts/tests/integration_http.sh`

Coberturas atuais:

- `GET /health` retorna `200` e payload esperado;
- `GET /api/hello` retorna `200` e payload esperado;
- `GET /metrics` respeita contrato JSON esperado;
- rota inexistente retorna `404`;
- `GET /` e `GET /static/index.html` entregam conteúdo estático;
- bloqueio de path traversal (`/static/../...`) com `400`;
- rejeição de header acima do limite com `431`.

## Boas práticas incorporadas

- scripts com `set -euo pipefail`;
- cleanup automático de processo com `trap`;
- logs de execução para troubleshooting;
- fail-fast com mensagem objetiva e contexto;
- teste de integração isolado por porta (`TEST_PORT`, default `18080`).

## Execução recomendada no dia a dia

1. `make test-all` antes de merge.
2. `make test-ci` antes de release.
3. Em incidentes de API, rodar `make test-integration` isoladamente para diagnóstico rápido.
