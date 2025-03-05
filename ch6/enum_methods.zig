
const std = @import("std");

const TrafficLight = enum {
    Red,
    Yellow,
    Green,

    pub fn isSafeToGo(self: TrafficLight) bool {
        return self == TrafficLight.Green;
    }
};

pub fn main() !void {
    const light = TrafficLight.Red;
    if (light.isSafeToGo()) {
        std.debug.print("Go ahead.\n", .{});
    } else {
        std.debug.print("Stop right there!\n", .{});
    }
}
