const std = @import("std");

// Demonstrates ArrayListUnmanaged, insert/remove ops, and sentinel slice conversion.
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Unmanaged: you pass the allocator to each operation and to deinit
    var unmanaged = std.ArrayListUnmanaged(u8){};
    defer unmanaged.deinit(allocator);

    try unmanaged.ensureTotalCapacity(allocator, 3);
    try unmanaged.append(allocator, 10);
    try unmanaged.append(allocator, 20);

    // Insert at index 0 (prepend). O(n)
    try unmanaged.insert(allocator, 0, 99);

    // Demonstrate orderedRemove (keeps order) and swapRemove (fast, may reorder)
    _ = unmanaged.orderedRemove(1); // remove the middle element
    // push one more value to make swapRemove visible
    try unmanaged.append(allocator, 33);
    _ = unmanaged.swapRemove(0); // remove index 0 by swapping with last

    std.debug.print("unmanaged items: {any}\n", .{unmanaged.items});

    // Managed-array equivalent: use Unmanaged for Zig 0.15 compatibility
    var list = std.ArrayListUnmanaged(u8){};
    defer list.deinit(allocator);

    try list.appendSlice(allocator, "hello");

    // Convert to a 0-terminated owned slice, suitable as a C string
    const c_str = try list.toOwnedSliceSentinel(allocator, 0);
    defer allocator.free(c_str);
    std.debug.print("C string: {s}\n", .{c_str});
}
