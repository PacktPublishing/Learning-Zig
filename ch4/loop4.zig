const std = @import("std");

pub fn main() void {
    var sum: usize = 0;

    for (0..5) |i| {
        sum += i;
    }

    std.debug.print("Sum of numbers from 0 to 4: {}\n", .{sum});
}
