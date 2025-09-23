const std = @import("std");

// 2. Standalone @setEvalBranchQuota Example (Page 18)
comptime { @setEvalBranchQuota(5000); } // Increase the quota to 5000 branches

// Provide a tiny test to ensure the file compiles and the quota applies to comptime work
test "ch12: standalone setEvalBranchQuota" {
    @setEvalBranchQuota(5000);
    const SUM: usize = comptime blk: {
        var s: usize = 0;
        for (0..3000) |i| {
            s += i;
        }
        break :blk s;
    };
    try std.testing.expectEqual(@as(usize, 4_498_500), SUM);
}