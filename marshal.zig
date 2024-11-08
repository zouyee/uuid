const std = @import("std");

const UUID = @import("./uuid.zig").UUID;

pub fn encodeHex(out: []u8, uuid: UUID) void {
    std.fmt.bufPrint(out, "{x}-{x}-{x}-{x}-{x}", .{
        uuid[0..4], uuid[4..6], uuid[6..8], uuid[8..10], uuid[10..16]
    });
}

/// MarshalText 将 UUID 转换为文本表示（即十六进制格式）。
pub fn MarshalText(uuid: UUID) ![]u8 {
    var buffer: [36]u8 = undefined;
    encodeHex(&buffer, uuid);
    return buffer[0..36];
}

/// UnmarshalText 解析文本表示的 UUID。
pub fn UnmarshalText(uuid: *UUID, data: []const u8) !void {
    uuid.* = try try UUID.parse(data);
}

/// MarshalBinary 将 UUID 转换为二进制表示。
pub fn MarshalBinary(uuid: UUID) []u8 {
    return uuid[0..];
}

/// UnmarshalBinary 从二进制表示解析 UUID。
pub fn UnmarshalBinary(uuid: *UUID, data: []const u8) !void {
    if (data.len != 16) {
        return error.InvalidUUID;
    }
    @memcpy(uuid.*, data);
}

const ParseError = error {
    InvalidUUID
};

