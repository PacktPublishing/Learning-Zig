const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("time.h");
});

pub fn main() void {
    _ = c.printf("Zig says: Hello from C's %s!\n", "printf");

    var tm: c.tm = undefined;
    const timestamp = c.time(null);
    _ = c.localtime_r(&timestamp, &tm);

    std.debug.print("\nToday's date (according to C): {d}-{d}-{d}\n", .{
        tm.tm_year + 1900,
        tm.tm_mon + 1,
        tm.tm_mday,
    });
}
