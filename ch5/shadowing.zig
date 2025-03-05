pub fn main() void {
    const pi = 3.14;
    {
        var pi: i32 = 1234; // Error: cannot redeclare 'pi'
    }
}
