const std = @import("std");

fn catAlloc(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);

    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);

    return result;
}

test "Concatenating Strings with FBA" {
    var buffer: [64]u8 = undefined;

    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const allocator = fba.allocator();
    const hello = "Hello, ";
    const world = "world!";

    const result = try catAlloc(allocator, hello, world);

    defer allocator.free(result);

    try std.testing.expectEqualStrings(result, "Hello, world!");
}