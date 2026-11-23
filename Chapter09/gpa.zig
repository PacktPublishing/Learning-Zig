const std = @import("std");

pub fn main() !void {
    // SafeAllocator detects leaks, double frees, and writes after free.
    // It wraps a backing allocator that supplies the pages.
    var gpa: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{
        .stack_trace_frames = 8, // frames recorded per allocation for leak reports
        .check_write_after_free = true,
    });

    // deinit returns the number of leaked allocations
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const memory = try allocator.alloc(u8, 512);

    defer allocator.free(memory);

    std.debug.print("Allocated {} bytes\n", .{memory.len});
}
