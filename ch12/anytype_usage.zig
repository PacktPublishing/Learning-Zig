const std = @import("std");

// 19. anytype add function (better version ensures same type)
fn addSame(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a + b;
}

// Helper: numeric type predicate
fn isNumeric(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

// 24. addNumbers with constraints
fn addNumbers(a: anytype, b: anytype) @TypeOf(a, b) {
    comptime {
        const T = @TypeOf(a, b);
        if (!isNumeric(T)) @compileError("addNumbers only works with numeric types");
    }
    return a + b;
}

// 23. Correct comptime type branching
fn processValueComptime(value: anytype) void {
    const T = @TypeOf(value);
    if (T == i32) {
        std.debug.print("It's an integer: {}\n", .{value});
    } else if (T == f32) {
        std.debug.print("It's a float: {}\n", .{value});
    } else {
        // For didactics: allow other types silently to compile tests
        std.debug.print("Type {} not specially handled\n", .{@typeName(T)});
    }
}

fn processValueSwitch(value: anytype) void {
    switch (@TypeOf(value)) {
        i32 => std.debug.print("It's an integer: {}\n", .{value}),
        f32 => std.debug.print("It's a float: {}\n", .{value}),
        else => std.debug.print("Unsupported type {}\n", .{@TypeOf(value)}),
    }
}

// 25. Generic function with concrete type
fn processNumbers(comptime T: type, values: []const T) void {
    for (values) |v| std.debug.print("{}\n", .{v});
}

fn processValue(value: anytype) void {
    std.debug.print("{}\n", .{value});
}

// 26. Correct type parameter naming
fn createContainer(comptime T: type) type {
    return struct {
        value: T,
        pub fn init(val: T) @This() {
            return .{ .value = val };
        }
    };
}

test "ch12: anytype usage and constraints" {
    // addSame
    try std.testing.expectEqual(@as(i32, 7), addSame(3, 4));

    // addNumbers with peer types
    const r1 = addNumbers(3, 2);
    try std.testing.expectEqual(@as(comptime_int, 5), r1);
    const r2 = addNumbers(@as(f64, 3.0), 2);
    try std.testing.expect(@TypeOf(r2) == f64);

    // processValueComptime and processValueSwitch (just ensure they compile)
    processValueComptime(@as(i32, 5));
    processValueComptime(@as(f32, 2.5));
    processValueSwitch(@as(i32, 6));

    // processNumbers and processValue
    const numbers = [_]i32{ 1, 2, 3, 4 };
    processNumbers(i32, &numbers);
    for (numbers) |n| processValue(n);

    // Container
    const IntContainer = createContainer(i32);
    const c = IntContainer.init(42);
    try std.testing.expectEqual(@as(i32, 42), c.value);
}
