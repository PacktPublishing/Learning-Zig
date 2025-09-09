const std = @import("std");
const FileMetadata = @import("file_metadata.zig").FileMetadata;

pub const FileIndex = struct {
    // Map from file paths to their metadata
    files: std.StringHashMap(FileMetadata),
    // Map from inodes to file paths (for detecting file moves)
    inodes: std.AutoHashMap(u64, []const u8),
    // Allocator for managing memory
    allocator: std.mem.Allocator,
    // Track path allocations separately
    path_storage: std.StringHashMap(void),

    pub fn init(allocator: std.mem.Allocator) FileIndex {
        return FileIndex{
            .files = std.StringHashMap(FileMetadata).init(allocator),
            .inodes = std.AutoHashMap(u64, []const u8).init(allocator),
            .allocator = allocator,
            .path_storage = std.StringHashMap(void).init(allocator),
        };
    }

    pub fn deinit(self: *FileIndex) void {
        // First free all metadata objects
        var it = self.files.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }

        // Free all path strings we've tracked
        var path_it = self.path_storage.keyIterator();
        while (path_it.next()) |path_ptr| {
            self.allocator.free(path_ptr.*);
        }

        // Free the hashmaps themselves
        self.files.deinit();
        self.inodes.deinit();
        self.path_storage.deinit();
    }

    // Add a file to the index
    pub fn addFile(self: *FileIndex, metadata: FileMetadata) !void {
        const cloned = try metadata.clone();
        errdefer cloned.deinit();

        // Duplicate the path to avoid reference problems
        const path_copy = try self.allocator.dupe(u8, cloned.path);
        errdefer self.allocator.free(path_copy);

        // Track this path allocation
        try self.path_storage.put(path_copy, {});

        // Add to our indices
        try self.files.put(path_copy, cloned);
        if (cloned.inode != 0) {
            try self.inodes.put(cloned.inode, path_copy);
        }
    }

    /// Memory ownership:
    /// - The new FileIndex is responsible for all its internal allocations
    /// - All path strings are duplicated, so both indices have independent string ownership
    /// - FileMetadata objects are cloned with duplicated path and checksum strings
    /// - The fs.File.Metadata is copied directly (doesn't contain owned pointers)
    ///
    /// This function maintains the relationship between paths and inodes in the cloned index.
    /// Modifying one index will not affect the other after cloning.
    ///
    /// Caller owns the returned FileIndex and must call deinit() on it when done.
    ///
    /// Returns: A new FileIndex with identical content but independent memory
    /// Error: Returns an error if any allocation fails
    pub fn clone(self: *const FileIndex) !FileIndex {
        // Create a new FileIndex with the same allocator
        var cloned = FileIndex.init(self.allocator);
        errdefer cloned.deinit();

        // Clone all files and their metadata
        var it = self.files.iterator();
        while (it.next()) |entry| {
            // Get the original metadata
            const original_metadata = entry.value_ptr.*;

            // Create new metadata object directly rather than going through addFile
            // to avoid double allocation of strings
            const metadata_clone = FileMetadata{
                .allocator = cloned.allocator,
                .path = try cloned.allocator.dupe(u8, original_metadata.path),
                .inode = original_metadata.inode,
                .md = original_metadata.md, // File.Metadata is a simple struct that can be copied directly
                .checksum = if (original_metadata.checksum) |cs|
                    try cloned.allocator.dupe(u8, cs)
                else
                    null,
            };
            errdefer {
                if (metadata_clone.checksum) |cs| {
                    cloned.allocator.free(cs);
                }
                cloned.allocator.free(metadata_clone.path);
                // No need to deinit metadata_clone.md as it's a simple struct copy
            }

            // Duplicate the path to avoid reference problems and for the index key
            const path_copy = try cloned.allocator.dupe(u8, metadata_clone.path);
            errdefer cloned.allocator.free(path_copy);

            // Track this path allocation
            try cloned.path_storage.put(path_copy, {});

            // Add to our indices
            try cloned.files.put(path_copy, metadata_clone);
            if (metadata_clone.inode != 0) {
                try cloned.inodes.put(metadata_clone.inode, path_copy);
            }
        }

        return cloned;
    }

    // Get number of files in the index
    pub fn count(self: *const FileIndex) usize {
        return self.files.count();
    }

    // Check if a file exists in the index
    pub fn contains(self: *const FileIndex, path: []const u8) bool {
        return self.files.contains(path);
    }

    // Get metadata for a file (by reference, more efficient)
    pub fn get(self: *const FileIndex, path: []const u8) ?*const FileMetadata {
        return self.files.getPtr(path);
    }

    // Find a file by inode
    pub fn findByInode(self: *const FileIndex, inode: u64) ?[]const u8 {
        return self.inodes.get(inode);
    }

    // Method to remove a file from the index
    pub fn removeFile(self: *FileIndex, path: []const u8) void {
        if (self.files.fetchRemove(path)) |removed| {
            if (removed.value.inode != 0) {
                _ = self.inodes.remove(removed.value.inode);
            }

            // Deinit the metadata object
            removed.value.deinit();

            // Remove and free the path from our tracking
            _ = self.path_storage.remove(removed.key);
            self.allocator.free(removed.key);
        }
    }
};

