const std = @import("std");

pub fn main() void {
    const a: u32 = 5;

    const b: u32 = 4;

    const result = if (a != b) 47 else 3089;

    std.debug.print("Result is: {}\n", .{result});
}
