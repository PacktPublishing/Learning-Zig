const std = @import("std");

// Stored in the global constant section of memory.
const manaPotion: f64 = 1.337;
const battleCry = "For Honor!";

// Stored in the global data section.
var monstersDefeated: usize = 0;

fn calculateDamage() u8 {
    // These local variables are gone once the function exits.
    const swordDamage: u8 = 10;
    const shieldBonus: u8 = 5;
    const totalDamage: u8 = swordDamage + shieldBonus;

    // Returning a copy of `totalDamage`, safe and sound.
    return totalDamage;
}

fn cursedSword() *u8 {
    var attackPower: u8 = 42;
    // Attack power lives on the stack and will disappear after the function.
    return &attackPower;
}

fn cursedScroll() []u8 {
    var spell: [5]u8 = .{ 'F', 'i', 'r', 'e', '!' };
    const incantation = spell[1..]; // Slice into the array.

    // The array vanishes after the function, leaving `incantation` dangling.
    return incantation;
}

fn enchantedSword(allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
    var swordStats: [5]u8 = .{ 'S', 'l', 'a', 's', 'h' };

    const statsCopy = try allocator.alloc(u8, swordStats.len);
    @memcpy(statsCopy, &swordStats);

    return statsCopy;
}