const std = @import("std");

pub const HttpMethod = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    OPTIONS,
    HEAD,
    UNKNOWN,
};

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const Request = struct {
    method: HttpMethod,
    target: []const u8,
    version: []const u8,
    headers: []Header,
    body: []const u8,

    pub fn header(self: Request, name: []const u8) ?[]const u8 {
        for (self.headers) |h| {
            if (std.ascii.eqlIgnoreCase(h.name, name)) return h.value;
        }
        return null;
    }
};

pub const Response = struct {
    status_code: u16,
    content_type: []const u8,
    body: []const u8,
};

pub const RouteResult = union(enum) {
    response: Response,
    static_file: []const u8,
};
