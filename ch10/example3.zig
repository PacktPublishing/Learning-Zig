const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close(); // Always close files

    // Write with explicit error handling
    try file.writeAll("Hello from Zig!");

    // Read back
    const data = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, "output.txt", 1024);
    defer std.heap.page_allocator.free(data);

    std.debug.print("File contents: {s}\n", .{data});
}
