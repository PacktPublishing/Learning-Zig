const std = @import("std");

pub fn main() !void {
    const name = "Zig";
    const score = 9001;

    // Compile-time validated format string
    std.debug.print("Player {s} scored {d} points\n", .{name, score});

    //Zig's Fallback Behavior:
    // When a type doesn’t match the format specifier, Zig tries to:
    // - Print the raw bytes of the value (ASCII codes in this case)
    // - Issue a runtime warning (not a compile error) about mismatched types
    std.debug.print("Score: {d}\n", .{"100"});

    std.debug.print("Score: {s}\n", .{"100"}); // Output: Score: 100
}
