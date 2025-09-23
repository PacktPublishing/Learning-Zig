const std = @import("std");

// Open an existing file for reading and read its entire contents into memory.
pub fn main() !void {
    const cwd = std.fs.cwd();
    const allocator = std.heap.page_allocator;

    // Create a small file to read so the example is self-contained.
    {
        const tmp = try cwd.createFile("secret_plans.txt", .{});
        defer tmp.close();
        try tmp.writeAll("Top secret: learn Zig.");
    }

    // Open the file for reading (default .{} is read-only on Zig 0.15)
    const file = try cwd.openFile("secret_plans.txt", .{});
    defer file.close();

    // Read entire contents with an upper bound
    const data = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(data);

    std.debug.print("File contents: {s}\n", .{data});
}
