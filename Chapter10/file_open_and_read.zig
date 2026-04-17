const std = @import("std");

// Open an existing file for reading and read its entire contents into memory.
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const allocator = std.heap.page_allocator;

    // Create a small file to read so the example is self-contained.
    {
        const tmp = try cwd.createFile(io, "secret_plans.txt", .{});
        defer tmp.close(io);
        try tmp.writeStreamingAll(io, "Top secret: learn Zig.");
    }

    // Read entire contents using readFileAlloc
    const data = try cwd.readFileAlloc(io, "secret_plans.txt", allocator, .limited(1024));
    defer allocator.free(data);

    std.debug.print("File contents: {s}\n", .{data});
}
