// cli.zig - Minimalist version focusing only on monitoring with console output
const std = @import("std");
const argsParser = @import("args");
const FileMetadata = @import("file_metadata.zig").FileMetadata;
const FileIndex = @import("file_index.zig").FileIndex;
const TraversalConfig = @import("config.zig").TraversalConfig;
const DetectionConfig = @import("change_detection.zig").DetectionConfig;
const traverseDirectory = @import("traversal.zig").traverseDirectory;
const ChangeJournal = @import("change_detection.zig").ChangeJournal;
const detectChanges = @import("change_detection.zig").detectChanges;
const FileChange = @import("change_detection.zig").FileChange;

/// Command-line options for FileGuard
pub const CliOptions = struct {
    // Global options
    help: bool = false,
    verbose: bool = false,

    // Monitoring options
    @"include-patterns": []const u8 = "*",
    @"exclude-patterns": []const u8 = "",
    @"max-depth": ?usize = null,
    @"hash-content": bool = false,
    @"follow-symlinks": bool = false,
    @"monitor-timestamps": bool = true,
    @"monitor-size": bool = true,
    @"monitor-content": bool = false,
    @"monitor-permissions": bool = false,
    @"detect-moves": bool = true,
    continuous: bool = false,
    interval: u64 = 60,

    // Shorthands for command-line options
    pub const shorthands = .{
        .h = "help",
        .v = "verbose",
        .i = "include-patterns",
        .x = "exclude-patterns",
        .d = "max-depth",
        .c = "hash-content",
        .s = "follow-symlinks",
        .t = "monitor-timestamps",
        .z = "monitor-size",
        .C = "monitor-content",
        .p = "monitor-permissions",
        .m = "detect-moves",
        .w = "continuous",
        .n = "interval",
    };

    // Documentation for command-line options
    pub const meta = .{
        .full_text = "FileGuard: A File Monitoring System\n\n" ++
            "This tool helps you monitor directories for file changes and " ++
            "reports changes directly to the console.",

        .option_docs = .{
            .help = "Display help information",
            .verbose = "Enable verbose output",
            .@"include-patterns" = "Comma-separated glob patterns for files to include (default: *)",
            .@"exclude-patterns" = "Comma-separated glob patterns for files to exclude",
            .@"max-depth" = "Maximum directory traversal depth",
            .@"hash-content" = "Enable content hashing for files (slower but more accurate)",
            .@"follow-symlinks" = "Follow symbolic links when traversing directories",
            .@"monitor-timestamps" = "Monitor timestamp changes",
            .@"monitor-size" = "Monitor file size changes",
            .@"monitor-content" = "Monitor file content changes (requires --hash-content)",
            .@"monitor-permissions" = "Monitor permission changes",
            .@"detect-moves" = "Detect moved/renamed files",
            .continuous = "Monitor continuously",
            .interval = "Interval in seconds for continuous monitoring (default: 60)",
        },
    };
};

/// Global flag for signal handling
var should_exit = false;

/// Process command-line arguments and run the monitoring
pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command-line arguments
    const args = try argsParser.parseForCurrentProcess(
        CliOptions,
        allocator,
        .print,
    );
    defer args.deinit();

    // Show help if requested
    if (args.options.help) {
        return showHelp(args.executable_name orelse "fg");
    }

    // Get the path to monitor (first positional argument, or default to ".")
    const path = if (args.positionals.len > 0) args.positionals[0] else ".";

    // Validate configuration
    if (args.options.@"monitor-content" and !args.options.@"hash-content") {
        std.debug.print("Error: --monitor-content requires --hash-content\n", .{});
        return error.InvalidConfiguration;
    }

    // Run the monitoring
    try runMonitor(allocator, path, args.options);
}

