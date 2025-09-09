const std = @import("std");

const GeneralError = error{
    NotFound,
    PermissionDenied,
    DiskFull,
    ConnectionLost,
};

const NetworkError = error{
    ConnectionLost,
};

fn connectToServer() NetworkError!void {
    return error.ConnectionLost;
}

fn performTask() GeneralError!void {
    // NetworkError is coerced into GeneralError by try
    try connectToServer();
    // Additional logic would go here
}

pub fn main() void {
    performTask() catch |err| {
        std.debug.print("performTask failed with: {s}\n", .{@errorName(err)});
        return;
    };
    std.debug.print("Performed task successfully\n", .{});
}