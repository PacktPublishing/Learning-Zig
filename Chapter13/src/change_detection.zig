const std = @import("std");
const FileMetadata = @import("file_metadata.zig").FileMetadata;
const FileIndex = @import("file_index.zig").FileIndex;

/// Types of changes that can be detected
pub const ChangeType = enum {
    created, // File is new
    deleted, // File no longer exists
    modified, // File content has changed
    moved, // File was moved or renamed
    permissions, // Permissions have changed
    timestamp, // Timestamp has changed without content changes
};

/// Represents a detected change to a file
pub const FileChange = struct {
    // Type of change that was detected
    change_type: ChangeType,

    // Original path of the file (null for created files)
    old_path: ?[]const u8,

    // Current path of the file (null for deleted files)
    new_path: ?[]const u8,

    // Original metadata (null for created files)
    old_metadata: ?FileMetadata,

    // Current metadata (null for deleted files)
    new_metadata: ?FileMetadata,

    // When the change was detected
    timestamp: i64,

    // Allocator for memory management
    allocator: std.mem.Allocator,

    /// Initialize a file change record
    pub fn init(
        allocator: std.mem.Allocator,
        change_type: ChangeType,
        old_path: ?[]const u8,
        new_path: ?[]const u8,
        old_metadata: ?FileMetadata,
        new_metadata: ?FileMetadata,
    ) !FileChange {
        var change = FileChange{
            .change_type = change_type,
            .old_path = null,
            .new_path = null,
            .old_metadata = null,
            .new_metadata = null,
            .timestamp = std.time.timestamp(),
            .allocator = allocator,
        };

        // Make deep copies of paths and metadata
        if (old_path) |path| {
            change.old_path = try allocator.dupe(u8, path);
        }

        if (new_path) |path| {
            change.new_path = try allocator.dupe(u8, path);
        }

        if (old_metadata) |metadata| {
            change.old_metadata = try metadata.clone();
        }

        if (new_metadata) |metadata| {
            change.new_metadata = try metadata.clone();
        }

        return change;
    }

    /// Free memory used by a file change record
    pub fn deinit(self: *FileChange) void {
        if (self.old_path) |path| {
            self.allocator.free(path);
        }

        if (self.new_path) |path| {
            self.allocator.free(path);
        }

        if (self.old_metadata) |*metadata| {
            metadata.deinit();
        }

        if (self.new_metadata) |*metadata| {
            metadata.deinit();
        }
    }
};

/// Configuration for change detection
pub const DetectionConfig = struct {
    // Enable timestamp monitoring
    monitor_timestamps: bool = true,

    // Enable size change detection
    monitor_size: bool = true,

    // Enable content hash comparison
    monitor_content: bool = false,

    // Enable permission change detection
    monitor_permissions: bool = false,

    // Enable move detection using inodes
    detect_moves: bool = true,

    // Test the configuration basics
    test "DetectionConfig defaults" {
        const config = DetectionConfig{};

        try std.testing.expect(config.monitor_timestamps);
        try std.testing.expect(config.monitor_size);
        try std.testing.expect(!config.monitor_content);
        try std.testing.expect(!config.monitor_permissions);
        try std.testing.expect(config.detect_moves);
    }
};

/// Journal for recording file changes
pub const ChangeJournal = struct {
    // List of detected changes
    changes: std.ArrayList(FileChange),

    // Allocator for memory management
    allocator: std.mem.Allocator,

    /// Initialize a new change journal
    pub fn init(allocator: std.mem.Allocator) ChangeJournal {
        return ChangeJournal{
            .changes = std.ArrayList(FileChange).init(allocator),
            .allocator = allocator,
        };
    }

    /// Free memory used by the journal
    pub fn deinit(self: *ChangeJournal) void {
        for (self.changes.items) |*change| {
            change.deinit();
        }
        self.changes.deinit();
    }

    /// Record a file change in the journal
    pub fn recordChange(
        self: *ChangeJournal,
        change_type: ChangeType,
        old_path: ?[]const u8,
        new_path: ?[]const u8,
        old_metadata: ?FileMetadata,
        new_metadata: ?FileMetadata,
    ) !void {
        const change = try FileChange.init(self.allocator, change_type, old_path, new_path, old_metadata, new_metadata);

        try self.changes.append(change);
    }

    /// Get the number of changes in the journal
    pub fn count(self: *const ChangeJournal) usize {
        return self.changes.items.len;
    }
};

/// Detect changes between two file indices
pub fn detectChanges(
    old_index: *const FileIndex,
    new_index: *const FileIndex,
    config: *const DetectionConfig,
    journal: *ChangeJournal,
) !void {
    // Step 1: Find deleted files (in old but not in new)
    var old_iterator = old_index.files.iterator();
    while (old_iterator.next()) |entry| {
        const path = entry.key_ptr.*;
        const old_metadata = entry.value_ptr.*;

        if (!new_index.contains(path)) {
            if (config.detect_moves) {
                // Check if the file was moved (same inode appears elsewhere)
                if (old_metadata.inode != 0) {
                    if (new_index.findByInode(old_metadata.inode)) |new_path| {
                        // File was moved/renamed
                        const new_metadata_opt = new_index.get(new_path);
                        if (new_metadata_opt) |new_metadata_ptr|
                        try journal.recordChange(
                            .moved,
                            path,
                            new_path,
                            old_metadata,
                            new_metadata_ptr.*,
                        );
                        continue; // Skip recording as deleted
                    }
                }
            }

            // File was deleted
            try journal.recordChange(
                .deleted,
                path,
                null,
                old_metadata,
                null,
            );
        }
    }

    // Step 2: Find created and modified files (in new but maybe not in old)
    var new_iterator = new_index.files.iterator();
    while (new_iterator.next()) |entry| {
        const path = entry.key_ptr.*;
        const new_metadata = entry.value_ptr.*;

        if (old_index.get(path)) |old_metadata| {
            // File exists in both - check for modifications
            try detectFileModifications(
                path,
                old_metadata.*,
                new_metadata,
                config,
                journal,
            );
        } else {
            // Skip files already detected as moved
            var was_move = false;
            if (config.detect_moves and new_metadata.inode != 0) {
                // Check if this is the destination of a move operation
                if (old_index.findByInode(new_metadata.inode)) |_| {
                    was_move = true;
                }
            }

            if (!was_move) {
                // New file (not detected as moved)
                try journal.recordChange(
                    .created,
                    null,
                    path,
                    null,
                    new_metadata,
                );
            }
        }
    }
}

