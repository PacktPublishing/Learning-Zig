const std = @import("std");



pub fn main() void {
    light: switch (@as(u8, 1)) {
        1 => {
            std.debug.print("Light is Red. Cars stop.\n", .{});
            continue :light 2;  // Transition to Yellow
        },
        2 => {
            std.debug.print("Light is Yellow. Prepare to stop.\n", .{});
            continue :light 3;  // Transition to Green
        },
        3 => {
            std.debug.print("Light is Green. Cars go.\n", .{});
            continue :light 4;  // Transition to Pedestrian Crossing
        },
        4 => {
            std.debug.print("Pedestrian crossing activated. Cars stop, people walk.\n", .{});
            return;  // End of cycle
        },
        else => unreachable,
    }
} 
