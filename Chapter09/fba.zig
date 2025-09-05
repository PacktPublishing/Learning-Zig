const std = @import("std");

pub fn main() !void {
    var buffer: [1024]u8 = undefined; // A 1KB fixed-size buffer.
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const allocator = fba.allocator();
    const slice = try allocator.alloc(u8, 512);

    defer allocator.free(slice);

    std.debug.print("Allocated {d} bytes from FixedBufferAllocator\n", .{slice.len});
}