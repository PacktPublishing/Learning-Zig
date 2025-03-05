const std = @import("std");

pub fn main() void {
    const day = 3;

    switch (day) {
        1 => std.debug.print("It's Monday.\n", .{}),

        2 => std.debug.print("It's Tuesday.\n", .{}),

        3 => std.debug.print("It's Wednesday.\n", .{}),

        //else => std.debug.print("It's some other day.\n", .{}),
    }
}
