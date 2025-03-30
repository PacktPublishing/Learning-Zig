const std = @import("std");
const expect = std.testing.expect;

test "packed struct example" {
    // Imagine a packed struct that stores
	// two small integers in a single byte:
	const TinyData = packed struct {
        high: u4,
        low: u4,
    };

    const data = TinyData{ .high = 0xA, .low = 0x5 };
    // Bit layout is now predictable and stable:
	try expect(data.high == 0xA);
    try expect(data.low == 0x5);
    try expect(@sizeOf(TinyData) == 1);
}