// Tests for FileIndex
test "FileIndex operations" {
    // Create a test file
    const test_filename = "test_index_file.txt";
    const test_content = "Hello, FileGuard!";
    const file_path = try createTempFile(std.testing.allocator, test_filename, test_content);
    defer deleteTempFile(std.testing.allocator, file_path);

    const test_filename2 = "test_index_file2.txt";
    const test_content2 = "Hello, FileGuard2!";
    const file_path2 = try createTempFile(std.testing.allocator, test_filename2, test_content2);
    defer deleteTempFile(std.testing.allocator, file_path2);

    // Initialize file index
    var index = FileIndex.init(std.testing.allocator);
    defer index.deinit();

    // Get files metadata
    var metadata = try FileMetadata.init(std.testing.allocator, file_path, true);
    defer metadata.deinit();
    var metadata2 = try FileMetadata.init(std.testing.allocator, file_path2, true);
    defer metadata2.deinit();

    // Add to index
    try index.addFile(metadata);
    try index.addFile(metadata2);

    // Verify counts
    try std.testing.expect(index.count() == 2);
    try std.testing.expect(index.contains(metadata.path));
    try std.testing.expect(index.contains(metadata2.path));

    // Retrieve by path and verify
    if (index.get(metadata.path)) |retrieved| {
        try std.testing.expect(metadata.md.size() == retrieved.md.size());
        try std.testing.expect(metadata.inode == retrieved.inode);
        try std.testing.expectEqualStrings(metadata.checksum.?, retrieved.checksum.?);
    } else {
        return error.FileNotFound;
    }

    // Retrieve by inode and verify
    if (index.findByInode(metadata.inode)) |path| {
        try std.testing.expectEqualStrings(metadata.path, path);
    } else {
        return error.InodeNotFound;
    }
}

// Helper function to create a temporary file with content
// It returns the file path. Otherwise the error.
fn createTempFile(allocator: std.mem.Allocator, name: []const u8, content: []const u8) ![]const u8 {
    const path = try std.fs.path.join(allocator, &[_][]const u8{ "tmp", name });
    errdefer allocator.free(path);

    // Create directory if it doesn't exist
    try std.fs.cwd().makePath("tmp");

    const file = try std.fs.cwd().createFile(path, .{});
    try file.writeAll(content);
    file.close();

    return path;
}

// Helper function to delete a temporary file
fn deleteTempFile(allocator: std.mem.Allocator, path: []const u8) void {
    std.fs.cwd().deleteFile(path) catch {};
    allocator.free(path);
}

// Helper function to delete a temporary file
fn deleteTempDir(allocator: std.mem.Allocator, path: []const u8) void {
    // Delete the directory first, then free the path buffer
    std.fs.cwd().deleteDir(path) catch {};
    allocator.free(path);
}

