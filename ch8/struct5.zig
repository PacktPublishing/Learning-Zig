const std = @import("std");
const expect = std.testing.expect;

test "default field values" {
    const Potion = struct {
        strength: u16 = 10,
        flavor_rating: u8,
    };

    // Only specify flavor_rating, strength defaults to 10.
    const brew = Potion{ .flavor_rating = 8 };
    try expect(brew.strength == 10);
    try expect(brew.flavor_rating == 8);
}