/// Detect modifications between two versions of the same file
fn detectFileModifications(
    path: []const u8,
    old_metadata: FileMetadata,
    new_metadata: FileMetadata,
    config: *const DetectionConfig,
    journal: *ChangeJournal,
) !void {
    // Check content changes first (highest priority)
    if (config.monitor_content) {
        // If both have checksums and they don't match, content changed
        if (old_metadata.checksum != null and new_metadata.checksum != null) {
            if (!std.mem.eql(u8, old_metadata.checksum.?, new_metadata.checksum.?)) {
                try journal.recordChange(
                    .modified,
                    path,
                    path,
                    old_metadata,
                    new_metadata,
                );
                return; // No need to check other modifications
            }
        }
    }

    // Check size changes
    if (config.monitor_size) {
        if (old_metadata.md.size() != new_metadata.md.size()) {
            try journal.recordChange(
                .modified,
                path,
                path,
                old_metadata,
                new_metadata,
            );
            return; // No need to check other modifications
        }
    }

    // Check permission changes
    if (config.monitor_permissions) {
        if (!std.meta.eql(old_metadata.md.permissions(), new_metadata.md.permissions())) {
            try journal.recordChange(
                .permissions,
                path,
                path,
                old_metadata,
                new_metadata,
            );
        }
    }

    // Check timestamp changes
    if (config.monitor_timestamps) {
        // Focus on modification time
        const old_mtime = old_metadata.md.modified();
        const new_mtime = new_metadata.md.modified();

        if (old_mtime != new_mtime) {
            try journal.recordChange(
                .timestamp,
                path,
                path,
                old_metadata,
                new_metadata,
            );
        }
    }
}

test "Basic change detection" {
    // Create old index
    var old_index = FileIndex.init(std.testing.allocator);
    defer old_index.deinit();

    // Create new index
    var new_index = FileIndex.init(std.testing.allocator);
    defer new_index.deinit();

    // Create test directory
    const test_dir = "test_changes_dir";
    try std.fs.cwd().makeDir(test_dir);
    defer std.fs.cwd().deleteTree(test_dir) catch {};

    // Create a test file for the old index
    const old_file_path = try std.fs.path.join(std.testing.allocator, &[_][]const u8{ test_dir, "file.txt" });
    defer std.testing.allocator.free(old_file_path);
    {
        const file = try std.fs.cwd().createFile(old_file_path, .{});
        try file.writeAll("Old content");
        file.close();
    }

    // Add file to old index
    const metadata = try FileMetadata.init(std.testing.allocator, old_file_path, true);
    defer metadata.deinit();
    try old_index.addFile(metadata);

    // Modify the file for the new index
    {
        try std.fs.cwd().deleteFile(old_file_path);
        const file = try std.fs.cwd().createFile(old_file_path, .{});
        try file.writeAll("New content");
        file.close();
    }

    // Create a new file for the new index
    const new_file_path = try std.fs.path.join(std.testing.allocator, &[_][]const u8{ test_dir, "new_file.txt" });
    defer std.testing.allocator.free(new_file_path);
    {
        const file = try std.fs.cwd().createFile(new_file_path, .{});
        try file.writeAll("Brand new file");
        file.close();
    }

    // Add both files to new index
    const metadata1 = try FileMetadata.init(std.testing.allocator, old_file_path, true);
    try new_index.addFile(metadata1);
    defer metadata1.deinit();

    const metadata2 = try FileMetadata.init(std.testing.allocator, new_file_path, true);
    try new_index.addFile(metadata2);
    defer metadata2.deinit();

    // Create a change journal
    var journal = ChangeJournal.init(std.testing.allocator);
    defer journal.deinit();

    // Detect changes
    const config = DetectionConfig{
        .monitor_content = true,
    };

    try detectChanges(&old_index, &new_index, &config, &journal);

    // We expect 2 changes:
    // 1. Modified file.txt
    // 2. Created new_file.txt
    try std.testing.expectEqual(@as(usize, 2), journal.count());

    // Verify the changes
    var found_modification = false;
    var found_creation = false;

    for (journal.changes.items) |change| {
        switch (change.change_type) {
            .modified => {
                // Just check that the path ends with the expected filename
                try std.testing.expect(std.mem.endsWith(u8, change.old_path.?, "file.txt"));
                try std.testing.expect(std.mem.endsWith(u8, change.new_path.?, "file.txt"));
                found_modification = true;
            },
            .created => {
                // Just check that the path ends with the expected filename
                try std.testing.expect(std.mem.endsWith(u8, change.new_path.?, "new_file.txt"));
                found_creation = true;
            },
            else => {
                try std.testing.expect(false); // Unexpected change type
            },
        }
    }

    try std.testing.expect(found_modification);
    try std.testing.expect(found_creation);
}
