const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const alt_message: [5]u8 = .{ 'h', 'e', 'l', 'l', 'o' };

comptime {
    const std = @import("std");
    const mem = std.mem;
    const assert = std.debug.assert;
    assert(mem.eql(u8, &message, &alt_message));
    assert(message.len == 5);
}
