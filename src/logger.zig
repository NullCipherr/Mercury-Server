const std = @import("std");

pub const Level = enum {
    debug,
    info,
    warn,
    err,
};

pub const Logger = struct {
    mutex: std.Thread.Mutex = .{},

    pub fn log(self: *Logger, level: Level, comptime fmt: []const u8, args: anytype) void {
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
