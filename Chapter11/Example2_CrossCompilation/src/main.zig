const std = @import("std");
const builtin = @import("builtin");

pub fn main() void {
    std.debug.print("Successfully compiled for target: {s}-{s}\n", .{
        @tagName(builtin.target.cpu.arch),
        @tagName(builtin.target.os.tag),
    });
}
