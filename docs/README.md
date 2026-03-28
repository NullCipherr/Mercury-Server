# Mercury Server - Documentação Modular

Esta pasta centraliza a documentação técnica do projeto de forma modular, para facilitar onboarding, manutenção e handoff.

## Índice

- [ARQUITETURA.md](ARQUITETURA.md)
  - visão de componentes, fluxo de request, concorrência e memória.
- [API.md](API.md)
  - contratos dos endpoints, exemplos de request/response e códigos de erro.
- [OPERACAO_DEPLOY_MANUTENCAO.md](OPERACAO_DEPLOY_MANUTENCAO.md)
  - execução local, Docker, Makefile, troubleshooting e rotina de manutenção.
- [OBSERVABILIDADE_E_BENCHMARK.md](OBSERVABILIDADE_E_BENCHMARK.md)
  - métricas internas, logs, benchmark comparativo e leitura de resultados.
- [TESTES_AUTOMATIZADOS.md](TESTES_AUTOMATIZADOS.md)
  - estratégia de testes, suíte de integração e pipeline local de CI.
- [METRICAS_AUTOMACAO_SHELL.md](METRICAS_AUTOMACAO_SHELL.md)
  - coleta automatizada de métricas via scripts shell e geração de relatório.
- [ROADMAP_TECNICO.md](ROADMAP_TECNICO.md)
  - lacunas atuais para produção e próximos incrementos recomendados.

## Como usar esta documentação

1. Comece por `ARQUITETURA.md` para entender o desenho do servidor.
2. Em seguida, consulte `API.md` para contratos de integração.
3. Para subir e operar o ambiente, use `OPERACAO_DEPLOY_MANUTENCAO.md`.
4. Para análise de comportamento e desempenho, use `OBSERVABILIDADE_E_BENCHMARK.md`.
5. Para automação de testes, use `TESTES_AUTOMATIZADOS.md`.
6. Para automação de métricas, use `METRICAS_AUTOMACAO_SHELL.md`.
7. Para planejamento de evolução, use `ROADMAP_TECNICO.md`.
