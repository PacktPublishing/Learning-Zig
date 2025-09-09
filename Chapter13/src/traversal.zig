const std = @import("std");
const FileMetadata = @import("file_metadata.zig").FileMetadata;
const FileIndex = @import("file_index.zig").FileIndex;
const TraversalConfig = @import("config.zig").TraversalConfig;
const pattern = @import("pattern.zig");

/// Determines if a file should be included based on the patterns
fn shouldIncludeFile(allocator: std.mem.Allocator, path: []const u8, config: *const TraversalConfig) bool {
    // Exclusion patterns take precedence over inclusion patterns
    if (pattern.matchesAnyPattern(allocator, config.exclude_patterns, path)) {
        return false;
    }

    // Check if the file matches any inclusion pattern
    return pattern.matchesAnyPattern(allocator, config.include_patterns, path);
}

/// Recursively traverses a directory and builds a file index
pub fn traverseDirectory(
    index: *FileIndex,
    dir_path: []const u8,
    config: *const TraversalConfig,
) !void {
    // Open the directory
    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();

    // Iterate through directory entries
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        // Construct the full path
        const full_path = try std.fs.path.join(
            index.allocator,
            &[_][]const u8{ dir_path, entry.name }
        );
        defer index.allocator.free(full_path);

        // Handle different entry types
        switch (entry.kind) {
            .file => {
                // Check if the file should be included
                if (shouldIncludeFile(index.allocator, full_path, config)) {
                    // Get metadata and add to index
                    const metadata = try FileMetadata.init(
                        index.allocator,
                        full_path,
                        config.hash_content
                    );
                    defer metadata.deinit();
                    try index.addFile(metadata);
                }
            },
            .directory => {
                // Check depth limit before recursing
                if (config.max_depth == null or config.current_depth < config.max_depth.?) {
                    // Create a new config with incremented depth
                    var next_config = config.*;
                    next_config.current_depth += 1;

                    // Recursively process subdirectory
                    try traverseDirectory(index, full_path, &next_config);
                }
            },
            .sym_link => {
                if (config.follow_symlinks) {
                    // Resolve the symlink using a real buffer (empty buffer is invalid)
                    var link_buf: [std.fs.max_path_bytes]u8 = undefined;
                    const target_rel = try dir.readLink(entry.name, &link_buf);
                    const resolved_path = try std.fs.path.resolve(
                        index.allocator,
                        &[_][]const u8{ dir_path, target_rel }
                    );
                    defer index.allocator.free(resolved_path);

                    // Check if the target is a directory or file
                    const target_stat = try std.fs.cwd().statFile(resolved_path);

                    if (target_stat.kind == .directory) {
                        // Check depth limit before recursing
                        if (config.max_depth == null or config.current_depth < config.max_depth.?) {
                            // Create a new config with incremented depth
                            var next_config = config.*;
                            next_config.current_depth += 1;

                            // Recursively process target directory using the traversal path (symlink path)
                            try traverseDirectory(index, full_path, &next_config);
                        }
                    } else if (target_stat.kind == .file) {
                        // Check if the file should be included using the traversal path (symlink path)
                        if (shouldIncludeFile(index.allocator, full_path, config)) {
                            // Get metadata and add to index using the traversal path
                            const metadata = try FileMetadata.init(
                                index.allocator,
                                full_path,
                                config.hash_content
                            );
                            defer metadata.deinit();
                            try index.addFile(metadata);
                        }
                    }
                }
            },
            else => {}, // Skip other types (pipes, devices, etc.)
        }
    }
}

