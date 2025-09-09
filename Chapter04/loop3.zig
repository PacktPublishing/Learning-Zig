const std = @import("std");

pub fn main() void {
    const items = [_]i32{ 4, 5, 3, 4, 0 };

    var sum: i32 = 0;

    for (items, 0..) |_, index| {
        sum += @intCast(index);
    }

    std.debug.print("Sum of the indices: {}\n", .{sum});
}
