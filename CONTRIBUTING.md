# Contributing to Mercury Server

Thank you for your interest in contributing to Mercury Server! This guide will help you get started.

## Getting Started

### Prerequisites

- [Zig](https://ziglang.org/download/) (0.14.0 or later)
- Git
- Make (optional, for convenience targets)
- [wrk](https://github.com/wg/wrk) (optional, for benchmarks)
- Docker (optional, for containerized builds)

### Setting Up the Development Environment

```bash
git clone https://github.com/NullCipherr/Mercury-Server.git
cd Mercury-Server
zig build
zig build test
```

## Development Workflow

1. **Fork** the repository and create a feature branch from `main`.
2. **Write code** following the project conventions (see below).
3. **Run tests** before submitting:
   ```bash
   make test-ci    # fmt + build + unit tests + integration tests
   ```
4. **Commit** using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
   ```
   feat: add request timeout middleware
   fix(parser): handle chunked transfer encoding
   docs: update API endpoint documentation
   test: add router edge case coverage
   chore: update zig version in CI
   ```
5. **Open a Pull Request** against `main` with a clear description.

## Code Conventions

- **Formatting:** Always run `zig fmt` before committing. The CI will reject unformatted code.
- **Naming:** Follow Zig's standard naming conventions (`camelCase` for functions/variables, `PascalCase` for types).
- **Error handling:** Prefer returning errors over panicking. Use `catch` for recoverable errors.
- **Memory:** Use explicit allocators. Never use `std.heap.page_allocator` directly in library code.
- **Comments:** Write comments in English for public APIs. Use `///` doc-comments for exported declarations.
- **Tests:** Add inline tests alongside the code they verify (`test "description" { ... }`).

## Project Structure

```
src/
  main.zig             # Application bootstrap and lifecycle
  server.zig           # Core HTTP server (accept loop, worker pool)
  http_parser.zig      # HTTP/1.1 request parser (zero-copy)
  http_response.zig    # Response serialization and static file serving
  router.zig           # Request routing
  config.zig           # CLI argument parsing
  types.zig            # Core type definitions
  logger.zig           # Thread-safe logging
  metrics.zig          # Runtime observability counters
  connection_pool.zig  # Thread-safe connection queue
```

## Testing

- **Unit tests:** `make test-unit` (or `zig build test`)
- **Integration tests:** `make test-integration` (requires bash)
- **Full CI pipeline:** `make test-ci`

When adding new functionality, include unit tests in the same file using Zig's built-in test blocks.

## Reporting Bugs

Open an issue with:
- A clear title and description
- Steps to reproduce
- Expected vs. actual behavior
- Zig version and OS information

## Suggesting Features

Open an issue tagged as `enhancement` with:
- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold its terms.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
