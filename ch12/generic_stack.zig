const std = @import("std");

// Mini-project: Generic Stack
// A basic fixed-capacity, heap-allocated generic stack.
// Demonstrates a generic type factory and using `anytype` with coercion to `T`.
pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        items: []T, // owned buffer
        len: usize,

        pub fn init(allocator: std.mem.Allocator, cap: usize) !Self {
            const buf = try allocator.alloc(T, cap);
            return .{ .allocator = allocator, .items = buf, .len = 0 };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
            self.* = undefined;
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.len == 0;
        }

        pub fn isFull(self: *const Self) bool {
            return self.len == self.items.len;
        }

        pub fn capacity(self: *const Self) usize {
            return self.items.len;
        }

        // Push accepts anytype. We then try to assign to T.
        // This works when `item` is already `T` or a comptime-known value that can
        // be coerced to T. Zig does not do implicit runtime numeric casts, so
        // passing, e.g., a u8 variable to a Stack(i32) push will fail to compile
        // unless explicitly cast by the caller.
        pub fn push(self: *Self, item: anytype) !void {
            if (self.isFull()) return error.StackOverflow;
            // This forces understanding of both type and anytype
            const converted: T = item; // Works if item is T or comptime-coercible to T
            self.items[self.len] = converted;
            self.len += 1;
        }

        pub fn pop(self: *Self) !T {
            if (self.len == 0) return error.StackUnderflow;
            self.len -= 1;
            return self.items[self.len];
        }

        pub fn peek(self: *const Self) !T {
            if (self.len == 0) return error.StackUnderflow;
            return self.items[self.len - 1];
        }
    };
}

// -----------------
// Tests
// -----------------
const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "generic stack basics with ints" {
    const gpa = std.testing.allocator;
    var s = try Stack(i32).init(gpa, 3);
    defer s.deinit();

    try expect(s.isEmpty());
    try expect(s.capacity() == 3);

    // Pushing comptime integer literals will coerce to i32 for assignment
    try s.push(10);
    try s.push(20);
    try expect(s.len == 2);
    try expect(try s.peek() == 20);

    // Fill to capacity and check overflow error
    try s.push(30);
    try expect(s.isFull());
    try expectError(error.StackOverflow, s.push(40));

    const v1 = try s.pop();
    const v2 = try s.pop();
    try expect(v1 == 30);
    try expect(v2 == 20);
    try expect(try s.pop() == 10);
    try expectError(error.StackUnderflow, s.pop());
}

test "generic stack with slices shows anytype + coercion" {
    const gpa = std.testing.allocator;
    var s = try Stack([]const u8).init(gpa, 2);
    defer s.deinit();

    // String literals coerce to []const u8 when assigned
    try s.push("hello");
    try s.push("world");

    const b = try s.pop();
    const a = try s.pop();
    try expect(std.mem.eql(u8, a, "hello"));
    try expect(std.mem.eql(u8, b, "world"));
}
