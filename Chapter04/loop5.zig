const std = @import("std");

pub fn main() void {
    const items = [_]i32{ 1, 3, 4, 5 };

    var sum: i32 = 0;
    var stoppedAtIndex: usize = 0;
    const stoppedEarly = for (0.., items) |i, value| {
        if (@mod(value, 2) == 0) {
            stoppedAtIndex = i;
            break true;
        }
        sum += value;
    } else false;

    std.debug.print("Sum of items: {}\n", .{sum});

    if (stoppedEarly) {
        std.debug.print("Stopped at index: {}\n", .{stoppedAtIndex});
    }
}
