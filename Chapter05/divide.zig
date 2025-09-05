fn divide(a: i32, b: i32) ?i32 {
    if (b == 0) {
        return null; // Cannot divide by zero
    }
    return @divExact(a, b);
}
