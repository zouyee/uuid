const std = @import("std");
const binary = std.mem.Endian.Big;

const UUID = @import("./uuid.zig").UUID;
const time = @import("./time.zig");
const nodeMu = @import("./node.zig").nodeMu;

/// UUID version 6 is a field-compatible version of UUIDv1, reordered for improved DB locality.
/// It is expected that UUIDv6 will primarily be used in contexts where there are existing v1 UUIDs.
/// Systems that do not involve legacy UUIDv1 SHOULD consider using UUIDv7 instead.
///
/// see https://datatracker.ietf.org/doc/html/rfc9562#uuidv6
///
/// NewV6 returns a Version 6 UUID based on the current NodeID and clock
/// sequence, and the current time. If the NodeID has not been set by SetNodeID
/// or SetNodeInterface then it will be set automatically. If the NodeID cannot
/// be set NewV6 set NodeID is random bits automatically . If clock sequence has not been set by
/// SetClockSequence then it will be set automatically. If GetTime fails to
/// return the current NewV6 returns Nil and an error.
fn NewV6() !UUID {
    var uuid: UUID = undefined;
    const result = try time.getCurrentTime();
    const now = result.now;
    const seq = result.seq;

    // Split the time into Version 6 UUID fields
    const timeHigh: u32 = @intCast(u32, (now >> 28) & 0xffffffff);
    const timeMid: u16 = @intCast(u16, (now >> 12) & 0xffff);
    const timeLowAndVersion: u16 = (@intCast(u16, now & 0x0fff) | 0x6000); // Version 6

    //
	//    0                   1                   2                   3
	//    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
	//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	//   |                           time_high                           |
	//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	//   |           time_mid            |      time_low_and_version     |
	//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	//   |clk_seq_hi_res |  clk_seq_low  |         node (0-1)            |
	//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	//   |                         node (2-5)                            |
	//   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	//
    binary.putU32(uuid[0..4], timeHigh);
    binary.putU16(uuid[4..6], timeMid);
    binary.putU16(uuid[6..8], timeLowAndVersion);
    binary.putU16(uuid[8..10], seq);

    nodeMu.lock();
    defer nodeMu.unlock();

    // Set node ID if it's uninitialized
    if (std.mem.eql(u8, nodeID[0..6], zeroID[0..6])) {
        try setNodeInterface("");
    }
    std.mem.copy(u8, uuid[10..16], nodeID[0..6]);

    return uuid;
}
