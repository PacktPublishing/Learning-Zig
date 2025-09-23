const std = @import("std");

// 3. Worker Pool with Global Stop Flag (Page 24)
var should_stop = false;
fn worker(id: usize) void {
    while (!should_stop) {
        std.debug.print("Worker {d} is working...\n", .{id});
        std.Thread.sleep(1 * std.time.ns_per_s);
    }
}

pub fn main() !void {
    const num_workers = 4;
    var threads: [num_workers]std.Thread = undefined;
    for (&threads, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, worker, .{i});
    }
    std.Thread.sleep(5 * std.time.ns_per_s); // Let workers run for 5 seconds.
    should_stop = true; // Signal workers to stop.
    for (threads) |t| t.join();
}