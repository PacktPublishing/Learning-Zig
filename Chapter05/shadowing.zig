pub fn main() void {
    const pi = 3.14;
    {
        const pi2: i32 = 1234; // In Zig 0.15+, local variables cannot shadow outer scope names
        _ = pi2;
    }
    _ = pi;
}
