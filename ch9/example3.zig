const std = @import("std");
const expect = std.testing.expect;
test "debugging spawn points with pointer math" {
    const spawn_point_ptr: *usize = @ptrFromInt(0xdeadbee0); // Memory-mapped spawn point

    const addr = @intFromPtr(spawn_point_ptr);
    try expect(@TypeOf(addr) == usize);
    try expect(addr == 0xdeadbee0); // Spawn point matches the expected address
}
