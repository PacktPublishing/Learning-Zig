const std = @import("std");

// 3. Worker Pool with Global Stop Flag (Page 24)
var should_stop = false;
fn worker(io: std.Io, id: usize) void {
    while (!should_stop) {
        std.debug.print("Worker {d} is working...\n", .{id});
        io.sleep(.fromSeconds(1), .awake) catch return;
    }
}

pub fn main(init: std.process.Init) !void {
    const num_workers = 4;
    var threads: [num_workers]std.Thread = undefined;
    for (&threads, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, worker, .{ init.io, i });
    }
    init.io.sleep(.fromSeconds(5), .awake) catch {}; // Let workers run for 5 seconds.
    should_stop = true; // Signal workers to stop.
    for (threads) |t| t.join();
}
