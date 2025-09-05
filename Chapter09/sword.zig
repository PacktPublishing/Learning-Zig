const std = @import("std");

const Sword = struct {
    stats: []u8,

    pub fn init(allocator: std.mem.Allocator, stats: []const u8) !*Sword {
        // Allocate memory for the struct.
        const sword_ptr = try allocator.create(Sword);
        errdefer allocator.destroy(sword_ptr);

        // Allocate memory for the sword stats.
        sword_ptr.stats = try allocator.alloc(u8, stats.len);
        @memcpy(sword_ptr.stats, stats);

        return sword_ptr;
    }

    pub fn deinit(self: *Sword, allocator: std.mem.Allocator) void {
        // Free the memory for the stats.
        allocator.free(self.stats);

        // Destroy the struct itself.
        allocator.destroy(self);
    }
};

const battleCry = "Victory!";

test "Sword initialization and cleanup" {
    const allocator = std.testing.allocator;
    const sword_ptr = try Sword.init(allocator, battleCry);

    // Ensure the stats were copied correctly.
    try std.testing.expectEqualStrings(battleCry, sword_ptr.stats);

}

test "Sword initialization and cleanup 2 " {
    const allocator = std.testing.failing_allocator;
    const sword = Sword.init(allocator, battleCry);

    try std.testing.expectError(error.OutOfMemory, sword);
}

test "Sword initialization and cleanup 3" {
    const allocator = std.testing.allocator;
    var sword_ptr = try Sword.init(allocator, battleCry);
    defer sword_ptr.deinit(allocator);

    // Ensure the stats were copied correctly.
    try std.testing.expectEqualStrings(battleCry, sword_ptr.stats);
}