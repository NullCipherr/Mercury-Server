FROM debian:bookworm-slim AS builder

ARG ZIG_VERSION=0.14.1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
      amd64) ZIG_ARCH="x86_64" ;; \
      arm64) ZIG_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture for Zig download: $ARCH" && exit 1 ;; \
    esac; \
    curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz; \
    tar -xf /tmp/zig.tar.xz -C /opt; \
    ln -s "/opt/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}/zig" /usr/local/bin/zig; \
    rm -f /tmp/zig.tar.xz

COPY build.zig ./
COPY src ./src
COPY static ./static

RUN zig build -Doptimize=ReleaseFast

FROM debian:bookworm-slim AS runtime

WORKDIR /app

COPY --from=builder /app/zig-out/bin/mercury-server /app/mercury-server
COPY --from=builder /app/static /app/static

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

ENTRYPOINT ["/app/mercury-server"]
CMD ["--host", "0.0.0.0", "--port", "8080", "--static-dir", "./static"]
