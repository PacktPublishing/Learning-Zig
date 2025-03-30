const std = @import("std");
test "slice syntax on pointers" {
    var y: i32 = 5678;
    const y_ptr = &y;
    const y_array_ptr = y_ptr[0..1]; // *[1]i32
	const y_many_ptr: [*]i32 = y_array_ptr;
    try std.testing.expect(@TypeOf(y_many_ptr) == [*]i32);
    try std.testing.expect(y_many_ptr[0] == 5678);
}

test "pointer arithmetic" {
    const arr = [_]i32{ 1, 2, 3, 4 };
    var ptr: [*]const i32 = &arr;
	try std.testing.expect(ptr[0] == 1);
    ptr += 1; // move forward one element
	try std.testing.expect(ptr[0] == 2);
}