// Tests for directory traversal
test "Basic directory traversal" {
    // Create a temporary test directory structure
    const test_dir = "test_traversal_dir";

    // Set up test allocator
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create test directory
    try std.fs.cwd().makeDir(test_dir);
    defer std.fs.cwd().deleteTree(test_dir) catch {};

    // Create some test files
    const file1 = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "file.txt" });
    const file2 = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "file2.md" });
    const file3 = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "excluded.tmp" });

    // Create a subdirectory with a file
    const subdir = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "subdir" });
    try std.fs.cwd().makeDir(subdir);
    const subfile = try std.fs.path.join(allocator, &[_][]const u8{ subdir, "subfile.txt" });

    // Create all the files
    {
        const f1 = try std.fs.cwd().createFile(file1, .{});
        try f1.writeAll("Test file 1");
        f1.close();

        const f2 = try std.fs.cwd().createFile(file2, .{});
        try f2.writeAll("Test file 2");
        f2.close();

        const f3 = try std.fs.cwd().createFile(file3, .{});
        try f3.writeAll("Excluded file");
        f3.close();

        const sf = try std.fs.cwd().createFile(subfile, .{});
        try sf.writeAll("Subdir file");
        sf.close();
    }

    // Initialize file index
    var index = FileIndex.init(allocator);
    defer index.deinit();

    // Define traversal configuration with pattern matching
    const config = TraversalConfig{
        .include_patterns = &[_][]const u8{ "*.txt", "*.md" },
        .exclude_patterns = &[_][]const u8{ "*.tmp" },
        .hash_content = true,
    };

    // Traverse the directory
    try traverseDirectory(&index, test_dir, &config);

    // We expect 3 files to be indexed (file.txt, file2.md, subdir/subfile.txt)
    // The excluded.tmp file should be excluded
    try std.testing.expectEqual(@as(usize, 3), index.count());

    // Test with root-only depth (max_depth = 0)
    var root_only_index = FileIndex.init(allocator);
    defer root_only_index.deinit();

    const root_only_config = TraversalConfig{
        .include_patterns = &[_][]const u8{ "*.txt", "*.md" },
        .exclude_patterns = &[_][]const u8{ "*.tmp" },
        .max_depth = 0,  // root-only depth
    };

    try traverseDirectory(&root_only_index, test_dir, &root_only_config);

    // We expect only 2 files to be indexed (file.txt, file2.md)
    // The subdir/subfile.txt should be excluded due to depth limit
    try std.testing.expectEqual(@as(usize, 2), root_only_index.count());

}

// Tests for directory traversal
test "Basic directory traversal 2" {
    // Create a temporary test directory structure
    const test_dir = "test_traversal_dir1";

    // Set up test allocator
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create test directory
    try std.fs.cwd().makeDir(test_dir);
    defer std.fs.cwd().deleteTree(test_dir) catch {};

    // Create some test files
    const file1 = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "file.txt" });
    const file2 = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "file2.md" });
    const file3 = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "excluded.tmp" });

    // Create a subdirectory with a file
    const subdir = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "subdir" });
    try std.fs.cwd().makeDir(subdir);
    const subfile = try std.fs.path.join(allocator, &[_][]const u8{ subdir, "subfile.txt" });

    // Create all the files
    {
        const f1 = try std.fs.cwd().createFile(file1, .{});
        try f1.writeAll("Test file 1");
        f1.close();

        const f2 = try std.fs.cwd().createFile(file2, .{});
        try f2.writeAll("Test file 2");
        f2.close();

        const f3 = try std.fs.cwd().createFile(file3, .{});
        try f3.writeAll("Excluded file");
        f3.close();

        const sf = try std.fs.cwd().createFile(subfile, .{});
        try sf.writeAll("Subdir file");
        sf.close();
    }


    // Test with depth limit
    var limited_index = FileIndex.init(allocator);
    defer limited_index.deinit();

    const limited_config = TraversalConfig{
        .include_patterns = &[_][]const u8{ "*.txt", "*.md" },
        .exclude_patterns = &[_][]const u8{ "*.tmp" },
        .max_depth = 0,  // Don't process subdirectories
    };

    try traverseDirectory(&limited_index, test_dir, &limited_config);

    // We expect 2 files to be indexed (file.txt, file2.md)
    // The subdir/subfile.txt should be excluded due to depth limit
    try std.testing.expectEqual(@as(usize, 2), limited_index.count());
}


