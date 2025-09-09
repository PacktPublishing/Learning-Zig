const std = @import("std");

const Day = enum { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday };

pub fn main() void {
    const day = Day.Tuesday;
    const dayName = @tagName(day);
    std.debug.print("Today is {s}.\n", .{dayName});
}