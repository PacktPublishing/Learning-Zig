const std = @import("std");

pub fn main() void {
    const a: u32 = 5;

    const b: u32 = 4;

    if (a != b) {
        std.debug.print("a is not equal to b.\n", .{});
    } else if (a == 9) {
        std.debug.print("a is inexplicably 9.\n", .{});
    } else {
        std.debug.print("None of the above conditions were met.\n", .{});
    }
}
