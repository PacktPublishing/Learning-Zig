const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // Fast pseudo-random (games/simulations)
    var prng = std.Random.DefaultPrng.init(42);
    const game_rng = prng.random();
    const damage = game_rng.intRangeAtMost(u8, 1, 100);

    // Cryptographically secure (passwords/keys)
    // In Zig 0.16, secure random requires an Io instance
    var buffer: [32]u8 = undefined;
    init.io.random(&buffer);

    std.debug.print("Damage: {d}\nSecure: {any}\n", .{ damage, buffer });
}
