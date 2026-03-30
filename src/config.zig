const std = @import("std");
const logger_mod = @import("logger.zig");

/// Configuração operacional do servidor.
/// Todos os campos têm defaults seguros para desenvolvimento local.
pub const Config = struct {
    host: []const u8 = "0.0.0.0",
    port: u16 = 8080,
    port_retries: u16 = 20,
    threads: u16 = 0,
    read_timeout_ms: u32 = 2000,
    write_timeout_ms: u32 = 2000,
    max_header_bytes: usize = 16 * 1024,
    max_body_bytes: usize = 1024 * 1024,
    static_dir: []const u8 = "./static",
    log_level: logger_mod.Level = .debug,

    pub fn resolveThreads(self: Config) u16 {
        if (self.threads != 0) return self.threads;
        // Em produção, evitar single-worker por padrão melhora throughput e resiliência a latência.
        const cpu_count = std.Thread.getCpuCount() catch 4;
        return @intCast(@max(cpu_count, 2));
    }
};

/// Faz parsing da CLI e retorna a configuração final.
/// Contrato: flags que exigem valor falham com `error.MissingValue`.
pub fn parseArgs() !Config {
    var cfg = Config{};

    var args = std.process.args();
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--host")) {
            cfg.host = args.next() orelse return error.MissingValue;
        } else if (std.mem.eql(u8, arg, "--port")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.port = try std.fmt.parseInt(u16, value, 10);
        } else if (std.mem.eql(u8, arg, "--threads")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.threads = try std.fmt.parseInt(u16, value, 10);
        } else if (std.mem.eql(u8, arg, "--port-retries")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.port_retries = try std.fmt.parseInt(u16, value, 10);
        } else if (std.mem.eql(u8, arg, "--read-timeout-ms")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.read_timeout_ms = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, arg, "--write-timeout-ms")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.write_timeout_ms = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, arg, "--max-header-bytes")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.max_header_bytes = try std.fmt.parseInt(usize, value, 10);
        } else if (std.mem.eql(u8, arg, "--max-body-bytes")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.max_body_bytes = try std.fmt.parseInt(usize, value, 10);
        } else if (std.mem.eql(u8, arg, "--static-dir")) {
            cfg.static_dir = args.next() orelse return error.MissingValue;
        } else if (std.mem.eql(u8, arg, "--log-level")) {
            const value = args.next() orelse return error.MissingValue;
            cfg.log_level = parseLogLevel(value) orelse return error.InvalidArgument;
        } else if (std.mem.eql(u8, arg, "--help")) {
            printHelp();
            std.process.exit(0);
        } else {
            std.debug.print("Argumento desconhecido: {s}\n", .{arg});
            printHelp();
            return error.InvalidArgument;
        }
    }

    return cfg;
}

fn printHelp() void {
    std.debug.print(
        \\Mercury Server CLI
        \\  --host <ip|hostname>   (default: 0.0.0.0)
        \\  --port <numero>        (default: 8080)
        \\  --port-retries <num>   (default: 20)
        \\  --threads <numero>     (default: CPUs)
        \\  --read-timeout-ms <n>  (default: 2000)
        \\  --write-timeout-ms <n> (default: 2000)
        \\  --max-header-bytes <n> (default: 16384)
        \\  --max-body-bytes <n>   (default: 1048576)
        \\  --static-dir <path>    (default: ./static)
        \\  --log-level <level>    debug|info|warn|err (default: debug)
        \\  --help
        \\ 
    , .{});
}

fn parseLogLevel(value: []const u8) ?logger_mod.Level {
    if (std.mem.eql(u8, value, "debug")) return .debug;
    if (std.mem.eql(u8, value, "info")) return .info;
    if (std.mem.eql(u8, value, "warn")) return .warn;
    if (std.mem.eql(u8, value, "err")) return .err;
    return null;
}
