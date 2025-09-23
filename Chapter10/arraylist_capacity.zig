const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var list = std.ArrayListUnmanaged(u8){};
    defer list.deinit(allocator);

    // Reserve exactly some capacity up front (precise)
    try list.ensureTotalCapacityPrecise(allocator, 4);

    // When you KNOW you have capacity, you can skip runtime checks
    list.appendAssumeCapacity(1);
    list.appendAssumeCapacity(2);

    // You can still use the safe version
    try list.append(allocator, 3);

    std.debug.print("items before shrink: {any} cap={d}\n", .{ list.items, list.capacity });

    // Shrink backing buffer to exactly fit, and free unused memory
    list.shrinkAndFree(allocator, list.items.len);
    std.debug.print("after shrink cap={d} len={d}\n", .{ list.capacity, list.items.len });
}
