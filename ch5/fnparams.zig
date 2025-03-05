const std = @import("std");
const MathOp = fn (a: i32, b: i32) i32;

fn applyOperation(op: MathOp, a: i32, b: i32) i32 {
    return op(a, b);
}

fn subtract(a: i32, b: i32) i32 {
    return a - b;
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn main() void {
    const sum = applyOperation(add, 5, 3);   	// sum is 8
    const difference = applyOperation(subtract, 5, 3); // difference is 2
    std.debug.print("sum: {}, difference: {}\n", .{sum, difference});
}
