const std = @import("std");

pub fn main() !void {
    // Fast pseudo-random (games/simulations)
    var prng = std.rand.DefaultPrng.init(42);
    const game_rng = prng.random();
    const damage = game_rng.intRangeAtMost(u8, 1, 100);

    // Cryptographically secure (passwords/keys)
    var buffer: [32]u8 = undefined;
    std.crypto.random.bytes(&buffer);

    std.debug.print("Damage: {d}\nSecure: {any}\n", .{ damage, buffer });
}
