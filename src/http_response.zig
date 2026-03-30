const std = @import("std");
const t = @import("types.zig");

/// Serializa e envia uma resposta HTTP/1.1 completa no stream.
pub fn writeResponse(stream: std.net.Stream, res: t.Response) !void {
    const reason = reasonPhrase(res.status_code);
    var header_buf: [512]u8 = undefined;
    const header = try std.fmt.bufPrint(
        &header_buf,
        "HTTP/1.1 {d} {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\nServer: Mercury Server\r\n\r\n",
        .{ res.status_code, reason, res.content_type, res.body.len },
    );

    try stream.writeAll(header);
    try stream.writeAll(res.body);
}

/// Serve um arquivo estático a partir de `static_dir`.
/// Segurança: aplica validação de path para bloquear traversal.
/// Trade-off atual: arquivo é carregado inteiro em memória antes do envio.
pub fn writeStaticFile(stream: std.net.Stream, static_dir: []const u8, target: []const u8, allocator: std.mem.Allocator) !void {
    // Normaliza e valida o alvo antes de tocar o filesystem.
    const file_path = normalizePath(target, allocator) catch return try writeResponse(stream, .{
        .status_code = 400,
        .content_type = "application/json",
        .body = "{\"error\":\"bad path\"}",
    });
    defer allocator.free(file_path);

    const full_path = std.fs.path.join(allocator, &.{ static_dir, file_path }) catch return try writeResponse(stream, .{
        .status_code = 500,
        .content_type = "application/json",
        .body = "{\"error\":\"internal\"}",
    });
    defer allocator.free(full_path);

    const cwd = std.fs.cwd();
    const file = cwd.openFile(full_path, .{}) catch return try writeResponse(stream, .{
        .status_code = 404,
        .content_type = "application/json",
        .body = "{\"error\":\"file not found\"}",
    });
    defer file.close();

    const stat = try file.stat();
    const size: usize = @intCast(stat.size);

    const buf = try allocator.alloc(u8, size);
    defer allocator.free(buf);
    _ = try file.readAll(buf);

    var header_buf: [512]u8 = undefined;
    const header = try std.fmt.bufPrint(
        &header_buf,
        "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\nServer: Mercury Server\r\n\r\n",
        .{ detectContentType(full_path), buf.len },
    );
    try stream.writeAll(header);
    try stream.writeAll(buf);
}

fn normalizePath(target: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (std.mem.eql(u8, target, "/")) return try allocator.dupe(u8, "index.html");

    if (!std.mem.startsWith(u8, target, "/static/")) return error.InvalidPath;

    const rel = target[8..];

    // Reject null bytes (poison for C-backed filesystem calls).
    if (std.mem.indexOfScalar(u8, rel, 0) != null) return error.InvalidPath;

    // Decode percent-encoded sequences before validation so that
    // %2e%2e, %2F, and similar encoded traversal payloads are caught.
    const decoded = percentDecode(rel, allocator) catch return error.InvalidPath;
    defer allocator.free(decoded);

    // Block path traversal in the decoded path.
    if (std.mem.indexOf(u8, decoded, "..") != null) return error.InvalidPath;

    // Reject paths that contain backslashes (Windows-style traversal).
    if (std.mem.indexOfScalar(u8, decoded, '\\') != null) return error.InvalidPath;

    if (decoded.len == 0) return try allocator.dupe(u8, "index.html");

    return allocator.dupe(u8, decoded);
}

/// Decode percent-encoded bytes in a URI path (e.g. %2F -> '/').
fn percentDecode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var out = try allocator.alloc(u8, input.len);
    var i: usize = 0;
    var j: usize = 0;
    while (i < input.len) {
        if (input[i] == '%' and i + 2 < input.len) {
            const high = hexVal(input[i + 1]) orelse return error.InvalidEncoding;
            const low = hexVal(input[i + 2]) orelse return error.InvalidEncoding;
            out[j] = (high << 4) | low;
            i += 3;
        } else {
            out[j] = input[i];
            i += 1;
        }
        j += 1;
    }
    // Shrink to actual length.
    const result = try allocator.dupe(u8, out[0..j]);
    allocator.free(out);
    return result;
}

