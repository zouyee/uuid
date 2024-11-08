const std = @import("std");

const UUID = @import("./uuid.zig");
const time = @import("./time.zig");

pub fn NewUUID() !UUID {
    var uuid: UUID = undefined;
    const result = try time.GetTime();
    const now = result[0];
    const seq = result[1];

    const timeLow: u32 = @intCast(u32, now & 0xffffffff);
    const timeMid: u16 = @intCast(u16, (now >> 32) & 0xffff);
    var timeHi: u16 = @intCast(u16, (now >> 48) & 0x0fff);
    timeHi |= 0x1000; // Version 1

    std.mem.writeIntBig(u32, uuid[0..4], timeLow);
    std.mem.writeIntBig(u16, uuid[4..6], timeMid);
    std.mem.writeIntBig(u16, uuid[6..8], timeHi);
    std.mem.writeIntBig(u16, uuid[8..10], seq);

    nodeMu.lock();
    defer nodeMu.unlock();
    if (std.mem.eql(u8, nodeID[0..], zeroID[0..])) {
        setNodeInterface("");
    }
    std.mem.copy(u8, uuid[10..], nodeID[0..]);

    return uuid;
}
