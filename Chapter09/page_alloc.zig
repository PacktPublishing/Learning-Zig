const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 8192); // Allocate 2 pages on a 4 KB system
    defer allocator.free(memory);

    std.debug.print("Allocated {} bytes\n", .{memory.len});
}