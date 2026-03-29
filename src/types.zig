const std = @import("std");

/// Métodos HTTP suportados pelo parser.
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

/// Header HTTP normalizado como par nome/valor.
pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

/// Representação interna da request parseada.
/// Observação: campos `target`, `version`, `headers` e `body` podem apontar para slices do buffer de entrada.
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

/// Payload de resposta usado pelo roteador e camada HTTP.
pub const Response = struct {
    status_code: u16,
    content_type: []const u8,
    body: []const u8,
};

/// Resultado de roteamento: resposta direta ou path estático para serving.
pub const RouteResult = union(enum) {
    response: Response,
    static_file: []const u8,
};
