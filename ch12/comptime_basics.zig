const std = @import("std");

fn someCompileTimeFunction() i32 {
    return 7;
}

fn add(x: comptime_int, y: comptime_int) comptime_int {
    return x + y;
}

fn complex_calculation(x: i32) i32 {
    // A stand-in for a complex calculation
    return x * x + 3;
}

fn my_function(comptime x: i32) void {
    comptime {
        if (x < 0) {
            @compileError("x must be non-negative");
        }
    }
}

fn factorial(comptime n: u32) comptime_int {
    if (n == 0) return 1;
    return n * factorial(n - 1);
}

// Tests for comptime basics (snippets 1–7, 8 valid call; invalid calls are commented)
test "ch12: comptime basics and validations" {
    // 1. Basic comptime usage
    const x = comptime someCompileTimeFunction();
    try std.testing.expectEqual(@as(i32, 7), x);

    // 2. Type inference with comptime_int
    const my_number = 1234;
    const sum = add(my_number, 5678);
    try std.testing.expectEqual(@as(comptime_int, 6912), sum);

    // 3. Precomputing complex function
    const res2 = comptime complex_calculation(12);
    try std.testing.expectEqual(@as(i32, 12 * 12 + 3), res2);

    // 4 & 5. comptime blocks and array size validation
    const array_size = 10;
    comptime {
        std.debug.assert(array_size > 0);
    }

    // 6. Function parameter validation (valid call)
    my_function(0);
    // my_function(-1); // would be a compile error if uncommented

    // 7 & 8. Factorial evaluated at comptime
    const fact5 = comptime factorial(5);
    try std.testing.expectEqual(@as(comptime_int, 120), fact5);

    const fact5_const = factorial(5);
    try std.testing.expectEqual(@as(comptime_int, 120), fact5_const);

    // 9. Invalid runtime factorial call demonstration (commented)
    // var user_input: u32 = 5; // runtime value
    // const invalid = factorial(user_input); // ERROR: requires comptime-known argument
    // _ = invalid;
}
