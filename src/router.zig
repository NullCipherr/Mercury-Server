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
