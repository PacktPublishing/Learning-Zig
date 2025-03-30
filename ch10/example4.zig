const std = @import("std");

const Player = extern struct {
    health: u32,
    mana: u32,
    level: u16,
};

pub fn main() !void {
    const file = try std.fs.cwd().createFile("save.bin", .{
        .read = true,
    });
    defer file.close();

    // Write struct to binary
    const player = Player{ .health = 100, .mana = 50, .level = 42 };
    try file.writeAll(std.mem.asBytes(&player));

    // Read back
    var buffer: [@sizeOf(Player)]u8 = undefined;
    try file.seekTo(0);
    _ = try file.readAll(&buffer);

    const loaded = std.mem.bytesToValue(Player, &buffer);
    std.debug.print("Loaded: {d} HP\n", .{loaded.health});
}
