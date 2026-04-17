const std = @import("std");

// 1. Dynamic Struct Generation
// In Zig 0.16, @Type is replaced by dedicated builtins: @Struct, @Int, @Enum, etc.
fn generateStruct(
    comptime field_names: anytype,
    comptime field_types: anytype,
) type {
    const n = field_names.len;
    var attrs: [n]std.builtin.Type.StructField.Attributes = undefined;
    for (&attrs) |*a| {
        a.* = .{};
    }

    return @Struct(.auto, null, field_names, field_types, &attrs);
}

// Usage example from the chapter
const MyStruct = generateStruct(
    &[_][:0]const u8{ "id", "name", "score" },
    &[_]type{ i32, []const u8, f32 },
);

// Provide a small test to ensure it works and compiles
test "ch12: dynamic struct generation usage" {
    const instance = MyStruct{
        .id = 42,
        .name = "Zig Developer",
        .score = 95.5,
    };

    try std.testing.expectEqual(@as(i32, 42), instance.id);
    try std.testing.expectEqualStrings("Zig Developer", instance.name);
    try std.testing.expect(@as(f32, 95.0) < instance.score and instance.score < 96.0);
}
