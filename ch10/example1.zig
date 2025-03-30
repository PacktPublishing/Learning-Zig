const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit(); // Mandatory cleanup

    // Append with error handling
    try list.append(42);
    try list.append(99);

    // Pre-allocate memory
    try list.ensureTotalCapacity(100);

    std.debug.print("List: {any}\n", .{list.items});
}
