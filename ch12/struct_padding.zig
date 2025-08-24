const std = @import("std");

// 35. Regular Struct with Padding
const MyStruct = struct {
    a: u8, // 1 byte
    // implicit padding to align next field
    b: u32, // 4 bytes
};

test "ch12: struct padding and size/alignment" {
    const align_u32 = @alignOf(u32);
    const head: usize = @sizeOf(u8); // 1
    const padding: usize = (align_u32 - (head % align_u32)) % align_u32;
    const expected: usize = head + padding + @sizeOf(u32);

    try std.testing.expectEqual(expected, @sizeOf(MyStruct));
    try std.testing.expectEqual(@alignOf(u32), @alignOf(MyStruct));

    // For common platforms this is 8 bytes
    if (@sizeOf(MyStruct) == 8) {
        std.debug.print("MyStruct size is 8 bytes due to padding.\n", .{});
    }
}
