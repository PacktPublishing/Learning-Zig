const std = @import("std");

fn square(x: i32) i32 {
    return x * x;
}

test "square function should return the square of a number" {
    try std.testing.expect(square(3) == 9);
    try std.testing.expect(square(-4) == 16);
    try std.testing.expect(square(0) == 0);
}

/// Returns the square of the given number.
///
/// ```zig
/// const squared = safeSquare(3);
/// // squared == "9"
/// ```
fn safeSquare(x: i32) !i32 {
    const ov = @mulWithOverflow(x, x);
    if (ov[1] != 0) return error.OverFlow;
    return ov[0];
}

test "safeSquare should return an error on overflow" {
    try std.testing.expectError(error.OverFlow, safeSquare(46341));
}
