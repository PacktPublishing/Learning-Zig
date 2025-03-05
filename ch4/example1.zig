const std = @import("std");

pub fn main() void {
    const number = 10;

    if (number > 5) {
        std.debug.print("Number is greater than 5.\n", .{});
    } else {
        std.debug.print("Number is 5 or less.\n", .{});
    }
}
