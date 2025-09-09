const std = @import("std");

const FetchError = error{
    InvalidResponse,
};

fn fetchData(url: []const u8) FetchError![]const u8 {
    if (url.len == 0) {
        return error.InvalidResponse;
    }
    // Simulate successful data retrieval
    return "Sample Data";
}

pub fn main() !void {
    const ok = try fetchData("https://example.com");
    std.debug.print("Data received: {s}\n", .{ok});

    // Demonstrate error path
    _ = fetchData("") catch |err| {
        std.debug.print("Received expected error: {s}\n", .{@errorName(err)});
        return;
    };
}