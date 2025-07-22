const std = @import("std");



pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Allocate and use memory
    _ = try allocator.alloc(u8, 1024);

    // Reset, retaining only 512 bytes of capacity
    if (!arena.reset(.{ .retain_with_limit = 512 })) {
        std.debug.print("Failed to reset with limit\n", .{});
    }
}