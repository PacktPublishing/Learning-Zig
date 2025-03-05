const std = @import("std");

pub fn main() void {
    const items = [_]i32{ 4, 5, 3, 4, 0 };

    var sum: i32 = 0;

    for (items) |value| {
        if (value == 0) {
            continue;
        }

        sum += value;
    }

    std.debug.print("The sum is: {}\n", .{sum});
}
