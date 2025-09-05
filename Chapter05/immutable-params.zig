const std = @import("std");

pub fn main() void {
    const n = 1;
    const result = increment(n);
    std.debug.print("result: {}\n", .{result});
}

fn increment(n: i32) i32 {
    // n += 1; // Error: cannot assign to constant
    const result = n + 1;
    return result;
}
