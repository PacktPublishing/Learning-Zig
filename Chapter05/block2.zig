const std = @import("std");

pub fn main() void {
    const result = blk: {
        const a = 10;
        const b = 20;
        break :blk a + b; // The block evaluates to this expression
    };

    std.debug.print("result: {}\n", .{result});
}
