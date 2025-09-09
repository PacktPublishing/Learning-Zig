const std = @import("std");
// Import the options module created in build.zig
const config = @import("config");

pub fn main() void {
    if (config.is_dark_mode_enabled) {
        std.debug.print("UI is running in Dark Mode!\n", .{});
    } else {
        std.debug.print("UI is running in Light Mode.\n", .{});
    }
}
