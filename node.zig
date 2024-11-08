const std = @import("std");

const UUID = @import("./uuid.zig").UUID;
const util = @import("./util.zig");

pub var nodeMu = std.sync.Mutex{};
var ifname: ?[]const u8 = null;
var nodeID: [6]u8 = [_]u8{0} ** 6;
const zeroID: [6]u8 = [_]u8{0} ** 6;

/// NodeInterface returns the name of the interface from which the NodeID was
/// derived.  The interface "user" is returned if the NodeID was set by
/// SetNodeID.
pub fn NodeInterface() []const u8 {
    var lock = nodeMu.lock();
    defer lock.unlock();
    return ifname orelse "unknown";
}

/// SetNodeInterface selects the hardware address to be used for Version 1 UUIDs.
/// If name is "" then the first usable interface found will be used or a random
/// Node ID will be generated.  If a named interface cannot be found then false
/// is returned.
///
/// SetNodeInterface never fails when name is "".
pub fn SetNodeInterface(name: []const u8) bool {
    var lock = nodeMu.lock();
    defer lock.unlock();
    return setNodeInterface(name);
}

fn setNodeInterface(name: []const u8) bool {
    var iname: ?[]const u8 = null;
    var addr: ?[]u8 = null;

    const hw_interface = getHardwareInterface(name); // 获取硬件接口（假设有实现）
    if (hw_interface) |i| {
        iname = i.name;
        addr = i.addr;
    }

    if (iname != null and addr != null) {
        ifname = iname;
        std.mem.copy(u8, nodeID[0..6], addr);
        return true;
    }

    if (name.len == 0) {
        ifname = "random";
        util.randomBits(nodeID[0..6]);
        return true;
    }
    return false;
}

/// NodeID returns a slice of a copy of the current Node ID, setting the Node ID
/// if not already set.
pub fn NodeID() []u8 {
    var lock = nodeMu.lock();
    defer lock.unlock();

    if (std.mem.eql(u8, nodeID[0..6], zeroID[0..6])) {
        _ = setNodeInterface("");
    }

    return nodeID[0..6];
}

/// SetNodeID sets the Node ID to be used for Version 1 UUIDs.  The first 6 bytes
/// of id are used.  If id is less than 6 bytes then false is returned and the
/// Node ID is not set.
pub fn SetNodeID(id: []const u8) bool {
    if (id.len < 6) {
        return false;
    }
    var lock = nodeMu.lock();
    defer lock.unlock();
    std.mem.copy(u8, nodeID[0..6], id[0..6]);
    ifname = "user";
    return true;
}

/// NodeID returns the 6 byte node id encoded in uuid.  It returns nil if uuid is
/// not valid.  The NodeID is only well defined for version 1 and 2 UUIDs.
pub fn UUID_NodeID(uuid: UUID) []u8 {
    return uuid[10..16];
}

/// getHardwareInterface returns nil values for the JS version of the code.
/// This removes the "net" dependency, because it is not used in the browser.
/// Using the "net" library inflates the size of the transpiled JS code by 673k bytes.
pub fn getHardwareInterface(_: []const u8) ?struct { name: []const u8, addr: []u8 } {
    if (std.target.os.tag == .wasi) {
        return null;
    }

    // TODO: interface()
    return null;
}