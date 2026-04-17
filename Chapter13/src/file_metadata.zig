const std = @import("std");
const Io = std.Io;
const Dir = Io.Dir;
const File = Io.File;

pub const FileMetadata = struct {
    md: File.Stat,
    path: [:0]const u8,
    inode: u64, // unique identifier for files (helps detect moves)
    checksum: ?[]const u8, // optional content hash

    // Allocator responsible for any owned memory
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, io: Io, path: []const u8, hash_content: bool) !FileMetadata {
        // Open the file to read metadata
        const abs_path = try Dir.cwd().realPathFileAlloc(io, path, allocator);
        errdefer allocator.free(abs_path);

        const file = try Dir.openFileAbsolute(io, abs_path, .{});
        defer file.close(io);

        const stat = try file.stat(io);
        // Create the metadata structure
        var metadata = FileMetadata{
            .path = abs_path,
            .md = stat,
            .inode = stat.inode,
            .checksum = null,
            .allocator = allocator,
        };

        // Optionally compute file hash
        if (hash_content) {
            metadata.checksum = try computeFileHash(file, io, allocator);
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
            .path = try fmd.allocator.dupeZ(u8, fmd.path),
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
    const io = std.testing.io;

    // Create a test file
    const test_filename = "test_file.txt";
    const test_content = "Hello, FileGuard!";

    // Create a test allocator
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Create the test file
    const file = try Dir.cwd().createFile(io, test_filename, .{});
    try file.writeStreamingAll(io, test_content);
    file.close(io);
    defer Dir.cwd().deleteFile(io, test_filename) catch {};

    // Initialize metadata (without hash)
    var metadata = try FileMetadata.init(allocator, io, test_filename, false);
    defer metadata.deinit();

    // Verify metadata
    try std.testing.expect(metadata.md.size == test_content.len);
    try std.testing.expect(metadata.checksum == null);

    // Initialize metadata (with hash)
    const metadata_with_hash = try FileMetadata.init(allocator, io, test_filename, true);
    defer metadata_with_hash.deinit();

    // Verify hash exists
    try std.testing.expect(metadata_with_hash.checksum != null);
    try std.testing.expect(metadata_with_hash.checksum.?.len == 64); // SHA-256 hex string length

    // Test cloning
    var cloned_metadata = try metadata.clone();
    defer cloned_metadata.deinit();

    try std.testing.expectEqualStrings(metadata.path, cloned_metadata.path);
    try std.testing.expect(metadata.md.size == cloned_metadata.md.size);
    try std.testing.expect(metadata.inode == cloned_metadata.inode);
}

// Helper function to compute file hash (SHA-256)
fn computeFileHash(file: File, io: Io, allocator: std.mem.Allocator) ![]const u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});

    // Use a 4KB buffer for reading
    var buffer: [4096]u8 = undefined;

    // Read and hash the file in chunks using positional reads
    var offset: u64 = 0;
    while (true) {
        const bytes_read = try file.readPositionalAll(io, &buffer, offset);
        if (bytes_read == 0) break;

        hasher.update(buffer[0..bytes_read]);
        offset += bytes_read;
    }

    // Finalize the hash
    var hash: [32]u8 = undefined;
    hasher.final(&hash);

    // Convert the hash to a hexadecimal string
    const hex_array = std.fmt.bytesToHex(hash, .lower);
    const hex_hash = try allocator.alloc(u8, 64);
    @memcpy(hex_hash, &hex_array);

    return hex_hash;
}
