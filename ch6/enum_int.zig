const std = @import("std");

const Day = enum {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
};

pub fn main() !void {
    const today = Day.Wednesday;
    const dayNumber = @intFromEnum(today);
    std.debug.print("It's day number {d} of the week.\n", .{dayNumber});
}