/// Display help information
fn showHelp(program_name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Usage: {s} [OPTIONS] [PATH]\n\n", .{program_name});
    try stdout.writeAll("A file monitoring system that detects and reports changes to the console.\n\n");
    try stdout.writeAll("If PATH is not specified, the current directory will be monitored.\n\n");

    try stdout.writeAll("Options:\n");
    try stdout.writeAll("  -h, --help               Show this help message\n");
    try stdout.writeAll("  -v, --verbose            Enable verbose output\n\n");

    try stdout.writeAll("File Selection:\n");
    try stdout.writeAll("  -i, --include-patterns=PATTERNS  Comma-separated glob patterns for files to include (default: *)\n");
    try stdout.writeAll("  -x, --exclude-patterns=PATTERNS  Comma-separated glob patterns for files to exclude\n");
    try stdout.writeAll("  -d, --max-depth=DEPTH           Maximum directory traversal depth\n");
    try stdout.writeAll("  -s, --follow-symlinks           Follow symbolic links\n\n");

    try stdout.writeAll("Change Detection:\n");
    try stdout.writeAll("  -c, --hash-content             Enable content hashing\n");
    try stdout.writeAll("  -t, --monitor-timestamps       Monitor timestamp changes (default: true)\n");
    try stdout.writeAll("  -z, --monitor-size             Monitor size changes (default: true)\n");
    try stdout.writeAll("  -C, --monitor-content          Monitor content changes\n");
    try stdout.writeAll("  -p, --monitor-permissions      Monitor permission changes\n");
    try stdout.writeAll("  -m, --detect-moves             Detect moved files (default: true)\n\n");

    try stdout.writeAll("Monitoring:\n");
    try stdout.writeAll("  -w, --continuous         Monitor continuously\n");
    try stdout.writeAll("  -n, --interval=SECONDS   Interval in seconds (default: 60)\n");
}

/// Split a comma-separated string into an array of strings
fn splitPatterns(allocator: std.mem.Allocator, patterns_str: []const u8) ![]const []const u8 {
    // If empty, return an allocator-owned empty array to allow caller to free safely
    if (patterns_str.len == 0) {
        return try allocator.alloc([]const u8, 0);
    }

    // Count the number of patterns (commas + 1)
    const count: usize = std.mem.count(u8, patterns_str, ",") + 1;

    // Allocate an array for the patterns
    var patterns = try allocator.alloc([]const u8, count);
    var i: usize = 0;
    errdefer {
        // If we encounter an error, free everything allocated so far that was actually allocated
        for (patterns[0..i]) |pattern| {
            allocator.free(pattern);
        }
        allocator.free(patterns);
    }

    // Split the string and fill the array
    var iter = std.mem.splitScalar(u8, patterns_str, ',');
    while (iter.next()) |pattern| {
        // Trim whitespace
        const trimmed = std.mem.trim(u8, pattern, &[_]u8{ ' ', '\t' });
        patterns[i] = try allocator.dupe(u8, trimmed);
        i += 1;
    }

    return patterns;
}

