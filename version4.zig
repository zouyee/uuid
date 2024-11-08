const std = @import("std");

const UUID = @import("./uuid.zig").UUID;

const UUID = []u8; // Define UUID as needed (16-byte array)
var poolEnabled = false; // Assuming poolEnabled as a global variable
const randPoolSize = 1024; // Define appropriate pool size
var poolPos: usize = randPoolSize;
var pool: [randPoolSize]u8 = undefined;

fn Nil() UUID {
    return [16]u8{0} ** 16; // Assuming Nil as a zeroed UUID
}

fn New() UUID {
    return try Must(NewRandom());
}

fn NewString() []const u8 {
    return try Must(NewRandom()).toString();
}

fn NewRandom() !UUID {
    if (!poolEnabled) {
        return try NewRandomFromReader(std.crypto.random);
    }
    return try newRandomFromPool();
}

fn NewRandomFromReader(r: *std.io.Reader) !UUID {
    var uuid: UUID = undefined;
    try r.readAllSlice(uuid[0..16]);
    uuid[6] = (uuid[6] & 0x0f) | 0x40; // Version 4
    uuid[8] = (uuid[8] & 0x3f) | 0x80; // Variant is 10
    return uuid;
}

fn newRandomFromPool() !UUID {
    var uuid: UUID = undefined;

    if (poolPos == randPoolSize) {
        // Refill pool if needed
        try std.crypto.random.readAllSlice(pool[0..randPoolSize]);
        poolPos = 0;
    }

    // Copy 16 bytes for a new UUID
    std.mem.copy(u8, uuid[0..16], pool[poolPos..poolPos+16]);
    poolPos += 16;

    uuid[6] = (uuid[6] & 0x0f) | 0x40; // Version 4
    uuid[8] = (uuid[8] & 0x3f) | 0x80; // Variant is 10
    return uuid;
}

fn Must(result: !UUID) UUID {
    return switch (result) {
        error => std.debug.panic("UUID creation failed: {}", error),
        else => result,
    };
}
