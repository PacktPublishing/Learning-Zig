const std = @import("std");

pub fn main() void {
    const number = 7;

    if (number > 10) {
        std.debug.print("Number is greater than 10.\n", .{});
    } else if (number > 5) {
        std.debug.print("Number is between 6 and 10.\n", .{});
    } else {
        std.debug.print("Number is 5 or less.\n", .{});
    }
}
