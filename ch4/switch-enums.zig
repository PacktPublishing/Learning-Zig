const std = @import("std");

pub fn main() void {
    var op: u8 = 1;

    while (true) {
        switch (op) {
            1 => {
                op = 2;
                continue;
            },
            2 => {
                op = 3;
                continue;
            },
            3 => {
                std.debug.print("Operation completed successfully.\n", .{});
                return;
            },
            4 => {
                std.debug.print("Operation 4 encountered.\n", .{});
                // Perform some action for operation 4
                break;
            },
            else => {
                std.debug.print("Unknown operation.\n", .{});
                break;
            },
        }
    }

    std.debug.print("Exiting the loop.\n", .{});
}
