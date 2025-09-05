const std = @import("std");
fn getNumber(code: u8) u8 {
    return switch (code) {
        1 => 42,
        2 => 84,
        else => unreachable,
    };
}

pub fn main() void {
    const num = getNumber(1);
    std.debug.print("num: {}\n", .{num});
}
