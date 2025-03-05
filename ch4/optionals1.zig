const std = @import("std");

pub fn main() void {
    const maybeValue: ?i32 = 10;

    if (maybeValue) |value| {
        std.debug.print("The number is {}\n", .{value});
    } else {
        std.debug.print("No number available.\n", .{});
    }
}
