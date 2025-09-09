const std = @import("std");

pub fn main() void {
    var x: u8 = 255;
    std.debug.print("Initial value: {}\n", .{x});

    // This will cause an overflow.
    x += 1;

    // This line may or may not be reached depending on the release mode.
    std.debug.print("Value after overflow: {}\n", .{x});
}
