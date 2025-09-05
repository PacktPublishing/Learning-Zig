const std = @import("std");
// WARNING: PROBABLY THIS CODE WILL SEGFAULT
test "fire the cannon with volatile" {
    const cannon_control_ptr: *volatile u8 = @ptrFromInt(0x12345678); // MMIO for the cannon
    try std.testing.expect(@TypeOf(cannon_control_ptr) == *volatile u8);
    // Writing to this pointer could trigger the cannon in hardware.
    cannon_control_ptr.* = 1; // Fire the cannon!
}
