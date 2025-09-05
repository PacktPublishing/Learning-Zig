const assert = @import("std").debug.assert;

pub fn main() void {
    assert(2 + 2 == 4); // This is fine
    assert(2 + 2 == 5); // This will cause a panic in debug modes
}
