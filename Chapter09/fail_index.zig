const std = @import("std");

test "failing allocator - index" {
    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 2 });

    var allocator = failing_allocator.allocator();

    // Two successful allocations. Hooray!
    const a = try allocator.create(i32);
    defer allocator.destroy(a);
    const b = try allocator.create(i32);
    defer allocator.destroy(b);

    // Oh no! Allocation number three trips over the fail_index.
    try std.testing.expectError(error.OutOfMemory, allocator.create(i32));
    
}