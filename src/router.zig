const std = @import("std");
const t = @import("types.zig");
const metrics_mod = @import("metrics.zig");

/// Resolve o destino da request em ordem determinística de regras.
/// A sequência de `if`s define prioridade de rotas; mudanças aqui impactam compatibilidade.
pub fn route(req: t.Request, metrics: *metrics_mod.Metrics) t.RouteResult {
    // Métricas entram como dependência para permitir evolução de observabilidade por rota sem mudar assinatura.
    _ = metrics;

    if (std.mem.eql(u8, req.target, "/health")) {
        return .{ .response = .{
            .status_code = 200,
            .content_type = "application/json",
            .body = "{\"status\":\"ok\"}",
        } };
    }

    if (std.mem.eql(u8, req.target, "/api/hello")) {
        return .{ .response = .{
            .status_code = 200,
            .content_type = "application/json",
            .body = "{\"message\":\"Mercury Server online\"}",
        } };
    }

    if (std.mem.eql(u8, req.target, "/") or std.mem.startsWith(u8, req.target, "/static/")) {
        return .{ .static_file = req.target };
    }

    return .{ .response = .{
        .status_code = 404,
        .content_type = "application/json",
        .body = "{\"error\":\"not found\"}",
    } };
}

test "route /health returns 200 ok" {
    var metrics = metrics_mod.Metrics{};
    var headers: [0]t.Header = undefined;
    const req = t.Request{
        .method = .GET,
        .target = "/health",
        .version = "HTTP/1.1",
        .headers = &headers,
        .body = "",
    };
    const result = route(req, &metrics);
    switch (result) {
        .response => |res| {
            try std.testing.expectEqual(@as(u16, 200), res.status_code);
            try std.testing.expect(std.mem.indexOf(u8, res.body, "\"ok\"") != null);
        },
        .static_file => unreachable,
    }
}

test "route /api/hello returns 200" {
    var metrics = metrics_mod.Metrics{};
    var headers: [0]t.Header = undefined;
    const req = t.Request{
        .method = .GET,
        .target = "/api/hello",
        .version = "HTTP/1.1",
        .headers = &headers,
        .body = "",
    };
    const result = route(req, &metrics);
    switch (result) {
        .response => |res| try std.testing.expectEqual(@as(u16, 200), res.status_code),
        .static_file => unreachable,
    }
}

test "route / serves static file" {
    var metrics = metrics_mod.Metrics{};
    var headers: [0]t.Header = undefined;
    const req = t.Request{
        .method = .GET,
        .target = "/",
        .version = "HTTP/1.1",
        .headers = &headers,
        .body = "",
    };
    const result = route(req, &metrics);
    switch (result) {
        .response => unreachable,
        .static_file => |path| try std.testing.expectEqualStrings("/", path),
    }
}

test "route /static/file.css serves static file" {
    var metrics = metrics_mod.Metrics{};
    var headers: [0]t.Header = undefined;
    const req = t.Request{
        .method = .GET,
        .target = "/static/file.css",
        .version = "HTTP/1.1",
        .headers = &headers,
        .body = "",
    };
    const result = route(req, &metrics);
    switch (result) {
        .response => unreachable,
        .static_file => |path| try std.testing.expectEqualStrings("/static/file.css", path),
    }
}

test "route unknown path returns 404" {
    var metrics = metrics_mod.Metrics{};
    var headers: [0]t.Header = undefined;
    const req = t.Request{
        .method = .GET,
        .target = "/nonexistent",
        .version = "HTTP/1.1",
        .headers = &headers,
        .body = "",
    };
    const result = route(req, &metrics);
    switch (result) {
        .response => |res| try std.testing.expectEqual(@as(u16, 404), res.status_code),
        .static_file => unreachable,
    }
}
