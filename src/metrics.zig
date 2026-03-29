const std = @import("std");

/// Métricas de runtime compartilhadas entre threads.
/// Os números são eventual-consistent (ordem monotônica) e priorizam baixo overhead.
pub const Metrics = struct {
    total_requests: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    total_errors: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    total_latency_ns: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    accepted_connections: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    worker_failures: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    header_too_large_errors: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    payload_too_large_errors: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    header_fields_too_large_errors: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    bad_request_errors: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    response_2xx: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    response_4xx: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    response_5xx: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),

    pub fn markRequest(self: *Metrics, latency_ns: u64, success: bool) void {
        // Contadores monotônicos: baixo custo para escrita concorrente entre workers.
        _ = self.total_requests.fetchAdd(1, .monotonic);
        _ = self.total_latency_ns.fetchAdd(latency_ns, .monotonic);
        if (!success) _ = self.total_errors.fetchAdd(1, .monotonic);
    }

    pub fn markConnectionAccepted(self: *Metrics) void {
        _ = self.accepted_connections.fetchAdd(1, .monotonic);
    }

    pub fn markWorkerFailure(self: *Metrics) void {
        _ = self.worker_failures.fetchAdd(1, .monotonic);
    }

    pub fn markHeaderTooLarge(self: *Metrics) void {
        _ = self.header_too_large_errors.fetchAdd(1, .monotonic);
    }

    pub fn markPayloadTooLarge(self: *Metrics) void {
        _ = self.payload_too_large_errors.fetchAdd(1, .monotonic);
    }

    pub fn markHeaderFieldsTooLarge(self: *Metrics) void {
        _ = self.header_fields_too_large_errors.fetchAdd(1, .monotonic);
    }

    pub fn markBadRequest(self: *Metrics) void {
        _ = self.bad_request_errors.fetchAdd(1, .monotonic);
    }

    pub fn markResponseStatus(self: *Metrics, status_code: u16) void {
        if (status_code >= 200 and status_code < 300) {
            _ = self.response_2xx.fetchAdd(1, .monotonic);
            return;
        }
        if (status_code >= 400 and status_code < 500) {
            _ = self.response_4xx.fetchAdd(1, .monotonic);
            return;
        }
        if (status_code >= 500 and status_code < 600) {
            _ = self.response_5xx.fetchAdd(1, .monotonic);
        }
    }

    /// Retorna latência média em milissegundos.
    pub fn avgLatencyMs(self: *Metrics) f64 {
        const reqs = self.total_requests.load(.monotonic);
        if (reqs == 0) return 0;
        const total_ns = self.total_latency_ns.load(.monotonic);
        return @as(f64, @floatFromInt(total_ns)) / @as(f64, @floatFromInt(reqs)) / 1_000_000.0;
    }
};

/// Decorador de allocator para telemetria de memória atual/pico.
pub const TrackingAllocator = struct {
    inner: std.mem.Allocator,
    current: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    peak: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),

    pub fn init(inner: std.mem.Allocator) TrackingAllocator {
        return .{ .inner = inner };
    }

    pub fn allocator(self: *TrackingAllocator) std.mem.Allocator {
        // Wrapper para observar uso de memória sem alterar chamadas do restante da aplicação.
        return std.mem.Allocator{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .resize = resize,
                .remap = remap,
                .free = free,
            },
        };
    }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        const self: *TrackingAllocator = @ptrCast(@alignCast(ctx));
        const maybe_ptr = self.inner.rawAlloc(len, ptr_align, ret_addr);
        if (maybe_ptr) |p| {
            const now = self.current.fetchAdd(len, .monotonic) + len;
            // Atualiza pico com CAS para manter consistência sob concorrência.
            while (true) {
                const peak_now = self.peak.load(.monotonic);
                if (now <= peak_now) break;
                if (self.peak.cmpxchgWeak(peak_now, now, .monotonic, .monotonic) == null) break;
            }
            return p;
        }
        return null;
    }

    fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
        const self: *TrackingAllocator = @ptrCast(@alignCast(ctx));
        const ok = self.inner.rawResize(buf, buf_align, new_len, ret_addr);
        if (!ok) return false;

        if (new_len > buf.len) {
            const growth = new_len - buf.len;
            const now = self.current.fetchAdd(growth, .monotonic) + growth;
            while (true) {
                const peak_now = self.peak.load(.monotonic);
                if (now <= peak_now) break;
                if (self.peak.cmpxchgWeak(peak_now, now, .monotonic, .monotonic) == null) break;
            }
        } else if (buf.len > new_len) {
            _ = self.current.fetchSub(buf.len - new_len, .monotonic);
        }
        return true;
    }

    fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        const self: *TrackingAllocator = @ptrCast(@alignCast(ctx));
        const mapped = self.inner.rawRemap(memory, alignment, new_len, ret_addr);
        if (mapped != null) {
            if (new_len > memory.len) {
                const growth = new_len - memory.len;
                const now = self.current.fetchAdd(growth, .monotonic) + growth;
                while (true) {
                    const peak_now = self.peak.load(.monotonic);
                    if (now <= peak_now) break;
                    if (self.peak.cmpxchgWeak(peak_now, now, .monotonic, .monotonic) == null) break;
                }
            } else if (memory.len > new_len) {
                _ = self.current.fetchSub(memory.len - new_len, .monotonic);
            }
        }
        return mapped;
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, ret_addr: usize) void {
        const self: *TrackingAllocator = @ptrCast(@alignCast(ctx));
        self.inner.rawFree(buf, buf_align, ret_addr);
        _ = self.current.fetchSub(buf.len, .monotonic);
    }
};
