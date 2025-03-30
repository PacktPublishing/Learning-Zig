const std = @import("std");

const User = struct {
    name: []const u8,
    score: u32
};

pub fn main() !void {
    var users = [_]User{
        .{ .name = "Alice", .score = 150 },
        .{ .name = "Bob", .score = 95 },
    };

    // Sort descending by score
    std.sort.block(User, &users, {}, struct {
        pub fn lessThan(_: void, a: User, b: User) bool {
            return a.score > b.score;
        }
    }.lessThan);

    std.debug.print("Leader: {s}\n", .{users[0].name});
}
