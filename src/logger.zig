const std = @import("std");

pub const Level = enum {
    debug,
    info,
    warn,
    err,
};

/// Logger síncrono com serialização por mutex para evitar interleaving em ambiente multithread.
pub const Logger = struct {
    mutex: std.Thread.Mutex = .{},
    min_level: Level = .debug,

    pub fn log(self: *Logger, level: Level, comptime fmt: []const u8, args: anytype) void {
        if (@intFromEnum(level) < @intFromEnum(self.min_level)) return;

        self.mutex.lock();
        defer self.mutex.unlock();

        const ts_ms = std.time.milliTimestamp();
        std.debug.print("[{d}] {s} ", .{ ts_ms, levelToStr(level) });
        std.debug.print(fmt, args);
        std.debug.print("\n", .{});
    }

    fn levelToStr(level: Level) []const u8 {
        return switch (level) {
            .debug => "DEBUG",
            .info => "INFO",
            .warn => "WARN",
            .err => "ERROR",
        };
    }
};
