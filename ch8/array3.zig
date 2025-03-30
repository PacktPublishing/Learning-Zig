const part_one = [_]i32{ 1, 2, 3, 4 };
const part_two = [_]i32{ 5, 6, 7, 8 };
const all_of_it = part_one ++ part_two;

comptime {
    const std = @import("std");
    const mem = std.mem;
    const assert = std.debug.assert;
    assert(mem.eql(i32, &all_of_it, &[_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }));
}

const hello = "hello";
const world = "world";
const hello_world = hello ++ " " ++ world;

comptime {
    const std = @import("std");
    const mem = std.mem;
    const assert = std.debug.assert;
    assert(mem.eql(u8, hello_world, "hello world"));
}

const pattern = "ab" ** 3;
comptime {
    const std = @import("std");
    const mem = std.mem;
    const assert = std.debug.assert;
    assert(mem.eql(u8, pattern, "ababab"));
}

const all_zero = [_]u16{0} ** 10;

comptime {
    const std = @import("std");
    const assert = std.debug.assert;
    assert(all_zero.len == 10);
    for (all_zero) |item| {
        assert(item == 0);
    }
}

const mat4x4 = [4][4]f32{
    [_]f32{ 1.0, 0.0, 0.0, 0.0 },
    [_]f32{ 0.0, 1.0, 0.0, 1.0 },
    [_]f32{ 0.0, 0.0, 1.0, 0.0 },
    [_]f32{ 0.0, 0.0, 5.0, 1.0 },
};

comptime {
    const std = @import("std");
    const assert = std.debug.assert;
    assert(mat4x4[3][2] == 5.0);
}
