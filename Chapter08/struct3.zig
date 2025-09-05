const std = @import("std");
const expect = std.testing.expect;

test "struct constants and empty structs" {
    const Alchemy = struct {
        pub const BASE_MULTIPLIER = 2.5;
    };

    const EmptySpace = struct {
        pub const PI = 3.14159;
        // No fields at all. Perfectly legal. No runtime cost.
	};

    try expect(@sizeOf(EmptySpace) == 0);
    try expect(EmptySpace.PI == 3.14159);

    // You can instantiate an empty struct if you like,
	// but it’s basically doing nothing.
	const nothing = EmptySpace{};
    _ = nothing;

    // Use the constants as needed:
	const result = 10.0 * Alchemy.BASE_MULTIPLIER;
    try expect(result == 25.0);
}



