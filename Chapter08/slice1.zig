const std = @import("std");

test "arrays and basic slicing" {
    // We have 6 mystical stones with fixed, known-at-compile-time powers.
    const stone_powers = [_]u16{ 42, 17, 93, 58, 11, 99 };

    // The array’s length is part of its type. Stone powers are fixed in stone (pun intended).
    const total_stones = stone_powers.len;
    try std.testing.expect(total_stones == 6);

    // Accessing by index: arrays do no runtime safety checks (by default),
    // but if you're testing in safe mode, Zig will still panic on out-of-bounds.
    try std.testing.expect(stone_powers[0] == 42);
    try std.testing.expect(stone_powers[5] == 99);
}

test "creating slices from arrays" {
    var stone_powers = [_]u16{ 42, 17, 93, 58, 11, 99 };

    // Let’s say a player enters a dungeon and only gets to see the middle half of the stones.
	// At runtime, we decide “middle half” means indices 2 through 3 (just two elements).
	const start_index: usize = 2;
    const end_index: usize = 4; // slicing is end-exclusive, so this grabs indices [2,3]

    // Because start_index and end_index are runtime-known, this produces a slice:
	const middle_stones = stone_powers[start_index..end_index];

    // Check the type:
	try std.testing.expect(@TypeOf(middle_stones) == *[2]u16);
    // Check the content:
	try std.testing.expect(middle_stones.len == 2);
    try std.testing.expect(middle_stones[0] == 93); // stone_powers[2]
	try std.testing.expect(middle_stones[1] == 58); // stone_powers[3]

    // If we used compile-time known indices, say stone_powers[2..4] directly,
	// and 2,4 were known at compile-time, we'd get a pointer-to-array instead of a slice.
	// Slices always come in when runtime enters the picture.
}

test "creating slices from arrays 2" {
    var stone_powers = [_]u16{ 42, 17, 93, 58, 11, 99 };

    // Let’s say a player enters a dungeon and only gets to see the middle half of the stones.
	// At runtime, we decide “middle half” means indices 2 through 3 (just two elements).
	var known_at_runtime_zero: usize = 0;
    _ = &known_at_runtime_zero;

    // Because start_index and end_index are runtime-known, this produces a slice:
	const middle_stones = stone_powers[known_at_runtime_zero..stone_powers.len];

    // Check the type:
	try std.testing.expect(@TypeOf(middle_stones) == []u16);
    // Check the content:
	try std.testing.expect(middle_stones.len == 6);
    try std.testing.expect(middle_stones[0] == 42);
	try std.testing.expect(middle_stones[1] == 17);
}

test "slices protect you from yourself" {
    var stone_powers = [_]u16{ 42, 17, 93, 58, 11, 99 };

    // Let's try to be naughty and access out-of-bounds on a slice.
	// We’ll create a small slice: indices [1..3].
	const subset = stone_powers[1..3];
    try std.testing.expect(subset.len == 2);

    // Attempting to do `subset[99] = 100;` will result in a runtime panic.
	// Unlike arrays (which rely on compile-time checks), slices will check at runtime.
	// Let's deliberately cause chaos (commented out to avoid panic here):
	// subset[99] = 100; // panic city, population: you.

    // Just knowing that slices protect you is enough. Embrace the safety.
}

test "slices enabling runtime filtering" {
    var stone_powers = [_]u16{ 42, 17, 93, 58, 11, 99 };

    // Count how many stones have power > 50 at runtime:
	var count_greater_than_50: usize = 0;
    for (stone_powers) |power| {
        if (power > 50) count_greater_than_50 += 1;
    }
    try std.testing.expect(count_greater_than_50 == 3); // Stones 93, 58, 99

    // Now we can create a slice that captures just these powerful stones.
	// We know we have 3 qualifying stones, let's say we decide these must be the last three stones
	// that matched the criterion. (In a real scenario, maybe you'd copy them into a separate array first.
	// For demonstration, we'll pretend we know which indices they ended up at.)
	// Suppose we know at runtime that the “good stones” start at index 2 and end at 5 exclusive:
	const start_index: usize = 2;
    var length: usize = 3; // we know at runtime we found 3 good stones (93, 58, 11)
     _ = &length; // runtime-known index
	const good_stones = stone_powers[start_index..][0..length];

    // Check that we got the right slice type:
	try std.testing.expect(@TypeOf(good_stones) == []u16);
    // Because we sliced twice, with one runtime and one compile-time known length,
	// Zig can deduce a pointer-to-array type. It's all about what Zig can know when.
	try std.testing.expect(good_stones[0] == 93);
    try std.testing.expect(good_stones[1] == 58);
    try std.testing.expect(good_stones[2] == 11);
}

test "strings as slices" {
    // A spell name represented as a UTF-8 slice
	const spell_name: []const u8 = "Caldara's Blaze";

    // We want to isolate the substring "Blaze" at runtime.
	var start_of_substring: usize = 10; // Counting: C(0)a(1)l(2)d(3)a(4)r(5)a(6)'(7)s(8) (space)(9)B(10)
    _ = &start_of_substring; // runtime-known index

    const substring = spell_name[start_of_substring..];
    try std.testing.expect(@TypeOf(substring) == []const u8);
    try std.testing.expect(std.mem.eql(u8, substring, "Blaze"));

    // If you mess up and pick out-of-range indices, Zig will let you know at runtime.
	// substring[99]; // would panic, since substring isn’t that long.
}

test "sentinel-terminated slices" {
    // Imagine a C-style string that’s zero-terminated.
	const legacy_name: [:0]const u8 = "Elixir";
    // "Elixir" is 6 characters plus a 0 at the end.
	try std.testing.expect(legacy_name.len == 6);
    try std.testing.expect(legacy_name[6] == 0);

    // If you create a sentinel-terminated slice from data that doesn't match:
	var data = [_]u8{ 70, 71, 72 }; // no terminating 0 here
    const good_slice = data[0..data.len]; _= good_slice;
	// const bad_slice = data[0..data.len :0]; _ = bad_slice; // would cause a sentinel mismatch panic
}
