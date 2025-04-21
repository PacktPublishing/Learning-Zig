const std = @import("std");

const Data = union {
    intValue: i32,
    floatValue: f64,
    textValue: []const u8,
};

pub fn main() void {
    var inputData = Data{ .intValue = 42 };
    std.debug.print("Integer value: {d}\n", .{inputData.intValue});

    // Change the union to hold a float
    inputData = Data{ .floatValue = 3.14 };
    std.debug.print("Floating-point value: {d}\n", .{inputData.floatValue});

    // Now change it to hold a string
    inputData = Data{ .textValue = "Hello, Zig!" };
    std.debug.print("Text value: {s}\n", .{inputData.textValue});
}
