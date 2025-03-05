const std = @import("std");
pub fn main() void {
    {
        const value = 42;
        std.debug.print("value: {}\n", .{value});
    }
    {
        const value: bool = true;
        std.debug.print("value: {}\n", .{value});
    }
}
