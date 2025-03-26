const std = @import("std");

pub fn main() void {
    const result = std.fmt.parseFloat(f64,"3.1415") catch |err| {
        std.debug.print("Failed to parse float: {s}\n", .{@errorName(err)});

        return;
    };

    std.debug.print("Parsed float: {}\n", .{result});
}
