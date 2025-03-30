const std = @import("std");
const expect = std.testing.expect;

test "upgrading player inventory slots using pointers" {
    // Define the player's inventory slots (capacity for items)
	var inventory_slots = [_]u8 { 1, 2, 3, 4, 5 }; // Slots have initial levels 1 to 5

    // Take a pointer to the 3rd inventory slot (level 3 slot)
	const slot_ptr = &inventory_slots[2];

    // Confirm the pointer type
	try expect(@TypeOf(slot_ptr) == *u8); // Pointer to a mutable u8

    // Check the initial level of the 3rd slot
	try expect(slot_ptr.* == 3);

    // Upgrade the 3rd slot by increasing its level
	slot_ptr.* += 1;

    // Confirm the slot has been upgraded
	try expect(inventory_slots[2] == 4); // 3rd slot is now at level 4
}
