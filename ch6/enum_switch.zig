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
    const day = Day.Friday;
    const message = switch (day) {
        Day.Monday => "Ugh, back to work.",
        Day.Friday => "TGIF!",
        Day.Saturday, Day.Sunday => "Weekend vibes.",
        else => "Just another day.",
    };
    std.debug.print("{s}\n", .{message});
}
