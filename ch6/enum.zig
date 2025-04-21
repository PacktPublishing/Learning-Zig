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

pub fn main() void {
    const today = Day.Wednesday;
    if (today == Day.Wednesday) {
        std.debug.print("Guess what? It's hump day!\n", .{});
    }
}
