const std = @import("std");

const UUID = @import("./uuid.zig").UUID;

const jsonNull = "null";

/// NullUUID represents a UUID that may be null.
/// NullUUID implements the SQL driver.Scanner interface so
/// it can be used as a scan destination:
///
///  var u uuid.NullUUID
///  err := db.QueryRow("SELECT name FROM foo WHERE id=?", id).Scan(&u)
///  ...
///  if u.Valid {
///     // use u.UUID
///  } else {
///     // NULL value
///  }
///
const NullUUID = struct {
    uuid: UUID,
    valid: bool,

    pub fn init() NullUUID {
        return NullUUID{ .uuid = UUID.init(), .valid = false };
    }

    /// Scan implements the SQL driver.Scanner interface.
    pub fn scan(self: *NullUUID, src: ?*UUID) !void {
        if (src == null) {
            self.valid = false;
        } else {
            self.uuid = src.*;
            self.valid = true;
        }
    }

    /// Value implements the driver Valuer interface.
    pub fn value(self: NullUUID) ?UUID {
        return if (self.valid) self.uuid else null;
    }

    /// MarshalBinary implements encoding.BinaryMarshaler.
    pub fn marshalBinary(self: NullUUID) ![]u8 {
        if (self.valid) {
            return self.uuid.data[0..];
        }
        return null;
    }

    /// UnmarshalBinary implements encoding.BinaryUnmarshaler.
    pub fn unmarshalBinary(self: *NullUUID, data: []const u8) !void {
        if (data.len != 16) return error.InvalidUUID;
        self.uuid = try UUID.parseBytes(data);
        self.valid = true;
    }

    /// MarshalText implements encoding.TextMarshaler.
    pub fn marshalText(self: NullUUID) ![]u8 {
        if (self.valid) {
            return self.uuid.marshalText();
        }
        return jsonNull;
    }

    /// UnmarshalText implements encoding.TextUnmarshaler.
    pub fn unmarshalText(self: *NullUUID, data: []const u8) !void {
        const parsedUUID = UUID.unmarshalText(data) catch return error.InvalidUUID;
        self.uuid = parsedUUID;
        self.valid = true;
    }

    /// MarshalJSON implements json.Marshaler.
    pub fn marshalJSON(self: NullUUID) ![]u8 {
        if (self.valid) {
            return self.uuid.marshalJSON();
        }
        return jsonNull;
    }

    /// UnmarshalJSON implements json.Unmarshaler.
    pub fn unmarshalJSON(self: *NullUUID, data: []const u8) !void {
        if (std.mem.eql(u8, data, jsonNull)) {
            self.* = NullUUID.init();
        } else {
            self.uuid = try UUID.unmarshalJSON(data);
            self.valid = true;
        }
    }
};
