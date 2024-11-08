const std = @import("std");

const Time = i64;

const lillian = 2299160;           // Julian day of 15 Oct 1582
const unix = 2440587;              // Julian day of 1 Jan 1970
const epoch = unix - lillian;      // Days between epochs
const g1582 = epoch * 86400;       // seconds between epochs
const g1582ns100 = g1582 * 10000000; // 100s of nanoseconds between epochs

// Globals
var clockSeq: u16 = 0; // Clock sequence for this run
var lastTime: u64 = 0; // Last time we returned in 100ns since 1582
var timeMutex = std.sync.Mutex(std.heap.page_allocator);

// Function to get the current Unix time in seconds and nanoseconds
pub fn toUnixTime(t: Time) i64, i64 {
    var sec = t - g1582ns100;
    const nsec = (sec % 10000000) * 100;
    sec /= 10000000;
    return struct{sec, nsec};
}

// Function to get the current time in 100ns since 15 Oct 1582 and the clock sequence
pub fn getCurrentTime() !struct{@TypeOf(Time), u16} {
    try timeMutex.lock();
    defer timeMutex.unlock();
    return try getTime();
}

fn getTime() !struct{@TypeOf(Time), u16} {
    const now = std.time.milliTimestamp() * 10; // Convert milliseconds to 100ns

    if (clockSeq == 0) {
        setClockSequence(-1);
    }

    var current = now + g1582ns100;

    // If time has gone backwards, increment the clock sequence
    if (current <= lastTime) {
        clockSeq = ((clockSeq + 1) & 0x3FFF) | 0x8000;
    }

    lastTime = current;
    return struct{Time(current), clockSeq};
}

// Get the current clock sequence, generating one if not already set
pub fn getClockSequence() !u16 {
    try timeMutex.lock();
    defer timeMutex.unlock();
    return clockSequence();
}

fn clockSequence() u16 {
    if (clockSeq == 0) {
        setClockSequence(-1);
    }
    return clockSeq & 0x3FFF;
}

// Set the clock sequence to the lower 14 bits of seq; -1 generates a new sequence
pub fn setClockSequence(seq: i32) void {
    timeMutex.lock();
    defer timeMutex.unlock();
    setClockSequenceInternal(seq);
}

fn setClockSequenceInternal(seq: i32) void {
    if (seq == -1) {
        const randomSequence = std.rand.DefaultPrng.init(std.time.nsTimestamp());
        const newSeq = randomSequence.int(u16);
        clockSeq = newSeq & 0x3FFF | 0x8000; // Set variant bits
    } else {
        clockSeq = @intCast(u16, seq & 0x3FFF) | 0x8000;
    }
    lastTime = 0;
}
