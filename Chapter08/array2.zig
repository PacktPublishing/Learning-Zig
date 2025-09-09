const std = @import("std");

test "iterate over an array" {
    const message = "hello";
    var sum: usize = 0;
    for (message) |byte| {
        sum += byte;
    }
    try std.testing.expect(sum == 'h' + 'e' + 'l' * 2 + 'o');
}


test "modify an array" {
    var some_integers: [100]i32 = undefined;
    for (&some_integers, 0..) |*item, i| {
        item.* = @intCast(i);
    }
    try std.testing.expect(some_integers[10] == 10);
    try std.testing.expect(some_integers[99] == 99);
}
