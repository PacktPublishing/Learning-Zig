const std = @import("std");

pub const TraversalConfig = struct {
    max_depth: ?usize = null, // Maximum directory depth to traverse (null = unlimited)
    include_patterns: []const []const u8 = &.{"*"}, // Glob patterns for files to include
    exclude_patterns: []const []const u8 = &.{}, // Glob patterns for files to exclude
    hash_content: bool = false, // Whether to compute content hashes
    follow_symlinks: bool = false, // Whether to follow symbolic links

    // Current depth level (internal tracking)
    current_depth: usize = 0,
};

// Test the configuration basics
test "TraversalConfig defaults" {
    const config = TraversalConfig{};

    try std.testing.expect(config.max_depth == null);
    try std.testing.expectEqualSlices([]const u8, &.{"*"}, config.include_patterns);
    try std.testing.expectEqualSlices([]const u8, &.{}, config.exclude_patterns);
    try std.testing.expect(config.hash_content == false);
    try std.testing.expect(config.follow_symlinks == false);
    try std.testing.expect(config.current_depth == 0);
}
