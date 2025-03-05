const std = @import("std");

pub fn main() void {
    var count: usize = 0;

    outer: for (1..6) |_| {
        for (1..6) |_| {
            count += 1;

            break :outer;
        }
    }

    std.debug.print("Count after breaking out: {}\n", .{count});
}
