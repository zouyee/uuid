const std = @import("std");
const time = std.time;
const nanoPerMilli = 1_000_000;

// Define UUID as needed for your application
const UUID = []u8; // Adjust UUID type to fit the expected size

// Locks for thread safety
const timeMu = std.sync.Mutex.init();
var lastV7time: i64 = 0;

fn NewV7() !UUID {
    var uuid = try NewRandom();
    makeV7(uuid[0..]);
    return uuid;
}

fn NewV7FromReader(r: anytype) !UUID {
    var uuid = try NewRandomFromReader(r);
    makeV7(uuid[0..]);
    return uuid;
}

fn makeV7(uuid: []u8) void {
    const result = getV7Time();
    const milli = result.milli;
    const seq = result.seq;

    uuid[0] = @intCast((milli >> 40) & 0xff);
    uuid[1] = @intCast( (milli >> 32) & 0xff);
    uuid[2] = @intCast( (milli >> 24) & 0xff);
    uuid[3] = @intCast( (milli >> 16) & 0xff);
    uuid[4] = @intCast( (milli >> 8) & 0xff);
    uuid[5] = @intCast( milli & 0xff);

    uuid[6] = 0x70 | (@intCast((seq >> 8) & 0x0F));
    uuid[7] = @intCast(u8, seq & 0xff);
}

fn getV7Time() struct { milli: i64, seq: i64 } {
    timeMu.lock();
    defer timeMu.unlock();

    const nano = time.milliTimestamp() * nanoPerMilli;
    var milli = nano / nanoPerMilli;
    var seq = (nano - milli * nanoPerMilli) >> 8;
    var now = (milli << 12) + seq;

    if (now <= lastV7time) {
        now = lastV7time + 1;
        milli = now >> 12;
        seq = now & 0xfff;
    }
    lastV7time = now;
    return .{ .milli = milli, .seq = seq };
}

// Placeholder for NewRandom function
fn NewRandom() !UUID {
    // Implement UUIDv4 generation here or call an external function if available
    return UUID{};
}

// Placeholder for NewRandomFromReader function
fn NewRandomFromReader(r: anytype) !UUID {
    // Implement UUIDv4 generation from a reader here
    return UUID{};
}
