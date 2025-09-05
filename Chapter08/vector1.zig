const std = @import("std");
const expectEqual = std.testing.expectEqual;

test "basic vector operations" {
    // Four intensities, because why not? Maybe these represent pixel values.
    const base = @Vector(4, u8){ 10, 20, 30, 40 };
    const add_val = @Vector(4, u8){ 1, 2, 3, 4 };
    // Element-wise addition
    const adjusted = base + add_val;

    try expectEqual(adjusted[0], 11); // 10 + 1
    try expectEqual(adjusted[1], 22); // 20 + 2
    try expectEqual(adjusted[2], 33); // 30 + 3
    try expectEqual(adjusted[3], 44); // 40 + 4
}

test "conversions between arrays and vectors" {
    const arr: [4]f32 = [_]f32{ 0.5, 1.5, 2.5, 3.5 };
    const vec: @Vector(4, f32) = arr; // direct conversion from array to vector
    const arr_back: [4]f32 = vec; // and back to an array
    try expectEqual(arr, arr_back);

    // If you only have part of the array, no problem:
    // Let's say we only need two elements from `arr` at runtime.
    var start: usize = 1;
    _ = &start; // to keep the compiler quiet
    const half_vec: @Vector(2, f32) = arr[start..][0..2].*;

    try expectEqual(half_vec[0], arr[1]); // 1.5
    try expectEqual(half_vec[1], arr[2]); // 2.5
}

test "scalars and vectors, splats and reductions" {
    const base = @Vector(4, i32){ 10, 20, 30, 40 };

    // Splatter a single scalar across the entire vector
    const increment: [4]i32 = @splat(5); // creates @Vector(4, i32){5, 5, 5, 5}
    const incremented = base + increment;

    try expectEqual(incremented[0], 15);
    try expectEqual(incremented[1], 25);
    try expectEqual(incremented[2], 35);
    try expectEqual(incremented[3], 45);

    // Reduce the vector to a single value (e.g. sum)
    // @reduce takes a builtin operation and a vector, returning a scalar.
    const sum = @reduce(.Add, incremented);
    try expectEqual(sum, 15 + 25 + 35 + 45); // 120
}
