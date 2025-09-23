const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var map = std.AutoHashMap(u32, u32).init(allocator);
    defer map.deinit();

    // Insert key-value pairs
    try map.put(42, 9001);
    try map.put(7, 1337);

    // Retrieve values
    if (map.get(42)) |val| {
        std.debug.print("Value: {d}\n", .{val});
    }

    // Remove installs a tombstone (affects performance)
    _ = map.remove(7);

    // Rehash cleans up tombstones and compacts the map
    map.rehash();
}
