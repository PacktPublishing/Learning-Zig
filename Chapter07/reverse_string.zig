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
/// Demonstrates correct usage of std.process.args() and {s} formatting for strings.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) std.debug.print("warning: memory leak detected\n", .{});
    }
    const allocator = gpa.allocator();

    var args = std.process.args(); // In Zig 0.15 this returns an ArgIterator directly
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "hello";
    const out = try reverseString(allocator, input);
    defer allocator.free(out);
    try std.testing.expectEqualStrings("olleh", out);
}

test "reverseString handles empty string" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "";
    const out = try reverseString(allocator, input);
    defer allocator.free(out);
    try std.testing.expectEqual(@as(usize, 0), out.len);
}

test "reverseString works with punctuation and spaces" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = "a man, a plan";
    const out = try reverseString(allocator, input);
    defer allocator.free(out);
    try std.testing.expectEqualStrings("nalp a ,nam a", out);
}