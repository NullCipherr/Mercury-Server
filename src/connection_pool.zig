const std = @import("std");

pub const ConnectionPool = struct {
    allocator: std.mem.Allocator,
    queue: std.ArrayListUnmanaged(i32) = .{},
    head: usize = 0,
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    closed: bool = false,

    pub fn init(allocator: std.mem.Allocator) ConnectionPool {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ConnectionPool) void {
        self.queue.deinit(self.allocator);
    }

    pub fn push(self: *ConnectionPool, fd: i32) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        try self.queue.append(self.allocator, fd);
        self.cond.signal();
    }

    pub fn pop(self: *ConnectionPool) ?i32 {
        self.mutex.lock();
        defer self.mutex.unlock();

        while (self.head >= self.queue.items.len and !self.closed) {
            self.cond.wait(&self.mutex);
        }

        if (self.head >= self.queue.items.len and self.closed) return null;

        const fd = self.queue.items[self.head];
        self.head += 1;

        // Compacta periodicamente para evitar crescimento do buffer e manter pop O(1).
        if (self.head >= 1024 and self.head * 2 >= self.queue.items.len) {
            const remaining = self.queue.items.len - self.head;
            std.mem.copyForwards(i32, self.queue.items[0..remaining], self.queue.items[self.head..]);
            self.queue.items.len = remaining;
            self.head = 0;
        }

        return fd;
    }

    pub fn shutdown(self: *ConnectionPool) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.closed = true;
        self.cond.broadcast();
    }
};

test "connection pool push e pop em ordem" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var pool = ConnectionPool.init(gpa.allocator());
    defer pool.deinit();

    try pool.push(10);
    try pool.push(20);
    try std.testing.expectEqual(@as(?i32, 10), pool.pop());
    try std.testing.expectEqual(@as(?i32, 20), pool.pop());
}
