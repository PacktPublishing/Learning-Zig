const std = @import("std");

pub fn main() !void {
    const name = "Zig";
    const score = 9001;

    // Compile-time validated format string
    std.debug.print("Player {s} scored {d} points\n", .{ name, score });

    // In Zig 0.16, mismatched format specifiers are compile errors:
    // std.debug.print("Score: {d}\n", .{"100"});
    // error: invalid format string 'd' for type '*const [3:0]u8'

    // Use {s} for string types
    std.debug.print("Score: {s}\n", .{"100"}); // Output: Score: 100
}
