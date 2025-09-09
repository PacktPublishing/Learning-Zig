const std = @import("std");

const Result = union(enum) {
    Success: i32,
    Error: []const u8,
};

fn calculate(input: i32) Result {
    if (input >= 0) {
        return .{ .Success = input * 2 };
    } else {
        return .{ .Error = "Input must be nonnegative" };
    }
}

pub fn main() void {
    const res = calculate(-5);
    switch (res) {
        .Success => |value| std.debug.print("Calculation result: {d}\n", .{value}),
        .Error => |errMsg| std.debug.print("Error: {s}\n", .{errMsg}),
    }
}