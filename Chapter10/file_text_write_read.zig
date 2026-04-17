const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const file = try cwd.createFile(io, "output.txt", .{});
    defer file.close(io);

    // Write with explicit error handling
    try file.writeStreamingAll(io, "Hello from Zig!");

    // Read back
    const data = try cwd.readFileAlloc(io, "output.txt", std.heap.page_allocator, .limited(1024));
    defer std.heap.page_allocator.free(data);

    std.debug.print("File contents: {s}\n", .{data});
}
