const std = @import("std");

pub fn main() void {
    const nums = [_]i32{ 2, 4, 6 };

    var sum: usize = 0;

    inline for (nums) |i| {
        const T = switch (i) {
            2 => f32,

            4 => i8,

            6 => bool,

            else => unreachable,
        };

        sum += @typeName(T).len;
    }

    std.debug.print("Total length of type names: {}\n", .{sum});
}
