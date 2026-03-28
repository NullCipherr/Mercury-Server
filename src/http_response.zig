const std = @import("std");
const t = @import("types.zig");

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

pub fn writeStaticFile(stream: std.net.Stream, static_dir: []const u8, target: []const u8, allocator: std.mem.Allocator) !void {
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
    if (std.mem.indexOf(u8, rel, "..") != null) return error.InvalidPath;
    if (rel.len == 0) return try allocator.dupe(u8, "index.html");

    return allocator.dupe(u8, rel);
}

fn detectContentType(path: []const u8) []const u8 {
    if (std.mem.endsWith(u8, path, ".html")) return "text/html; charset=utf-8";
    if (std.mem.endsWith(u8, path, ".css")) return "text/css; charset=utf-8";
    if (std.mem.endsWith(u8, path, ".js")) return "application/javascript";
    if (std.mem.endsWith(u8, path, ".json")) return "application/json";
    if (std.mem.endsWith(u8, path, ".svg")) return "image/svg+xml";
    if (std.mem.endsWith(u8, path, ".png")) return "image/png";
    return "application/octet-stream";
}

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
