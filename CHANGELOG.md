# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

### Added
- `.gitignore` for Zig build artifacts, benchmark results, and IDE files
- `CONTRIBUTING.md` with development workflow and code conventions
- `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1)
- `SECURITY.md` with vulnerability reporting guidelines
- `CHANGELOG.md` following Keep a Changelog format
- GitHub Actions CI workflow for automated build, test, and format checks
- `.editorconfig` for consistent editor formatting
- Dockerfile healthcheck and pinned Zig version
- Hardened path traversal protection for static file serving
- POSIX signal handling for graceful server shutdown
- Runtime log level filtering via `--log-level` CLI flag
- Expanded unit test coverage for parser, router, and config modules
- English translations for Makefile help and comments

### Fixed
- Tracked `.zig-cache/` and `zig-out/` build artifacts removed from repository
- Tracked benchmark result files removed from repository
- Path traversal vulnerability via URL-encoded sequences in static file paths

### Changed
- README updated for international open-source standards

## [0.1.0] - 2026-03-28

### Added
- Manual HTTP/1.1 parser with zero-copy semantics
- Thread pool-based connection handling with configurable workers
- Static file serving with content-type detection
- `/health`, `/api/hello`, and `/metrics` endpoints
- Connection pool with producer-consumer pattern
- Runtime metrics (requests, latency, memory, error breakdown)
- CLI configuration with 10+ tunable parameters
- Thread-safe logger with millisecond timestamps
- Auto port fallback with `--port-retries`
- Docker multi-stage build support
- Makefile with 20+ automation targets
- Comparative benchmarks (Mercury vs Go vs Node.js)
- Integration test suite via shell scripts
- Comprehensive documentation (architecture, API, operations, testing, observability)
