const std = @import("std");

pub fn main() !void {
    try doSomethingThatMightFail();
    std.debug.print("Success!\n", .{});
}

fn doSomethingThatMightFail() !void {
    // Imagine this is some resource acquisition
    std.debug.print("Resource acquired\n", .{});

    // This will run only if an error occurs after this point
    errdefer std.debug.print("Cleaning up resource\n", .{});

    // Simulate a potential error using a PRNG
    var prng = std.Random.DefaultPrng.init(0xdeadbeef);
    if (prng.random().boolean()) {
        return error.Oops;
    }

    std.debug.print("Operation completed\n", .{});
}
