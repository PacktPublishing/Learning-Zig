const std = @import("std");
const fs = std.fs;

pub const FileMetadata = struct {
    md: fs.File.Metadata,
    path: []const u8,
    inode: u64,  // unique identifier for files (helps detect moves)
    checksum: ?[]const u8, // optional content hash

    // Allocator responsible for any owned memory
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, path: []const u8, hash_content: bool) !FileMetadata {
        // Open the file to read metadata
        const abs_path = try fs.realpathAlloc(allocator, path);
        errdefer allocator.free(abs_path);

        const file = try fs.openFileAbsolute(abs_path, .{});
        defer file.close();

        const md = try fs.File.metadata(file);
        // Get file stat information
        const stat = try file.stat();
        // Create the metadata structure
        var metadata = FileMetadata{
            .path = abs_path,
            .md = md,
            .inode = stat.inode,
            .checksum = null,
            .allocator = allocator,
        };

        // Optionally compute file hash
        if (hash_content) {
            metadata.checksum = try computeFileHash(file, allocator);
        }

        return metadata;
    }

    pub fn deinit(self: *const FileMetadata) void {
        self.allocator.free(self.path);
        if (self.checksum) |checksum| {
            self.allocator.free(checksum);
        }
    }

    // Create a duplicate of this metadata
    pub fn clone(fmd: FileMetadata) !FileMetadata {
        var new_metadata = FileMetadata{
            .path = try fmd.allocator.dupe(u8, fmd.path),
            .md = fmd.md,
            .inode = fmd.inode,
            .checksum = null,
            .allocator = fmd.allocator,
        };

        if (fmd.checksum) |cs| {
            new_metadata.checksum = try fmd.allocator.dupe(u8, cs);
        }

        return new_metadata;
    }

};


// Tests for FileMetadata
    test "FileMetadata initialization and cleanup" {
    // Create a test file
    const test_filename = "test_file.txt";
    const test_content = "Hello, FileGuard!";

    // Create a test allocator
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create the test file
        const file = try std.fs.cwd().createFile(test_filename, .{});
    try file.writeAll(test_content);
    file.close();
    defer std.fs.cwd().deleteFile(test_filename) catch {};

    // Initialize metadata (without hash)
        var metadata = try FileMetadata.init(allocator, test_filename, false);
    defer metadata.deinit();

    // Verify metadata
        try std.testing.expect(metadata.md.size() == test_content.len);
    try std.testing.expect(metadata.checksum == null);

    // Initialize metadata (with hash)
        const metadata_with_hash = try FileMetadata.init(allocator, test_filename, true);
    defer metadata_with_hash.deinit();

    // Verify hash exists
        try std.testing.expect(metadata_with_hash.checksum != null);
    try std.testing.expect(metadata_with_hash.checksum.?.len == 64); // SHA-256 hex string length

        // Test cloning
        var cloned_metadata = try metadata.clone();
    defer cloned_metadata.deinit();

    try std.testing.expectEqualStrings(metadata.path, cloned_metadata.path);
    try std.testing.expect(metadata.md.size() == cloned_metadata.md.size());
    try std.testing.expect(metadata.inode == cloned_metadata.inode);
    // _ = std.debug.print("{s}\n", .{"file-metadata tests"});
    }

// Helper function to compute file hash (SHA-256)
fn computeFileHash(file: fs.File, allocator: std.mem.Allocator) ![]const u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});

    // Use a 4KB buffer for reading
    var buffer: [4096]u8 = undefined;

    // Seek to the start of the file
    try file.seekTo(0);

    // Read and hash the file in chunks
    while (true) {
        const bytes_read = try file.read(&buffer);
        if (bytes_read == 0) break;

        hasher.update(buffer[0..bytes_read]);
    }

    // Finalize the hash
    var hash: [32]u8 = undefined;
    hasher.final(&hash);

    // Convert the hash to a hexadecimal string
    const hex_hash = try allocator.alloc(u8, 64);
    _ = try std.fmt.bufPrint(hex_hash, "{s}", .{std.fmt.fmtSliceHexLower(&hash)});

    return hex_hash;
}
