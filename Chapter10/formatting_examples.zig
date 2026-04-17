const std = @import("std");

const Monster = struct {
    name: []const u8,
    hp: u32,

    // In Zig 0.16, custom format takes (self, writer) — no more comptime fmt or FormatOptions.
    pub fn format(self: Monster, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{s} (HP: {d})", .{ self.name, self.hp });
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const name = "Goku";
    const power_level: i32 = 9001;

    // std.debug.print writes directly to stderr (no Io needed)
    std.debug.print("{s}'s power level is {d}.\n", .{ name, power_level });

    // allocPrint to produce a formatted owned string
    const message = try std.fmt.allocPrint(allocator, "Errors: {d}", .{42});
    defer allocator.free(message);
    std.debug.print("allocPrint -> {s}\n", .{message});

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
