const std = @import("std");

test "open the loot box (pointer casting)" {
    const loot_bytes = [_]u8 { 0x12, 0x34, 0x56, 0x78 }; // Encoded loot box data

    // Interpret the first 4 bytes as a u32
	const loot_value_ptr: *const u32 = @alignCast(@ptrCast(&loot_bytes[0]));
    try std.testing.expect(loot_value_ptr.* == 0x78563412); // Endianness dependent
}

test "bitCast for decoding item ID" {
    const item_id: u32 = 0x12345678; // Encoded item ID as a single u32

    // Reinterpret the bits of the u32 as an array of 4 u8 values
	const item_id_bytes: [4]u8 = @bitCast(item_id);

    // Validate the byte order
	try std.testing.expect(item_id_bytes[0] == 0x78); // Least significant byte
	try std.testing.expect(item_id_bytes[1] == 0x56);
    try std.testing.expect(item_id_bytes[2] == 0x34);
    try std.testing.expect(item_id_bytes[3] == 0x12); // Most significant byte
}
