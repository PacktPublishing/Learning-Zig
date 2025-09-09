const std = @import("std");

fn screamIntoTheVoid(steps: u8) void {
    var i: u8 = 0;
    while (i < steps) : (i += 1) {
        std.debug.print("A", .{});
        // Short sleep to keep example snappy
        std.Thread.sleep(10 * std.time.ns_per_ms);
    }
    std.debug.print("!\n", .{});
}

pub fn main() !void {
    const thread = try std.Thread.spawn(.{}, screamIntoTheVoid, .{@as(u8, 5)});
    std.debug.print("Main thread here, sipping tea...\n", .{});
    thread.join();
}
