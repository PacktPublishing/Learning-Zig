const std = @import("std");
pub fn main() void {
    defer std.debug.print("First defer\n", .{});
    defer std.debug.print("Second defer\n", .{});
    std.debug.print("In main function\n", .{});
}
