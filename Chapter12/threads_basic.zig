const std = @import("std");

fn screamIntoTheVoid(io: std.Io, steps: u8) void {
    var i: u8 = 0;
    while (i < steps) : (i += 1) {
        std.debug.print("A", .{});
        // In Zig 0.16, sleep requires an Io instance
        io.sleep(.fromMilliseconds(10), .awake) catch return;
    }
    std.debug.print("!\n", .{});
}

pub fn main(init: std.process.Init) !void {
    const thread = try std.Thread.spawn(.{}, screamIntoTheVoid, .{ init.io, @as(u8, 5) });
    std.debug.print("Main thread here, sipping tea...\n", .{});
    thread.join();
}
