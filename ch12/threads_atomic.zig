const std = @import("std");

const Data = struct {
    counter: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
};

fn incrementCounter(data: *Data) void {
    _ = data.counter.fetchAdd(1, .seq_cst);
}

pub fn main() !void {
    var data: Data = .{};
    var threads: [2]std.Thread = undefined;

    threads[0] = try std.Thread.spawn(.{}, incrementCounter, .{&data});
    threads[1] = try std.Thread.spawn(.{}, incrementCounter, .{&data});

    threads[0].join();
    threads[1].join();

    std.debug.print("Counter: {d} (Pray it's 2)\n", .{data.counter.load(.seq_cst)});
}
