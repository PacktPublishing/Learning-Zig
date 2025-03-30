const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Custom key type
    const AdaptedKey = struct {
        name: []const u8
    };

    // Context with hash/eql implementations
    const AdaptedContext = struct {
        pub fn hash(ctx: @This(), key: AdaptedKey) u64 {
            _ = ctx; // Context unused here
            return std.hash.Wyhash.hash(0, key.name);
        }

        pub fn eql(ctx: @This(), a: AdaptedKey, b: AdaptedKey) bool {
            _ = ctx;
            return std.mem.eql(u8, a.name, b.name);
        }
    };

    // Initialize map with custom context
    var map = std.HashMap(
        AdaptedKey,
        u32,
        AdaptedContext,
        std.hash_map.default_max_load_percentage,
    ).init(allocator);
    defer map.deinit();

    // Insert using adapted key
    const entry = try map.getOrPut(.{ .name = "Zig" });
    if (!entry.found_existing) {
        entry.value_ptr.* = 9001;
    }

    // Retrieve value
    if (map.get(.{ .name = "Zig" })) |value| {
        print("Value: {d}\n", .{value}); // Output: Value: 9001
    }
}