/// Print a detected change to stdout
fn printChange(change: FileChange, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    const old_path = change.old_path orelse "unknown";
    const new_path = change.new_path orelse "unknown";

    switch (change.change_type) {
        .created => {
            try stdout.print("[{d}] CREATED: {s}\n", .{
                change.timestamp,
                new_path,
            });
        },
        .deleted => {
            try stdout.print("[{d}] DELETED: {s}\n", .{
                change.timestamp,
                old_path,
            });
        },
        .modified => {
            const display_path = if (change.new_path != null) new_path else old_path;
            try stdout.print("[{d}] MODIFIED: {s}\n", .{
                change.timestamp,
                display_path,
            });

            // Show size change if available
            if (change.old_metadata != null and change.new_metadata != null) {
                const old_meta = change.old_metadata.?;
                const new_meta = change.new_metadata.?;

                // Size changes
                const old_size = old_meta.md.size();
                const new_size = new_meta.md.size();

                if (old_size != new_size) {
                    const percentage = calculatePercentageChange(old_size, new_size);
                    try stdout.print("  Size changed: {d} → {d} bytes ({d})\t", .{
                        old_size,
                        new_size,
                        percentage,
                    });
                }

                // Modified time changes (if tracked but not the only change)
                if (old_meta.md.modified() != new_meta.md.modified() and
                    change.change_type != .timestamp)
                {
                    try stdout.print("  Modified time changed: {d} → {d}\n", .{
                        old_meta.md.modified(),
                        new_meta.md.modified(),
                    });
                }

                // Content hash changes (if tracked)
                if (old_meta.checksum != null and new_meta.checksum != null) {
                    const old_hash = old_meta.checksum.?;
                    const new_hash = new_meta.checksum.?;

                    if (!std.mem.eql(u8, old_hash, new_hash)) {
                        const old_hash_str = try std.fmt.allocPrint(allocator, "{s}", .{old_hash});
                        defer allocator.free(old_hash_str);
                        const new_hash_str = try std.fmt.allocPrint(allocator, "{s}", .{new_hash});
                        defer allocator.free(new_hash_str);

                        try stdout.print("  Content hash changed: {s} → {s}\n", .{
                            old_hash_str[0..8], // Display first 8 chars of hash for brevity
                            new_hash_str[0..8],
                        });
                    }
                }
            }
        },
        .moved => {
            try stdout.print("[{d}] MOVED: {s} → {s}\n", .{
                change.timestamp,
                old_path,
                new_path,
            });
        },
        .permissions => {
            const display_path = if (change.new_path != null) new_path else old_path;
            try stdout.print("[{d}] PERMISSIONS CHANGED: {s}\n", .{
                change.timestamp,
                display_path,
            });

            // Show permission details if available
            if (change.old_metadata != null and change.new_metadata != null) {
                const old_mode = change.old_metadata.?.md.permissions();
                const new_mode = change.new_metadata.?.md.permissions();

                try stdout.print("  Mode changed: {any} → {any}\n", .{
                    old_mode,
                    new_mode,
                });
            }
        },
        .timestamp => {
            const display_path = if (change.new_path != null) new_path else old_path;
            try stdout.print("[{d}] TIMESTAMP CHANGED: {s}\n", .{
                change.timestamp,
                display_path,
            });

            // Show timestamp details
            if (change.old_metadata != null and change.new_metadata != null) {
                try stdout.print("  Modified time: {d} → {d}\n", .{
                    change.old_metadata.?.md.modified(),
                    change.new_metadata.?.md.modified(),
                });
            }
        },
    }
}

/// Calculate percentage change between two values
fn calculatePercentageChange(old_value: u64, new_value: u64) f64 {
    if (old_value == 0) {
        return if (new_value == 0) 0.0 else 100.0;
    }

    const old_f = @as(f64, @floatFromInt(old_value));
    const new_f = @as(f64, @floatFromInt(new_value));

    return (new_f - old_f) / old_f * 100.0;
}

/// Check if a path exists and is accessible
fn validatePath(path: []const u8) !void {
    var dir = std.fs.cwd().openDir(path, .{}) catch |err| {
        switch (err) {
            error.FileNotFound => {
                std.debug.print("Error: Path '{s}' does not exist\n", .{path});
                return error.PathNotFound;
            },
            error.AccessDenied => {
                std.debug.print("Error: Access denied to path '{s}'\n", .{path});
                return error.AccessDenied;
            },
            else => {
                std.debug.print("Error: Unable to access path '{s}': {}\n", .{ path, err });
                return err;
            },
        }
    };
    dir.close();
}

