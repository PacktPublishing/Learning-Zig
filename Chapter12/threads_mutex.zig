const std = @import("std");

const Data = struct {
    mutex: std.Thread.Mutex = .{},
    counter: u32 = 0,
};

fn incrementCounter(data: *Data) void {
    data.mutex.lock();
    defer data.mutex.unlock();
    data.counter += 1;
}

pub fn main() !void {
    var data: Data = .{};
    var threads: [2]std.Thread = undefined;

    threads[0] = try std.Thread.spawn(.{}, incrementCounter, .{&data});
    threads[1] = try std.Thread.spawn(.{}, incrementCounter, .{&data});

    threads[0].join();
    threads[1].join();

    std.debug.print("Counter: {d} (Pray it's 2)\n", .{data.counter});
}
