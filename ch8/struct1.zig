const std = @import("std");
const expect = std.testing.expect;

test "defining and using a simple struct" {
	const Spell = struct {
    	name: []const u8,
    	mana_cost: u32,
    	potency: f32,
	};

	// Initializing a struct literal—just fill in all the fields:
	const fireball = Spell{
    	.name = "Fireball",
    	.mana_cost = 25,
    	.potency = 0.75,
	};

	try expect(std.mem.eql(u8, fireball.name, "Fireball"));
	try expect(fireball.mana_cost == 25);
	try expect(fireball.potency == 0.75);
}
