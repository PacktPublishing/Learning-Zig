const std = @import("std");

/// reverseString returns a newly allocated string that is the reverse of `s`.
/// The caller owns the returned memory and must free it with the same allocator.
pub fn reverseString(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    const len = s.len;
    var out = try allocator.alloc(u8, len);
    // Reverse copy
    var i: usize = 0;
    while (i < len) : (i += 1) {
        out[i] = s[len - 1 - i];
    }
    return out;
}

/// Example program that reverses each command line argument and prints it.
/// In Zig 0.16, main accepts std.process.Init for access to args, allocator, and I/O.
pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var args = init.minimal.args.iterate();
    _ = args.next(); // skip program name

    var saw_any = false;
    while (args.next()) |arg| {
        saw_any = true;
        const reversed = try reverseString(allocator, arg);
        defer allocator.free(reversed);
        std.debug.print("{s}\n", .{reversed}); // use {s} for slices/strings
    }

    if (!saw_any) {
        std.debug.print("usage: reverse_string <words...>\n", .{});
    }
}

// -----------------
// Tests
// -----------------

test "reverseString reverses ascii text" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "hello";
    const out = try reverseString(allocator, input);
    defer allocator.free(out);
    try std.testing.expectEqualStrings("olleh", out);
}

test "reverseString handles empty string" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "";
    const out = try reverseString(allocator, input);
    defer allocator.free(out);
    try std.testing.expectEqual(@as(usize, 0), out.len);
}

test "reverseString works with punctuation and spaces" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "a man, a plan";
    const out = try reverseString(allocator, input);
    defer allocator.free(out);
    try std.testing.expectEqualStrings("nalp a ,nam a", out);
}