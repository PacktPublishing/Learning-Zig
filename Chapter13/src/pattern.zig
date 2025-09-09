const std = @import("std");
const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("fnmatch.h");
});

pub fn matches(allocator: std.mem.Allocator, pattern: []const u8, name: []const u8) bool {
    // Ensure null-terminated strings for C fnmatch
    const pattZ = allocator.allocSentinel(u8, pattern.len, 0) catch return false;
    defer allocator.free(pattZ);
    std.mem.copyForwards(u8, pattZ[0..pattern.len], pattern);

    const nameZ = allocator.allocSentinel(u8, name.len, 0) catch return false;
    defer allocator.free(nameZ);
    std.mem.copyForwards(u8, nameZ[0..name.len], name);

    // to understand what is possible for the flags: https://man7.org/linux/man-pages/man3/fnmatch.3.html
    const rc: c_int = c.fnmatch(@ptrCast(pattZ.ptr), @ptrCast(nameZ.ptr), 0);
    return rc == 0;
}

pub fn matchesAnyPattern(allocator: std.mem.Allocator, patterns: []const []const u8, path: []const u8) bool {
    for (patterns) |pattern| {
        if (matches(allocator, pattern, path)) {
            // std.debug.print("MATCH: {s} {s}\n", .{pattern, path});
            return true;
        }
    }
    return false;
}


// Tests for pattern matching
test "Pattern matching basics" {
    const allocator = std.testing.allocator;
    
    // Simple exact matches
    try std.testing.expect(matches(allocator, "file.txt", "file.txt"));
    try std.testing.expect(!matches(allocator, "other.txt", "file.txt"));

    // Wildcard matches
    try std.testing.expect(matches(allocator, "*.txt", "file.txt"));
    try std.testing.expect(matches(allocator, "file.*", "file.txt"));
    try std.testing.expect(matches(allocator, "*.*", "file.txt"));
    try std.testing.expect(matches(allocator, "*", "file.txt"));

    // Question mark matches
    try std.testing.expect(matches(allocator, "file.???", "file.txt"));
    try std.testing.expect(matches(allocator, "????.???", "file.txt"));
    try std.testing.expect(!matches(allocator, "???.???", "file.txt"));

    // Mixed wildcards
    try std.testing.expect(matches(allocator, "f*.t?t", "file.txt"));
    try std.testing.expect(!matches(allocator, "f*.doc", "file.txt"));

    try std.testing.expect(matches(allocator, "*/*.txt", "test_traversal_dir/file1.txt"));
    // Should match across directory separators when FNM_PATHNAME is not set
    try std.testing.expect(matches(allocator, "*.txt", "test_traversal_dir/file1.txt"));
}

test "Pattern matching with multiple patterns" {
    const allocator = std.testing.allocator;
    const include_patterns = [_][]const u8{ "*.txt", "*.md", "*.zig" };
    const exclude_patterns = [_][]const u8{ "temp*", "*.tmp" };

    // These should match include patterns
    // std.debug.print("pattern: {s} | name: {s}\n", .{include_patterns, "file.txt"});
    try std.testing.expect(matchesAnyPattern(allocator, &include_patterns, "file.txt"));
    try std.testing.expect(matchesAnyPattern(allocator, &include_patterns, "README.md"));
    try std.testing.expect(matchesAnyPattern(allocator, &include_patterns, "main.zig"));

    // These should not match include patterns
    try std.testing.expect(!matchesAnyPattern(allocator, &include_patterns, "image.png"));
    try std.testing.expect(!matchesAnyPattern(allocator, &include_patterns, "data.json"));

    // These should match exclude patterns
    try std.testing.expect(matchesAnyPattern(allocator, &exclude_patterns, "temp.txt"));
    try std.testing.expect(matchesAnyPattern(allocator, &exclude_patterns, "file.tmp"));
    try std.testing.expect(matchesAnyPattern(allocator, &exclude_patterns, "temp_data.md"));

    // These should not match exclude patterns
    try std.testing.expect(!matchesAnyPattern(allocator, &exclude_patterns, "document.txt"));
    try std.testing.expect(!matchesAnyPattern(allocator, &exclude_patterns, "main.zig"));
}