// Test the FileIndex clone method
test "FileIndex clone" {
    // Initialize random for this test
    var prng = std.Random.DefaultPrng.init(0);
    const random = prng.random();

    // Create test files with unique content to ensure uniqueness
    const random_suffix1 = random.int(u32);
    const random_suffix2 = random.int(u32);

    const test_filename1 = try std.fmt.allocPrint(std.testing.allocator, "test_clone_file1_{d}.txt", .{random_suffix1});
    defer std.testing.allocator.free(test_filename1);

    const test_filename2 = try std.fmt.allocPrint(std.testing.allocator, "test_clone_file2_{d}.txt", .{random_suffix2});
    defer std.testing.allocator.free(test_filename2);

    const test_content1 = "Hello, FileGuard Clone!";
    const test_content2 = "Hello, FileGuard Clone 2!";

    const file_path1 = try createTempFile(std.testing.allocator, test_filename1, test_content1);
    defer deleteTempFile(std.testing.allocator, file_path1);

    const file_path2 = try createTempFile(std.testing.allocator, test_filename2, test_content2);
    defer deleteTempFile(std.testing.allocator, file_path2);

    // Initialize original file index
    var original = FileIndex.init(std.testing.allocator);
    defer original.deinit();

    // Create and add file metadata
    var metadata1 = try FileMetadata.init(std.testing.allocator, file_path1, true);
    defer metadata1.deinit();

    var metadata2 = try FileMetadata.init(std.testing.allocator, file_path2, true);
    defer metadata2.deinit();

    try original.addFile(metadata1);
    try original.addFile(metadata2);

    // Store original paths for later comparison
    var originalPaths = std.ArrayList([]const u8).init(std.testing.allocator);
    defer originalPaths.deinit();
    {
        var it = original.files.keyIterator();
        while (it.next()) |key_ptr| {
            try originalPaths.append(key_ptr.*);
        }
    }

    // Verify original contains the expected number of files
    try std.testing.expect(original.count() == 2);
    try std.testing.expect(originalPaths.items.len == 2);

    // Now clone the index
    var cloned = try original.clone();
    defer cloned.deinit();

    // Verify counts match
    try std.testing.expect(cloned.count() == 2);

    // Collect all paths from cloned index
    var clonedPaths = std.ArrayList([]const u8).init(std.testing.allocator);
    defer clonedPaths.deinit();
    {
        var it = cloned.files.keyIterator();
        while (it.next()) |key_ptr| {
            try clonedPaths.append(key_ptr.*);
        }
    }

    // Verify the correct number of paths were found
    try std.testing.expect(clonedPaths.items.len == 2);

    // Match paths between original and clone
    var matches: usize = 0;
    for (originalPaths.items) |orig_path| {
        for (clonedPaths.items) |clone_path| {
            if (std.mem.eql(u8, orig_path, clone_path)) {
                matches += 1;
                break;
            }
        }
    }
    try std.testing.expect(matches == 2);

    // Compare metadata between original and clone (using internal paths)
    for (originalPaths.items) |orig_path| {
        const orig_meta = original.get(orig_path).?;

        // Find corresponding path in clone
        for (clonedPaths.items) |clone_path| {
            if (std.mem.eql(u8, orig_path, clone_path)) {
                const clone_meta = cloned.get(clone_path).?;

                try std.testing.expectEqual(orig_meta.md.size(), clone_meta.md.size());
                try std.testing.expectEqual(orig_meta.inode, clone_meta.inode);
                try std.testing.expectEqualStrings(orig_meta.checksum.?, clone_meta.checksum.?);
                break;
            }
        }
    }

    // Verify independence by modifying original
    original.removeFile(originalPaths.items[0]);
    try std.testing.expect(original.count() == 1);
    try std.testing.expect(cloned.count() == 2);

    // Verify all cloned paths still exist in cloned index
    for (clonedPaths.items) |clone_path| {
        try std.testing.expect(cloned.get(clone_path) != null);
    }
}
