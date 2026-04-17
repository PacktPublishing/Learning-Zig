const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{
        .safety = true,
        .enable_memory_limit = true,
        .retain_metadata = true,
    }) = .init;

    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const memory = try allocator.alloc(u8, 512);

    defer allocator.free(memory);

    std.debug.print("Allocated {} bytes\n", .{memory.len});
}