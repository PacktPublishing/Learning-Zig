const std = @import("std");

const ErrorCode = enum(u16) {
    Success = 0,
    Failure = 1,
    _,
};

pub fn main() void {
    const code: ErrorCode = .Success;
    switch (code) {
        .Success => std.debug.print("Operation succeeded.\n", .{}),
        .Failure => std.debug.print("Operation failed.\n", .{}),
        _ => std.debug.print("Unknown error code.\n", .{}),
    }
}
