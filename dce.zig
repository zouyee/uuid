// Copyright zouyee All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

const std = @import("std");

const UUID = @import("./uuid.zig");

/// A Domain represents a Version 2 domain
const Domain = enum(u8) {
    /// Domain constants for DCE Security (Version 2) UUIDs.
    Person = 0,
    Group = 1,
    Org = 2,

    pub fn toString(self: Domain) []const u8 {
        return switch (self) {
            .Person => "Person",
            .Group => "Group",
            .Org => "Org",
            else => {
                var buf: [10]u8 = undefined;
                const len = std.fmt.bufPrint(&buf, "Domain{}", .{@intCast(u32, self)}) catch {
                    return "Unknown";
                };
                return buf[0..len];
            },
        };
    }
};

/// NewDCESecurity returns a DCE Security (Version 2) UUID.
///
/// The domain should be one of Person, Group or Org.
/// On a POSIX system the id should be the users UID for the Person
/// domain and the users GID for the Group.  The meaning of id for
/// the domain Org or on non-POSIX systems is site defined.
///
/// For a given domain/id pair the same token may be returned for up to
/// 7 minutes and 10 seconds.
pub fn NewDCESecurity(domain: Domain, id: u32) !UUID {
    var uuid = try UUID.NewUUID();

    uuid[6] = (uuid[6] & 0x0f) | 0x20; // Version 2
    uuid[9] = @as(u8, domain);
    std.mem.writeInt(u32, uuid[0..4], id, .big);

    return uuid;
}

/// NewDCEPerson returns a DCE Security (Version 2) UUID in the person
/// domain with the id returned by os.Getuid.
///
///  NewDCESecurity(Person, uint32(os.Getuid()))
pub fn NewDCEPerson() !UUID {
	return NewDCESecurity(Domain(0), u32(std.os.linux.getuid()));
}

/// NewDCEGroup returns a DCE Security (Version 2) UUID in the group
/// domain with the id returned by os.Getgid.
///
///  NewDCESecurity(Group, uint32(os.Getgid()))
pub fn NewDCEGroup() !UUID {
	return NewDCESecurity(Domain(1), u32(std.os.linux.getuid()));
}


