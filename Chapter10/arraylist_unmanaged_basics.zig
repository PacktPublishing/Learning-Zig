const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // ArrayList is unmanaged: pass the allocator to each call that allocates
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator); // Mandatory cleanup

    // Append with error handling
    try list.append(allocator, 42);
    try list.append(allocator, 99);

    // Pre-allocate memory
    try list.ensureTotalCapacity(allocator, 100);

    std.debug.print("List: {any}\n", .{list.items});
}
