pub fn main() void {
    {
        var x: i32 = 1;
        x += 1;
    }
    // Trying to access x here will result in an error
    // x += 1; // Error: x is undefined here
}
