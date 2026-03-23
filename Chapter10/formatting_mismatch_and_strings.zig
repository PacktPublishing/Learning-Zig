const std = @import("std");

pub fn main() !void {
    const name = "Zig";
    const score = 9001;

    // Compile-time validated format string
    std.debug.print("Player {s} scored {d} points\n", .{name, score});

    // In Zig 0.15+, using a mismatched format specifier (e.g., {d} for a string)
    // is a compile error. Always use the correct specifier for the type:
    // - {s} for strings
    // - {d} for integers
    std.debug.print("Score: {s}\n", .{"100"}); // Output: Score: 100
}
