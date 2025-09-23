const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Use Unmanaged for compatibility across Zig versions
    var list = std.ArrayListUnmanaged(u8){};
    defer list.deinit(allocator); // Mandatory cleanup

    // Append with error handling
    try list.append(allocator, 42);
    try list.append(allocator, 99);

    // Pre-allocate memory
    try list.ensureTotalCapacity(allocator, 100);

    std.debug.print("List: {any}\n", .{list.items});
}
