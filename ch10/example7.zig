const std = @import("std");

pub fn main() !void {
    const data = "Zig,C,Rust,Go";
    var iter = std.mem.splitSequence(u8, data, ",");

    while (iter.next()) |lang| {
        std.debug.print("Language: {s}\n", .{lang});
    }
}
