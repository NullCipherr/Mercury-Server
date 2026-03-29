const std = @import("std");
const t = @import("types.zig");

pub const max_headers = 32;
pub const ParseLimits = struct {
    // Limites defensivos para evitar abuso de payload/header sem depender de alocação dinâmica.
    max_body_bytes: usize = 1024 * 1024,
    max_target_bytes: usize = 2048,
    max_header_line_bytes: usize = 8192,
};

pub fn parseRequest(buffer: []u8, header_storage: *[max_headers]t.Header, limits: ParseLimits) !t.Request {
    // Parser incremental mínimo: primeiro separa head/body via CRLF CRLF.
    const req_end = std.mem.indexOf(u8, buffer, "\r\n\r\n") orelse return error.IncompleteRequest;
    const head = buffer[0..req_end];
    var body = buffer[req_end + 4 ..];

    var lines = std.mem.splitSequence(u8, head, "\r\n");
    const first = lines.next() orelse return error.BadRequest;

    var parts = std.mem.tokenizeScalar(u8, first, ' ');
    const method_raw = parts.next() orelse return error.BadRequest;
    const target = parts.next() orelse return error.BadRequest;
    const version = parts.next() orelse return error.BadRequest;
    if (target.len > limits.max_target_bytes) return error.TargetTooLarge;

    var header_count: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        if (line.len > limits.max_header_line_bytes) return error.HeaderLineTooLarge;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.BadRequest;
        if (header_count >= max_headers) return error.TooManyHeaders;

        const name = std.mem.trim(u8, line[0..colon], " ");
        const value = std.mem.trim(u8, line[colon + 1 ..], " ");

        // `headers` referencia slices do buffer original: zero-copy e sem custos extras de alocação.
        header_storage[header_count] = .{ .name = name, .value = value };
        header_count += 1;
    }

    const headers = header_storage[0..header_count];
    const content_length = try parseContentLength(headers);
    if (content_length > limits.max_body_bytes) return error.BodyTooLarge;
    if (body.len < content_length) return error.IncompleteBody;
    body = body[0..content_length];

    return .{
        .method = parseMethod(method_raw),
        .target = target,
        .version = version,
        .headers = headers,
        .body = body,
    };
}

fn parseContentLength(headers: []const t.Header) !usize {
    var found = false;
    var value: usize = 0;
    for (headers) |h| {
        if (!std.ascii.eqlIgnoreCase(h.name, "content-length")) continue;
        // `Content-Length` duplicado é tratado como request inválida para evitar ambiguidades.
        if (found) return error.BadRequest;
        value = std.fmt.parseInt(usize, h.value, 10) catch return error.BadRequest;
        found = true;
    }
    return value;
}

fn parseMethod(method: []const u8) t.HttpMethod {
    if (std.mem.eql(u8, method, "GET")) return .GET;
    if (std.mem.eql(u8, method, "POST")) return .POST;
    if (std.mem.eql(u8, method, "PUT")) return .PUT;
    if (std.mem.eql(u8, method, "DELETE")) return .DELETE;
    if (std.mem.eql(u8, method, "PATCH")) return .PATCH;
    if (std.mem.eql(u8, method, "OPTIONS")) return .OPTIONS;
    if (std.mem.eql(u8, method, "HEAD")) return .HEAD;
    return .UNKNOWN;
}

test "parse request basico com content-length" {
    var storage: [max_headers]t.Header = undefined;
    var req_buf: [256]u8 = undefined;
    const raw = try std.fmt.bufPrint(
        &req_buf,
        "POST /api/hello HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\n\r\nabcde",
        .{},
    );

    const req = try parseRequest(raw, &storage, .{});
    try std.testing.expectEqual(t.HttpMethod.POST, req.method);
    try std.testing.expectEqualStrings("/api/hello", req.target);
    try std.testing.expectEqualStrings("abcde", req.body);
}

test "falha quando body excede limite" {
    var storage: [max_headers]t.Header = undefined;
    const raw =
        "POST /x HTTP/1.1\r\nHost: localhost\r\nContent-Length: 20\r\n\r\n12345678901234567890";

    try std.testing.expectError(
        error.BodyTooLarge,
        parseRequest(@constCast(raw), &storage, .{ .max_body_bytes = 8 }),
    );
}

test "falha com body incompleto" {
    var storage: [max_headers]t.Header = undefined;
    const raw = "POST /x HTTP/1.1\r\nHost: localhost\r\nContent-Length: 10\r\n\r\n123";

    try std.testing.expectError(
        error.IncompleteBody,
        parseRequest(@constCast(raw), &storage, .{}),
    );
}
