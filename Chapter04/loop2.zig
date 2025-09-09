const std = @import("std");

pub fn main() void {
    const items = [_]i32{ 4, 5, 3, 4, 0 };

    var sum: i32 = 0;

    for (items[0..2]) |value| {
        sum += value;
    }

    std.debug.print("Sum of the first two items: {}\n", .{sum});
}
