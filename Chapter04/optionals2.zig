const std = @import("std");

pub fn main() void {
    const items = [_]?i32{ 1, null, 3, null, 5 };
    var sum: i32 = 0;

    for (items) |item| {
        if (item) |value| {
            sum += value;
        } else {
            std.debug.print("Encountered a null value.\n", .{});
        }
    }

    std.debug.print("Sum of non-null values: {}\n", .{sum});
}
