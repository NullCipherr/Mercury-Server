const std = @import("std");
const t = @import("types.zig");
const metrics_mod = @import("metrics.zig");

pub fn route(req: t.Request, metrics: *metrics_mod.Metrics) t.RouteResult {
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
