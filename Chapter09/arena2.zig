const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    for ([_]usize{ 256, 512, 1024 }) |alloc_size| {
        const memory = try allocator.alloc(u8, alloc_size);
        std.debug.print("Allocated {} bytes\n", .{memory.len});
        // Reset the arena and reuse memory
        _ = arena.reset(.retain_capacity);
    }
}