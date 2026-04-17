const std = @import("std");

const Player = extern struct {
    health: u32,
    mana: u32,
    level: u16,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const file = try cwd.createFile(io, "save.bin", .{ .read = true });
    defer file.close(io);

    // Write struct to binary
    const player = Player{ .health = 100, .mana = 50, .level = 42 };
    try file.writeStreamingAll(io, std.mem.asBytes(&player));

    // Read back using positional read (at offset 0)
    var buffer: [@sizeOf(Player)]u8 = undefined;
    _ = try file.readPositionalAll(io, &buffer, 0);

    const loaded = std.mem.bytesToValue(Player, &buffer);
    std.debug.print("Loaded: {d} HP\n", .{loaded.health});
}
