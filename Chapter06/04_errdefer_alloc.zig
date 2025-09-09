const std = @import("std");

const OperationError = error{ OperationFailed };

fn performOperation(buf: []u8) OperationError!void {
    // Simulate an operation that might fail depending on content
    if (buf.len > 0 and buf[0] == 0) {
        return error.OperationFailed;
    }
    // Pretend we write something into the buffer
    if (buf.len >= 11) {
        std.mem.copyForwards(u8, buf[0..11], "hello world");
    }
}

fn allocateResource(allocator: std.mem.Allocator) (std.mem.Allocator.Error || OperationError)![]u8 {
    const buffer = try allocator.alloc(u8, 1024);
    errdefer allocator.free(buffer);

    // Perform operations that might fail
    try performOperation(buffer);

    return buffer;
}

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa_state.deinit();
        if (check == .leak) std.debug.print("warning: memory leaked\n", .{});
    }
    const allocator = gpa_state.allocator();

    const buf = try allocateResource(allocator);
    defer allocator.free(buf);

    std.debug.print("Allocated and initialized buffer of {d} bytes. First 11: {s}\n", .{ buf.len, buf[0..@min(buf.len, 11)] });
}