// Symlink traversal test ensures we correctly read the link target using a proper buffer
// and that following symlinks can include files beyond the max_depth restriction.
test "Symlink traversal with root-only depth" {
    const test_dir = "test_symlink_traversal_dir";

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create root dir and subdir
    try std.fs.cwd().makeDir(test_dir);
    defer std.fs.cwd().deleteTree(test_dir) catch {};

    const subdir = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "subdir" });
    try std.fs.cwd().makeDir(subdir);

    const target = try std.fs.path.join(allocator, &[_][]const u8{ subdir, "target.txt" });

    // Create target file in subdir
    {
        const f = try std.fs.cwd().createFile(target, .{});
        try f.writeAll("hello");
        f.close();
    }

    // Create a symlink in the root pointing to subdir/target.txt (relative target)
    const link = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "link_to_target" });
    const rel_target = try std.fs.path.join(allocator, &[_][]const u8{ "subdir", "target.txt" });
    try std.fs.cwd().symLink(rel_target, link, .{});

    // Without following symlinks and with root-only depth, nothing should be indexed
    var idx1 = FileIndex.init(allocator);
    defer idx1.deinit();
    const cfg1 = TraversalConfig{
        .include_patterns = &[_][]const u8{ "*.txt" },
        .max_depth = 0,
        .follow_symlinks = false,
    };
    try traverseDirectory(&idx1, test_dir, &cfg1);
    try std.testing.expectEqual(@as(usize, 0), idx1.count());

    // With following symlinks and pattern matching traversal path, "*.txt" will not match
    // the symlink name at root. Expect 0.
    var idx2 = FileIndex.init(allocator);
    defer idx2.deinit();
    const cfg2 = TraversalConfig{
        .include_patterns = &[_][]const u8{ "*.txt" },
        .max_depth = 0,
        .follow_symlinks = true,
    };
    try traverseDirectory(&idx2, test_dir, &cfg2);
    try std.testing.expectEqual(@as(usize, 0), idx2.count());

    // If we use a permissive pattern that matches the symlink name, we should include 1.
    var idx3 = FileIndex.init(allocator);
    defer idx3.deinit();
    const cfg3 = TraversalConfig{
        .include_patterns = &[_][]const u8{ "*" },
        .max_depth = 0,
        .follow_symlinks = true,
    };
    try traverseDirectory(&idx3, test_dir, &cfg3);
    try std.testing.expectEqual(@as(usize, 1), idx3.count());
}


// Ensures include patterns are evaluated against the traversal path (join(dir, name))
// not the resolved absolute target path of a symlink.
// With a root-only depth and a symlink at root pointing into subdir, a pattern like
// "subdir/*.txt" should not match the symlinked file because the traversal path is
// "link_to_target" at root, not "subdir/target.txt".
test "Symlink pattern consistency with traversal path" {
    const test_dir = "test_symlink_pattern_consistency";

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create root dir and subdir
    try std.fs.cwd().makeDir(test_dir);
    defer std.fs.cwd().deleteTree(test_dir) catch {};

    const subdir = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "subdir" });
    try std.fs.cwd().makeDir(subdir);

    const target = try std.fs.path.join(allocator, &[_][]const u8{ subdir, "target.txt" });

    // Create target file in subdir
    {
        const f = try std.fs.cwd().createFile(target, .{});
        try f.writeAll("hello");
        f.close();
    }

    // Create a symlink in the root pointing to subdir/target.txt (relative target)
    const link = try std.fs.path.join(allocator, &[_][]const u8{ test_dir, "link_to_target" });
    const rel_target = try std.fs.path.join(allocator, &[_][]const u8{ "subdir", "target.txt" });
    try std.fs.cwd().symLink(rel_target, link, .{});

    // With following symlinks and a pattern anchored to subdir, we expect 0 matches when
    // evaluating patterns against traversal paths (root-only depth).
    var idx = FileIndex.init(allocator);
    defer idx.deinit();
    const cfg = TraversalConfig{
        .include_patterns = &[_][]const u8{ "subdir/*.txt" },
        .max_depth = 0,
        .follow_symlinks = true,
    };
    try traverseDirectory(&idx, test_dir, &cfg);
    try std.testing.expectEqual(@as(usize, 0), idx.count());
}
