const std = @import("std");

const Entity = struct {
    id: u32,
    name: []const u8,
};

fn createEntities(allocator: std.mem.Allocator, count: usize) ![]Entity {
    return try allocator.alloc(Entity, count);
}

test "Allocating Structs with FBA" {
    var buffer: [128]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const allocator = fba.allocator();

    const entities = try createEntities(allocator, 3);
    defer allocator.free(entities);

    entities[0] = .{ .id = 1, .name = "Hero" };
    entities[1] = .{ .id = 2, .name = "Villain" };
    entities[2] = .{ .id = 3, .name = "Sidekick" };

    try std.testing.expectEqual(entities[0].id, 1);
    try std.testing.expectEqualStrings(entities[1].name, "Villain");
}