fn hexVal(c: u8) ?u4 {
    return switch (c) {
        '0'...'9' => @intCast(c - '0'),
        'a'...'f' => @intCast(c - 'a' + 10),
        'A'...'F' => @intCast(c - 'A' + 10),
        else => null,
    };
}

/// Resolve `Content-Type` por extensão de arquivo.
fn detectContentType(path: []const u8) []const u8 {
    if (std.mem.endsWith(u8, path, ".html")) return "text/html; charset=utf-8";
    if (std.mem.endsWith(u8, path, ".css")) return "text/css; charset=utf-8";
    if (std.mem.endsWith(u8, path, ".js")) return "application/javascript";
    if (std.mem.endsWith(u8, path, ".json")) return "application/json";
    if (std.mem.endsWith(u8, path, ".svg")) return "image/svg+xml";
    if (std.mem.endsWith(u8, path, ".png")) return "image/png";
    return "application/octet-stream";
}

/// Frase curta do status HTTP usada na linha de resposta.
fn reasonPhrase(code: u16) []const u8 {
    return switch (code) {
        200 => "OK",
        400 => "Bad Request",
        408 => "Request Timeout",
        413 => "Payload Too Large",
        431 => "Request Header Fields Too Large",
        404 => "Not Found",
        500 => "Internal Server Error",
        else => "OK",
    };
}

test "normalizePath resolves / to index.html" {
    const alloc = std.testing.allocator;
    const result = try normalizePath("/", alloc);
    defer alloc.free(result);
    try std.testing.expectEqualStrings("index.html", result);
}

test "normalizePath resolves valid static path" {
    const alloc = std.testing.allocator;
    const result = try normalizePath("/static/style.css", alloc);
    defer alloc.free(result);
    try std.testing.expectEqualStrings("style.css", result);
}

test "normalizePath rejects path traversal with .." {
    const alloc = std.testing.allocator;
    try std.testing.expectError(error.InvalidPath, normalizePath("/static/../etc/passwd", alloc));
}

test "normalizePath rejects encoded path traversal %2e%2e" {
    const alloc = std.testing.allocator;
    try std.testing.expectError(error.InvalidPath, normalizePath("/static/%2e%2e/etc/passwd", alloc));
}

test "normalizePath rejects backslash traversal" {
    const alloc = std.testing.allocator;
    try std.testing.expectError(error.InvalidPath, normalizePath("/static/..\\etc\\passwd", alloc));
}

test "normalizePath rejects non-static prefix" {
    const alloc = std.testing.allocator;
    try std.testing.expectError(error.InvalidPath, normalizePath("/etc/passwd", alloc));
}

test "normalizePath empty static path resolves to index.html" {
    const alloc = std.testing.allocator;
    const result = try normalizePath("/static/", alloc);
    defer alloc.free(result);
    try std.testing.expectEqualStrings("index.html", result);
}

test "percentDecode decodes basic sequences" {
    const alloc = std.testing.allocator;
    const result = try percentDecode("hello%20world", alloc);
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hello world", result);
}

test "percentDecode passes plain text through" {
    const alloc = std.testing.allocator;
    const result = try percentDecode("plain", alloc);
    defer alloc.free(result);
    try std.testing.expectEqualStrings("plain", result);
}

test "detectContentType returns correct MIME types" {
    try std.testing.expectEqualStrings("text/html; charset=utf-8", detectContentType("index.html"));
    try std.testing.expectEqualStrings("text/css; charset=utf-8", detectContentType("style.css"));
    try std.testing.expectEqualStrings("application/javascript", detectContentType("app.js"));
    try std.testing.expectEqualStrings("application/json", detectContentType("data.json"));
    try std.testing.expectEqualStrings("image/svg+xml", detectContentType("logo.svg"));
    try std.testing.expectEqualStrings("image/png", detectContentType("image.png"));
    try std.testing.expectEqualStrings("application/octet-stream", detectContentType("file.bin"));
}
