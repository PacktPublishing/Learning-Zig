const std = @import("std");
const expect = std.testing.expect;

const Creature = struct {
    health: f32,
    mana: u32,
};

fn boostMana(mana_ptr: *u32, amount: u32) void {
    // We know mana_ptr is a field of Creature. Let's get the Creature pointer!
	// const Creature = @typeInfo(@TypeOf(mana_ptr.*)).Pointer.parent; // Just a demonstration of concept
	// Actually use Zig's built-in:
	const creature_ptr: *Creature = @fieldParentPtr("mana", mana_ptr);
    creature_ptr.mana += amount;
}

test "field parent pointer" {


    var elf = Creature{ .health = 150.0, .mana = 10 };
    boostMana(&elf.mana, 40);
    try expect(elf.mana == 50);
}
