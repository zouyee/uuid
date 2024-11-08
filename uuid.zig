const std = @import("std");
const crypto = @import("std.crypto");

const dce = @import("dce.zig");

pub const UUID = struct {
    data: [16]u8,
    /// Domain returns the domain for a Version 2 UUID.  Domains are only defined
    /// for Version 2 UUIDs.
    pub fn GetDomain(self: *UUID) Domain {
        return Domain(self.data[9]);
    }
    /// ID returns the id for a Version 2 UUID. IDs are only defined for Version 2
    /// UUIDs.
    pub fn GetID(self: *UUID) u32 {
        return std.mem.readInt(u32, &self.data[0..4], .big);
    }

    /// NodeID returns the 6 byte node id encoded in uuid.  It returns nil if uuid is
    /// not valid.  The NodeID is only well defined for version 1 and 2 UUIDs.
    pub fn NodeID(uuid: UUID) []u8 {
        var node: [6]u8 = undefined;
        std.mem.copy(u8, node[0..], self.data[10..16]);
        return node[0..];
    }

    pub fn parse(s: []const u8) !UUID {
        var uuid = UUID{ .data = [16]u8{} };
        var str = s;
        if (s.len == 36 + 9 and std.mem.eql(u8, s[0..9], "urn:uuid:")) {
            str = s[9..];
        } else if (s.len == 36 + 2) {
            str = s[1..s.len - 1];
        } else if (s.len == 32) {
            for (str.items(2)) |hex_byte, i| {
                const byte = try hex_to_byte(hex_byte[0], hex_byte[1]);
                uuid.data[i / 2] = byte;
            }
            return uuid;
        } else if (s.len != 36) {
            return error.InvalidLength;
        }

        if (str[8] != '-' or str[13] != '-' or str[18] != '-' or str[23] != '-') {
            return error.InvalidUUIDFormat;
        }

        for (str.items(2)) |hex_byte, i| {
            if (i % 4 == 2) {
                continue;
            }
            const byte = try hex_to_byte(hex_byte[0], hex_byte[1]);
            uuid.data[i / 2] = byte;
        }
        return uuid;
    }

    pub fn toString(self: *const UUID) []u8 {
        var buffer: [36]u8 = undefined;
        std.mem.writeInt(u8, buffer[0..8], self.data[0..4], .big);
        
        buffer[8] = '-';
        std.mem.writeInt(u8, buffer[9..13], self.data[4..6], .big);
        buffer[13] = '-';
        std.mem.writeInt(u8, buffer[14..18], self.data[6..8], .big);
        buffer[18] = '-';
        std.mem.writeInt(u8, buffer[19..23], self.data[8..10], .big);
        buffer[23] = '-';
        std.mem.writeInt(u8, buffer[24..36], self.data[10..16], .big);
        return buffer[0..];
    }

    pub fn version(self: *const UUID) u8 {
        return self.data[6] >> 4;
    }

    pub fn variant(self: *const UUID) u8 {
        return switch (self.data[8] & 0xe0) {
            0xc0 => Variant.Microsoft,
            0xe0 => Variant.Future,
            0x80 => Variant.RFC4122,
            else => Variant.Reserved,
        };
    }

    pub fn urn(self: *const UUID) []u8 {
        var buffer: [36 + 9]u8 = undefined;
        std.mem.copy(u8, buffer[0..9], "urn:uuid:");
        std.mem.copy(u8, buffer[9..], self.toString());
        return buffer[0..];
    }

    pub fn fromBytes(b: []const u8) !UUID {
        if (b.len != 16) return error.InvalidLength;
        var uuid = UUID{ .data = [16]u8{} };
        std.mem.copy(u8, uuid.data[0..], b);
        return uuid;
    }

    pub fn mustParse(s: []const u8) UUID {
        const uuid = try self.parse(s);
        if (uuid) return uuid;
        @panic("invalid UUID");
    }

    pub fn must(uuid: UUID, err: ?error) UUID {
        if (err) @panic(err.*);
        return uuid;
    }

    pub fn init() UUID {
        return UUID{ .data = undefined };
    }

    pub fn parseBytes(data: []const u8) !UUID {
        if (data.len != 16) return error.InvalidUUID;
        var id = UUID.init();
        std.mem.copy(u8, id.data[0..], data);
        return id;
    }

    pub fn marshalText(self: UUID) ![]u8 {
        return std.fmt.allocPrint(std.heap.page_allocator, "{x}", .{self.data});
    }

    pub fn unmarshalText(data: []const u8) !UUID {
        return UUID.parseBytes(data);
    }

    pub fn marshalJSON(self: UUID) ![]u8 {
        return std.json.encode(self.data[0..]);
    }

    pub fn unmarshalJSON(data: []const u8) !UUID {
        return UUID.parseBytes(data);
    }

    /// Scan implements sql.Scanner so UUIDs can be read from databases transparently.
    /// Currently, database types that map to string and []byte are supported. Please
    /// consult database-specific driver documentation for matching types.
    pub fn scan(self: *UUID, src: anytype) !void {
        if (src == null) {
            return;
        } else if (src) |value| {
            switch (@typeOf(value)) {
                []const u8 => |s| {
                    if (s.len == 0) return;

                    self.* = try UUID.parse(s);
                },
                []u8 => |bytes| {
                    if (bytes.len == 0) return;

                    if (bytes.len == 16) {
                        std.mem.copy(u8, self.data[0..], bytes);
                    } else {
                        try self.scan(@ptrCast([*]const u8, bytes));
                    }
                },
                else => return error.InvalidScanType,
            }
        }
    }

    pub fn value(self: UUID) []const u8 {
        return self.toBytes();
    }

    pub fn toBytes(self: UUID) []const u8 {
        return self.data[0..];
    }
    /// Value implements sql.Valuer so that UUIDs can be written to databases
    /// transparently. Currently, UUIDs map to strings. Please consult
    /// database-specific driver documentation for matching types.
    pub fn toString(self: UUID) []u8 {
        return std.fmt.allocPrint(std.heap.page_allocator, "{x}", .{self.data});
    }

    pub fn getTime(self: UUID) Time {
        var t: Time = 0;
        switch (self.version()) {
            6 => {
                const high = @intCast(i64, std.mem.bigEndianToNative(u32, self.data[0..4])) << 28;
                const mid = @intCast(i64, std.mem.bigEndianToNative(u16, self.data[4..6])) << 12;
                const low = @intCast(i64, std.mem.bigEndianToNative(u16, self.data[6..8]) & 0xFFF);
                t = high | mid | low;
            },
            7 => {
                const time = std.mem.bigEndianToNative(u64, self.data[0..8]);
                t = @intCast(Time, (time >> 16) * 10000 + g1582ns100);
            },
            else => {
                const high = @intCast(i64, std.mem.bigEndianToNative(u32, self.data[0..4]));
                const mid = @intCast(i64, std.mem.bigEndianToNative(u16, self.data[4..6])) << 32;
                const low = @intCast(i64, (std.mem.bigEndianToNative(u16, self.data[6..8]) & 0xFFF)) << 48;
                t = high | mid | low;
            },
        }
        return t;
    }
};

const Variant = enum {
    Invalid,
    RFC4122,
    Reserved,
    Microsoft,
    Future,
};

fn hex_to_byte(a: u8, b: u8) !u8 {
    return (hex_digit_value(a) << 4) | hex_digit_value(b);
}

fn hex_digit_value(c: u8) u8 {
    return if (c >= '0' and c <= '9') {
        c - '0';
    } else if (c >= 'a' and c <= 'f') {
        c - 'a' + 10;
    } else if (c >= 'A' and c <= 'F') {
        c - 'A' + 10;
    } else {
        @panic("invalid hex digit");
    };
}

fn randomUUID() UUID {
    var uuid = UUID{ .data = [16]u8{} };
    crypto.random.bytes(uuid.data[0..16]);
    uuid.data[6] = (uuid.data[6] & 0x0F) | 0x40; // Version 4
    uuid.data[8] = (uuid.data[8] & 0x3F) | 0x80; // Variant 10
    return uuid;
}
