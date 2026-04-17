const std = @import("std");

// Demonstrates buffered line-by-line reading.
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    // Prepare a file with multiple lines
    {
        const f = try cwd.createFile(io, "log.txt", .{});
        defer f.close(io);
        try f.writeStreamingAll(io, "line1\nline2\nline3\n");
    }

    const file = try cwd.openFile(io, "log.txt", .{});
    defer file.close(io);

    var buf: [4096]u8 = undefined;
    var reader = file.reader(io, &buf);

    while (try reader.interface.takeDelimiter('\n')) |line| {
        std.debug.print("Line: {s}\n", .{line});
    }
}
