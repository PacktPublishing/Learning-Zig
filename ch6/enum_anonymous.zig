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
    const day: Day = .Saturday;

    // Uncomment to see the different types when type is not explicity.
    // const anotherDay = .Friday;
    // std.debug.print("{}\n", .{@TypeOf(day)});
    // std.debug.print("{}\n", .{@TypeOf(anotherDay)});

    if (day == .Saturday) {
        std.debug.print("Enjoy your weekend!\n", .{});
    }
}
