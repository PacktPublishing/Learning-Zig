const std = @import("std");

fn allocateResource(allocator: *std.mem.Allocator) !*u8 {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer);

    performOperation(buffer) catch |err| {
        return err;
    };

    return buffer;
}

fn performOperation(_: []u8) !void {
    // Perform some operation with the buffer.
    return void;
}
