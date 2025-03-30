const std = @import("std");
const expect = std.testing.expect;

test "managing player health using pointers" {
    // 1) Address of a constant variable (initial health of a non-playable character)
	const npc_health: i32 = 100;
    const npc_health_ptr = &npc_health; // Take the address
	try expect(npc_health_ptr.* == 100); // Confirm the value via the pointer
	try expect(@TypeOf(npc_health_ptr) == *const i32); // Confirm pointer type: immutable

    // 2) Address of a mutable variable (health of a player)
	var player_health: i32 = 150;
    const player_health_ptr = &player_health; // Take the address
	try expect(@TypeOf(player_health_ptr) == *i32); // Confirm pointer type: mutable

    // Simulate player taking damage
	player_health_ptr.* -= 20; // Reduce health through the pointer
	try expect(player_health_ptr.* == 130); // Verify the updated health
}
