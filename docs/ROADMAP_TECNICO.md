# Roadmap Técnico

Este roadmap foca nos próximos passos para elevar o Mercury Server de base sólida para uso mais robusto em produção.

## Prioridade alta

- implementar suporte mais completo a keep-alive;
- evoluir parser para modelo incremental com cenários de fragmentação mais agressivos;
- adicionar streaming para arquivos estáticos (evitando leitura total em memória).

## Prioridade média

- padronizar logs estruturados (JSON) para integração com stack de observabilidade;
- expor métricas em formato Prometheus;
- ampliar testes automatizados para cenários de regressão em parser/roteamento.

## Prioridade estratégica

- adicionar fuzzing no parser HTTP;
- definir estratégia formal de deploy com proxy reverso + TLS;
- incluir health checks e práticas de readiness/liveness para orquestração.

## Critérios de evolução

Para considerar o projeto em estágio de produção operacional:

1. cobertura de testes consistente para parser e fluxo de conexão;
2. comportamento previsível sob carga sustentada;
3. observabilidade suficiente para diagnóstico de incidentes;
4. documentação de operação e rollback revisada e atualizada.
