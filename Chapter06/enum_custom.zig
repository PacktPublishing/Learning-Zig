const HttpStatus = enum(i32) {
    OK = 200,
    NotFound = 404,
    InternalServerError = 500,
};

const std = @import("std");

pub fn main() void {
    const status = HttpStatus.NotFound;
    const code = @intFromEnum(status);
    std.debug.print("HTTP Status Code: {d}\n", .{code});
}
