const std = @import("std");

// Export our components
pub const FileMetadata = @import("file_metadata.zig").FileMetadata;
pub const FileIndex = @import("file_index.zig").FileIndex;
pub const TraversalConfig = @import("config.zig").TraversalConfig;
pub const pattern = @import("pattern.zig");
pub const traverseDirectory = @import("traversal.zig").traverseDirectory;
pub const ChangeType = @import("change_detection.zig").ChangeType;
pub const FileChange = @import("change_detection.zig").FileChange;
pub const DetectionConfig = @import("change_detection.zig").DetectionConfig;
pub const ChangeJournal = @import("change_detection.zig").ChangeJournal;
pub const detectChanges = @import("change_detection.zig").detectChanges;
pub const cli = @import("cli.zig");

pub fn main() !void {
    // Run the CLI
    try cli.run();
}

test {
    _ = @import("file_metadata.zig");
    _ = @import("file_index.zig");

    _ = @import("config.zig");
    _ = @import("pattern.zig");

    _ = @import("traversal.zig");

    _ = @import("change_detection.zig");
}

// This test block ensures our test runner compiles and includes all tests from imported files
test {
    std.testing.refAllDecls(@This());
}
