fn greet() void {
    const std = @import("std");
    std.debug.print("Hello, world!\n", .{});
}
