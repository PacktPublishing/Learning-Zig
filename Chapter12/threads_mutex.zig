const std = @import("std");

const Data = struct {
    // In Zig 0.16, Mutex moved from std.Thread.Mutex to std.Io.Mutex
    mutex: std.Io.Mutex = .init,
    counter: u32 = 0,
};

fn incrementCounter(data: *Data, io: std.Io) void {
    // lock/unlock now require an Io parameter
    data.mutex.lockUncancelable(io);
    defer data.mutex.unlock(io);
    data.counter += 1;
}

pub fn main(init: std.process.Init) !void {
    var data: Data = .{};
    var threads: [2]std.Thread = undefined;

    threads[0] = try std.Thread.spawn(.{}, incrementCounter, .{ &data, init.io });
    threads[1] = try std.Thread.spawn(.{}, incrementCounter, .{ &data, init.io });

    threads[0].join();
    threads[1].join();

    std.debug.print("Counter: {d} (Pray it's 2)\n", .{data.counter});
}
