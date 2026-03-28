const std = @import("std");
const config = @import("config.zig");
const logger_mod = @import("logger.zig");
const metrics_mod = @import("metrics.zig");
const server_mod = @import("server.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("Aviso: vazamento de memória detectado\n", .{});
        }
    }

    var tracking = metrics_mod.TrackingAllocator.init(gpa.allocator());
    const alloc = tracking.allocator();

    var logger = logger_mod.Logger{};
    var metrics = metrics_mod.Metrics{};

    const cfg = config.parseArgs() catch |err| {
        logger.log(.err, "falha ao parsear argumentos: {s}", .{@errorName(err)});
        return err;
    };

    var server = server_mod.Server.init(alloc, cfg, &logger, &metrics);
    defer server.deinit();

    server.run() catch |err| {
        logger.log(.err, "erro fatal: {s}", .{@errorName(err)});
        return err;
    };

    logger.log(.info, "requests totais: {d}", .{metrics.total_requests.load(.monotonic)});
    logger.log(.info, "erros totais: {d}", .{metrics.total_errors.load(.monotonic)});
    logger.log(.info, "latência média (ms): {d:.3}", .{metrics.avgLatencyMs()});
    logger.log(.info, "memória atual (bytes): {d}", .{tracking.current.load(.monotonic)});
    logger.log(.info, "pico memória (bytes): {d}", .{tracking.peak.load(.monotonic)});
}
