const std = @import("std");
const builtin = @import("builtin");

const Monster = struct {
    name: []const u8,
    hp: u32,
    pub fn format(self: Monster, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{s} (HP: {d})", .{ self.name, self.hp });
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    const name = "Goku";
    const power_level: i32 = 9001;

    // Using a writer with std.fmt.format
    try std.fmt.format(stdout, "{s}'s power level is {d}.\n", .{ name, power_level });

    // allocPrint to produce a formatted owned string
    const message = try std.fmt.allocPrint(allocator, "Errors: {d}", .{42});
    defer allocator.free(message);
    try stdout.print("allocPrint -> {s}\n", .{message});

    // Alignment and numeric formatting
    std.debug.print("Health: {d:0>4}\n", .{5});
    std.debug.print("Mana: {d:*<4}\n", .{8});
    std.debug.print("Hex: 0x{x}\n", .{255});
    std.debug.print("PI: {d:.3}\n", .{3.1415926535});

    // Custom format method usage
    const boss = Monster{ .name = "Dragon", .hp = 1234 };
    // Use {} to trigger the custom format method
    std.debug.print("Boss -> {}\n", .{boss});
}
