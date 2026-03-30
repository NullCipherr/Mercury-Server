# Technical Roadmap

*[Leia em Português](../pt-br/ROADMAP_TECNICO.md)*

This roadmap focuses on the next steps to evolve Mercury Server from a solid foundation to more robust production usage.

## High Priority

- Implement more complete keep-alive support.
- Evolve the parser to an incremental model with more aggressive fragmentation scenarios.
- Add streaming for static files (avoiding full in-memory reads).

## Medium Priority

- Standardize structured logs (JSON) for integration with observability stacks.
- Expose metrics in Prometheus format.
- Expand automated tests for regression scenarios in parser/routing.

## Strategic Priority

- Add fuzzing for the HTTP parser.
- Define a formal deployment strategy with reverse proxy + TLS.
- Include health checks and readiness/liveness practices for orchestration.

## Evolution Criteria

For the project to be considered at an operational production stage:

1. Consistent test coverage for the parser and connection flow.
2. Predictable behavior under sustained load.
3. Sufficient observability for incident diagnosis.
4. Reviewed and up-to-date operations and rollback documentation.
