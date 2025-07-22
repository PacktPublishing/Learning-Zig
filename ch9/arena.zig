const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // Frees all memory in one go

    const allocator = arena.allocator();

    // Allocate memory
    const memory1 = try allocator.alloc(u8, 100);
    const memory2 = try allocator.alloc(u8, 200);

    std.debug.print("Allocated {} and {} bytes\n", .{ memory1.len, memory2.len });

    // No need to free individually; `defer arena.deinit()` will take care of everything
}