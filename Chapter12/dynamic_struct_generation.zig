const std = @import("std");

// 1. Dynamic Struct Generation (Pages 15-16)
fn generateStruct(comptime field_names: []const []const u8, comptime field_types: []const type) type {
    var fields: [field_names.len]std.builtin.Type.StructField = undefined;

    for (field_names, 0..) |name, i| {
        fields[i] = .{
            .name = name[0..:0],
            .type = field_types[i],
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(field_types[i]),
        };
    }

    return @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = &fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });
}

// Usage example from the chapter
const MyStruct = generateStruct(
    &[_][]const u8{ "id", "name", "score" },
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