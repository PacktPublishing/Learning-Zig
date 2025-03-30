const std = @import("std");
const expect = std.testing.expect;

test "anonymous structs" {
    // Anonymous struct with named fields, inferred by the function signature:
    try check(.{
        .max_health = 200,
        .respawn_enabled = true,
    });
}

test "tuples" {
    // Tuples: just a collection of values with indices as field names.
    const hero_stats = .{100, 50.5, "strong"};
    // hero_stats[0] = 100;
    // hero_stats[1] = 50.5;
    // hero_stats[2] = "strong";
    
    try expect(hero_stats.len == 3);
    try expect(hero_stats.@"0" == 100);
    try expect(hero_stats.@"2"[0] == 's');
}

fn check(settings: anytype) !void {
    try expect(settings.max_health == 200);
    try expect(settings.respawn_enabled);
}
