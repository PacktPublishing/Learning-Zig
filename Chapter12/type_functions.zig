const std = @import("std");

// 11. FixedArray type function
fn FixedArray(comptime T: type, comptime size: usize) type {
    return [size]T;
}

// 12. Pair type function
fn Pair(comptime T: type) type {
    return struct {
        begin: T,
        end: T,

        pub fn isBetween(this: @This(), other: T) bool {
            return this.begin <= other and other < this.end;
        }
    };
}

test "ch12: FixedArray and Pair type function" {
    // FixedArray usage
    const IntArray5 = FixedArray(i32, 5);
    const a: IntArray5 = .{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(@as(i32, 1), a[0]);

    // Pair usage
    const PairI32 = Pair(i32);
    const p1 = PairI32{ .begin = 2, .end = 14 };
    try std.testing.expect(p1.isBetween(3));
    try std.testing.expect(!p1.isBetween(99));

    const PairF64 = Pair(f64);
    const p2 = PairF64{ .begin = 0.2, .end = 0.4 };
    try std.testing.expect(p2.isBetween(0.22));
}

// 14. @TypeOf example
// 15. @typeInfo example
// 17. Creating new type with modified bits

test "ch12: type reflection with @TypeOf, @typeInfo, @Type" {
    const x: i32 = 42;
    const y: f32 = 3.14;
    const Peer = @TypeOf(x, y);
    try std.testing.expect(Peer == f32);

    const info_i32 = @typeInfo(i32);
    switch (info_i32) {
        .int => |int_info| {
            // Build a wider integer type based on i32 (i40)
            const NewType = @Type(.{ .int = .{
                .signedness = int_info.signedness,
                .bits = int_info.bits + 8,
            } });

            // Verify properties of the new type
            const info_new = @typeInfo(NewType);
            switch (info_new) {
                .int => |new_int| {
                    try std.testing.expectEqual(int_info.bits + 8, new_int.bits);
                    // Coercion and usage of NewType
                    var v: NewType = 1;
                    v += 1;
                    try std.testing.expectEqual(@as(NewType, 2), v);
                },
                else => try std.testing.expect(false),
            }
        },
        else => try std.testing.expect(false),
    }
}
