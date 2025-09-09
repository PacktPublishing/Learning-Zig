const std = @import("std");

const Number = union {
    intValue: i32,
    floatValue: f64,
};

pub fn main() void {
    const num: Number = .{ .intValue = 256 };
    std.debug.print("Integer number: {d}\n", .{num.intValue});

    const numFloat: Number = .{ .floatValue = 1.618 };
    std.debug.print("Floating-point number: {}\n", .{numFloat.floatValue});
}