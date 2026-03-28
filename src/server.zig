const std = @import("std");
const config_mod = @import("config.zig");
const parser = @import("http_parser.zig");
const pool_mod = @import("connection_pool.zig");
const router = @import("router.zig");
const types = @import("types.zig");
const response = @import("http_response.zig");
const logger_mod = @import("logger.zig");
const metrics_mod = @import("metrics.zig");

pub const Server = struct {
    const max_read_buffer_bytes = 64 * 1024;

    allocator: std.mem.Allocator,
    cfg: config_mod.Config,
    pool: pool_mod.ConnectionPool,
    logger: *logger_mod.Logger,
    metrics: *metrics_mod.Metrics,
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(true),

    pub fn init(
        allocator: std.mem.Allocator,
        cfg: config_mod.Config,
        logger: *logger_mod.Logger,
        metrics: *metrics_mod.Metrics,
    ) Server {
        return .{
            .allocator = allocator,
            .cfg = cfg,
            .pool = pool_mod.ConnectionPool.init(allocator),
            .logger = logger,
            .metrics = metrics,
        };
    }

    pub fn deinit(self: *Server) void {
        self.pool.deinit();
    }

    pub fn run(self: *Server) !void {
        if (self.cfg.max_header_bytes == 0 or self.cfg.max_header_bytes > max_read_buffer_bytes) {
            return error.InvalidHeaderLimit;
        }

        const bound = try self.bindWithRetry();
        var tcp_server = bound.server;
        defer tcp_server.deinit();

        const worker_count = self.cfg.resolveThreads();
        const workers = try self.allocator.alloc(std.Thread, worker_count);
        defer self.allocator.free(workers);

        var worker_ctx = try self.allocator.alloc(WorkerContext, worker_count);
        defer self.allocator.free(worker_ctx);

        for (workers, 0..) |*thread, i| {
            worker_ctx[i] = .{ .server = self, .worker_id = i };
            thread.* = try std.Thread.spawn(.{}, workerMain, .{&worker_ctx[i]});
        }

        self.logger.log(.info, "Mercury Server ouvindo em {s}:{d} com {d} workers", .{ self.cfg.host, bound.port, worker_count });

        while (self.running.load(.monotonic)) {
            const conn = tcp_server.accept() catch |err| {
                self.logger.log(.warn, "erro no accept: {s}", .{@errorName(err)});
                continue;
            };
            errdefer conn.stream.close();

            self.metrics.markConnectionAccepted();
            try self.pool.push(conn.stream.handle);
        }

        self.pool.shutdown();
        for (workers) |t| t.join();
    }

    fn bindWithRetry(self: *Server) !struct { server: std.net.Server, port: u16 } {
        var port = self.cfg.port;
        var attempt: u16 = 0;

        while (true) : (attempt += 1) {
            const address = try std.net.Address.parseIp(self.cfg.host, port);
            const server = address.listen(.{ .reuse_address = true }) catch |err| switch (err) {
                error.AddressInUse => {
                    if (attempt >= self.cfg.port_retries or port == std.math.maxInt(u16)) return error.AddressInUse;
                    self.logger.log(
                        .warn,
                        "porta {d} em uso, tentando {d} (tentativa {d}/{d})",
                        .{ port, port + 1, attempt + 1, self.cfg.port_retries + 1 },
                    );
                    port += 1;
                    continue;
                },
                else => return err,
            };

            return .{ .server = server, .port = port };
        }
    }

    const WorkerContext = struct {
        server: *Server,
        worker_id: usize,
    };

    fn workerMain(ctx: *WorkerContext) void {
        const server = ctx.server;
        server.logger.log(.info, "worker {d} iniciado", .{ctx.worker_id});

        while (server.running.load(.monotonic)) {
            const maybe_fd = server.pool.pop();
            if (maybe_fd == null) break;

            const fd = maybe_fd.?;
            var stream = std.net.Stream{ .handle = fd };
            const start = std.time.nanoTimestamp();

            setSocketTimeouts(fd, server.cfg.read_timeout_ms, server.cfg.write_timeout_ms) catch |err| {
                server.logger.log(.warn, "worker {d} falhou ao configurar timeout: {s}", .{ ctx.worker_id, @errorName(err) });
            };

            const ok = handleConnection(server, stream) catch |err| blk: {
                server.logger.log(.warn, "worker {d} falhou ao processar conexão: {s}", .{ ctx.worker_id, @errorName(err) });
                server.metrics.markWorkerFailure();
                break :blk false;
            };

            stream.close();

            const elapsed_ns: u64 = @intCast(@max(std.time.nanoTimestamp() - start, 0));
            server.metrics.markRequest(elapsed_ns, ok);
        }

        server.logger.log(.info, "worker {d} finalizado", .{ctx.worker_id});
    }

    fn handleConnection(server: *Server, stream: std.net.Stream) !bool {
        var read_buf: [max_read_buffer_bytes]u8 = undefined;
        const bytes_read = readUntilHeadersComplete(stream, read_buf[0..server.cfg.max_header_bytes]) catch |err| switch (err) {
            error.HeaderTooLarge => {
                server.metrics.markHeaderTooLarge();
                server.metrics.markResponseStatus(431);
                try response.writeResponse(stream, .{
                    .status_code = 431,
                    .content_type = "application/json",
                    .body = "{\"error\":\"header too large\"}",
                });
                return false;
            },
            else => return err,
        };
        if (bytes_read == 0) return false;

        var headers: [parser.max_headers]types.Header = undefined;
        const req = parser.parseRequest(
            read_buf[0..bytes_read],
            &headers,
            .{ .max_body_bytes = server.cfg.max_body_bytes },
        ) catch |err| {
            switch (err) {
                error.BodyTooLarge => {
                    server.metrics.markPayloadTooLarge();
                    server.metrics.markResponseStatus(413);
                    try response.writeResponse(stream, .{
                        .status_code = 413,
                        .content_type = "application/json",
                        .body = "{\"error\":\"payload too large\"}",
                    });
                },
                error.TooManyHeaders, error.HeaderLineTooLarge, error.TargetTooLarge => {
                    server.metrics.markHeaderFieldsTooLarge();
                    server.metrics.markResponseStatus(431);
                    try response.writeResponse(stream, .{
                        .status_code = 431,
                        .content_type = "application/json",
                        .body = "{\"error\":\"request header fields too large\"}",
                    });
                },
                else => {
                    server.metrics.markBadRequest();
                    server.metrics.markResponseStatus(400);
                    try response.writeResponse(stream, .{
                        .status_code = 400,
                        .content_type = "application/json",
                        .body = "{\"error\":\"bad request\"}",
                    });
                },
            }
            return false;
        };

        if (std.mem.eql(u8, req.target, "/metrics")) {
            var metrics_buf: [1024]u8 = undefined;
            const total = server.metrics.total_requests.load(.monotonic);
            const errors = server.metrics.total_errors.load(.monotonic);
            const latency = server.metrics.avgLatencyMs();
            const accepted = server.metrics.accepted_connections.load(.monotonic);
            const worker_failures = server.metrics.worker_failures.load(.monotonic);
            const header_too_large = server.metrics.header_too_large_errors.load(.monotonic);
            const payload_too_large = server.metrics.payload_too_large_errors.load(.monotonic);
            const header_fields_too_large = server.metrics.header_fields_too_large_errors.load(.monotonic);
            const bad_request = server.metrics.bad_request_errors.load(.monotonic);
            const response_2xx = server.metrics.response_2xx.load(.monotonic);
            const response_4xx = server.metrics.response_4xx.load(.monotonic);
            const response_5xx = server.metrics.response_5xx.load(.monotonic);
            const body = std.fmt.bufPrint(
                &metrics_buf,
                "{{\"requests\":{d},\"errors\":{d},\"avg_latency_ms\":{d:.3},\"connections_accepted\":{d},\"worker_failures\":{d},\"error_breakdown\":{{\"header_too_large\":{d},\"payload_too_large\":{d},\"header_fields_too_large\":{d},\"bad_request\":{d}}},\"response_status\":{{\"2xx\":{d},\"4xx\":{d},\"5xx\":{d}}}}}",
                .{
                    total,
                    errors,
                    latency,
                    accepted,
                    worker_failures,
                    header_too_large,
                    payload_too_large,
                    header_fields_too_large,
                    bad_request,
                    response_2xx,
                    response_4xx,
                    response_5xx,
                },
            ) catch "{}";

            server.metrics.markResponseStatus(200);
            try response.writeResponse(stream, .{
                .status_code = 200,
                .content_type = "application/json",
                .body = body,
            });
            return true;
        }

        const routed = router.route(req, server.metrics);
        switch (routed) {
            .response => |res| {
                server.metrics.markResponseStatus(res.status_code);
                try response.writeResponse(stream, res);
            },
            .static_file => |target| {
                server.metrics.markResponseStatus(200);
                try response.writeStaticFile(stream, server.cfg.static_dir, target, server.allocator);
            },
        }
        return true;
    }

    fn readUntilHeadersComplete(stream: std.net.Stream, buffer: []u8) !usize {
        var total: usize = 0;

        while (total < buffer.len) {
            const n = try stream.read(buffer[total..]);
            if (n == 0) return total;
            total += n;

            if (std.mem.indexOf(u8, buffer[0..total], "\r\n\r\n") != null) {
                return total;
            }
        }

        if (std.mem.indexOf(u8, buffer[0..total], "\r\n\r\n") == null) return error.HeaderTooLarge;
        return total;
    }

    fn setSocketTimeouts(fd: std.posix.socket_t, read_timeout_ms: u32, write_timeout_ms: u32) !void {
        var read_tv = timevalFromMs(read_timeout_ms);
        try std.posix.setsockopt(
            fd,
            std.posix.SOL.SOCKET,
            std.posix.SO.RCVTIMEO,
            std.mem.asBytes(&read_tv),
        );

        var write_tv = timevalFromMs(write_timeout_ms);
        try std.posix.setsockopt(
            fd,
            std.posix.SOL.SOCKET,
            std.posix.SO.SNDTIMEO,
            std.mem.asBytes(&write_tv),
        );
    }

    fn timevalFromMs(timeout_ms: u32) std.posix.timeval {
        return .{
            .sec = @as(isize, @intCast(timeout_ms / 1000)),
            .usec = @as(isize, @intCast((timeout_ms % 1000) * 1000)),
        };
    }
};
