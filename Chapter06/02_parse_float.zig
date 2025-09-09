const std = @import("std");

const ParseError = error{
    InvalidFormat,
    Overflow,
};

fn parseFloat(input: []const u8) ParseError!f64 {
    const result = std.fmt.parseFloat(f64, input) catch {
        // Zig 0.15.1 may not expose Overflow in ParseFloatError; map any failure to InvalidFormat
        return error.InvalidFormat;
    };
    return result;
}

pub fn main() !void {
    const good = try parseFloat("3.1415");
    std.debug.print("Parsed: {}\n", .{good});

    _ = parseFloat("not-a-number") catch |err| {
        std.debug.print("Expected error: {s}\n", .{@errorName(err)});
        return;
    };
}