/// Run the monitor
fn runMonitor(
    allocator: std.mem.Allocator,
    path: []const u8,
    options: CliOptions,
) !void {
    // First validate the path
    try validatePath(path);

    if (options.verbose) {
        std.debug.print("Monitoring {s} for changes\n", .{path});
    }

    // Resolve the real path
    const real_path = try std.fs.realpathAlloc(allocator, path);
    defer allocator.free(real_path);

    // Split the pattern strings into arrays
    const include_patterns = try splitPatterns(allocator, options.@"include-patterns");
    defer {
        for (include_patterns) |pattern| {
            allocator.free(pattern);
        }
        allocator.free(include_patterns);
    }

    const exclude_patterns = try splitPatterns(allocator, options.@"exclude-patterns");
    defer {
        for (exclude_patterns) |pattern| {
            allocator.free(pattern);
        }
        allocator.free(exclude_patterns);
    }

    // Create traversal configuration
    const traverse_config = TraversalConfig{
        .include_patterns = include_patterns,
        .exclude_patterns = exclude_patterns,
        .max_depth = options.@"max-depth",
        .hash_content = options.@"hash-content",
        .follow_symlinks = options.@"follow-symlinks",
    };

    // Create detection configuration
    const detect_config = DetectionConfig{
        .monitor_timestamps = options.@"monitor-timestamps",
        .monitor_size = options.@"monitor-size",
        .monitor_content = options.@"monitor-content",
        .monitor_permissions = options.@"monitor-permissions",
        .detect_moves = options.@"detect-moves",
    };

    // Create baseline index
    std.debug.print("Creating initial baseline index...\n", .{});
    var baseline_index = FileIndex.init(allocator);
    defer baseline_index.deinit();

    // Traverse directory for baseline
    try traverseDirectory(&baseline_index, real_path, &traverse_config);

    if (options.verbose) {
        std.debug.print("Baseline index created with {d} files\n", .{baseline_index.count()});
    }

    // Determine if we're doing continuous monitoring or a single check
    const is_continuous = options.continuous;
    const interval_ns = options.interval * std.time.ns_per_s;
    var last_change_time: i64 = 0;

    std.debug.print("Monitoring started. ", .{});
    if (is_continuous) {
        std.debug.print("Will check every {d} seconds. Press Ctrl+C to stop.\n", .{options.interval});
    } else {
        std.debug.print("Will perform a single check.\n", .{});
    }

    // Monitor loop
    while (!should_exit) {
        var current_index = FileIndex.init(allocator);
        defer current_index.deinit();

        // Traverse directory
        traverseDirectory(&current_index, real_path, &traverse_config) catch |err| {
            std.debug.print("Error during directory traversal: {}\n", .{err});
            std.debug.print("Will retry on next cycle\n", .{});
            if (!is_continuous) {
                return err;
            }
            std.time.sleep(interval_ns);
            continue;
        };

        if (options.verbose) {
            std.debug.print("Current scan found {d} files\n", .{current_index.count()});
        }

        // Create a change journal
        var change_journal = ChangeJournal.init(allocator);
        defer change_journal.deinit();

        // Detect changes
        try detectChanges(&baseline_index, &current_index, &detect_config, &change_journal);

        // If changes were detected
        if (change_journal.count() > 0) {
            const timestamp = std.time.timestamp();

            std.debug.print("\n=== Changes detected at {d} ({d} changes) ===\n\n", .{
                timestamp,
                change_journal.count(),
            });

            // Print each change
            for (change_journal.changes.items) |change| {
                printChange(change, allocator) catch |err| {
                    std.debug.print("Error printing change: {}\n", .{err});
                };
            }

            std.debug.print("\n", .{});
            last_change_time = timestamp;

            // Update baseline by creating a fresh copy of current_index
            const new_baseline = try current_index.clone();
            baseline_index.deinit();
            baseline_index = new_baseline;
        } else {
            if (options.verbose) {
                std.debug.print("No changes detected at {}\n", .{std.time.timestamp()});
            }
        }

        // If not continuous monitoring, break
        if (!is_continuous) {
            break;
        }
        // Sleep for the interval
        std.time.sleep(interval_ns);
    }

    std.debug.print("Monitoring completed.\n", .{});
}
