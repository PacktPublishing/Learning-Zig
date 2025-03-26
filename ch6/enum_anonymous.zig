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
    const day: Day = .Saturday;
    if (day == .Saturday) {
        std.debug.print("Enjoy your weekend!\n", .{});
    }
}
