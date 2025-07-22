const std = @import("std");

test "using void as a value type in a HashMap" {
    var map = std.AutoHashMap(i32, void).init(std.testing.allocator);
    defer map.deinit();

    // Insert keys without any associated data
    try map.put(42, {});
    try std.testing.expect(map.contains(42));

    _ = map.remove(42);
    try std.testing.expect(!map.contains(42));
}