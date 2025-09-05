const std = @import("std");

const expect = std.testing.expect;

test "managing player health using pointers" {
    const npc_health: i32 = 100;

    const npc_health_ptr = &npc_health;

    try expect(npc_health_ptr.* == 100);
    try expect(@TypeOf(npc_health_ptr) == *const i32);

    var player_health: i32 = 150;
    const player_health_ptr = &player_health;

    try expect(@TypeOf(player_health_ptr) == *i32);
    player_health_ptr.* -= 20;
    try expect(player_health_ptr.* == 130);
    try expect(player_health == 130);
}