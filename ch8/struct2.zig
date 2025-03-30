const std = @import("std");
const expect = std.testing.expect;

const Spell = struct {
    name: []const u8,
    mana_cost: u32,
    potency: f32,
};

const Creature = struct {
    health: f32,
    mana: u32,

    pub fn attack(self: *Creature, spell: Spell) bool {
        if (self.mana < spell.mana_cost) {
            // Not enough mana to cast the spell
            	return false;
        }
        self.mana -= spell.mana_cost;
        return true;
    }
};

test "struct methods" {
    var goblin = Creature{ .health = 100.0, .mana = 50 };
    const frost_bolt = Spell{ .name = "Frost Bolt", .mana_cost = 20, .potency = 0.6 };

    try expect(goblin.attack(frost_bolt) == true);
    try expect(goblin.mana == 30);

    // Try again until the goblin can’t cast anymore
	try expect(goblin.attack(frost_bolt) == true);
    try expect(goblin.mana == 10);

    try expect(goblin.attack(frost_bolt) == false);
    // Out of mana now
}
