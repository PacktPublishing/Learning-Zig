const std = @import("std");

// Export the function for C compatibility, C calling convention
export fn count_words(str: [*:0]const u8) callconv(.C) u32 {
    var count: u32 = 0;
    var in_word: bool = false;
    var i: usize = 0;

    while (str[i] != 0) : (i += 1) {
        const c = str[i];
        if (std.ascii.isWhitespace(c)) {
            in_word = false;
        } else if (!in_word) {
            count += 1;
            in_word = true;
        }
    }

    return count;
}

// Zig-side tests exercising the exported function
// Note: c"..." yields a zero-terminated string literal suitable for [*:0]const u8

test "ch12: export count_words and call from Zig" {
    const alloc = std.testing.allocator;

    const s1 = try alloc.dupeZ(u8, "Zig is awesome");
    defer alloc.free(s1);
    try std.testing.expectEqual(@as(u32, 3), count_words(s1.ptr));

    const s2 = try alloc.dupeZ(u8, "  many   spaces here  ");
    defer alloc.free(s2);
    try std.testing.expectEqual(@as(u32, 3), count_words(s2.ptr));

    const s3 = try alloc.dupeZ(u8, "");
    defer alloc.free(s3);
    try std.testing.expectEqual(@as(u32, 0), count_words(s3.ptr));
}

// C usage example (not compiled here):
// #include <stdint.h>
// extern uint32_t count_words(const char *str);
// int main(){ return (int)count_words("Zig is awesome"); }
