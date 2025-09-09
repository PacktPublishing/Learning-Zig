const std = @import("std");

const Day = enum {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
};

pub fn main() void {
    const info = @typeInfo(Day);
    const enumInfo = info.@"enum";
    std.debug.print("Enum tag type: {s}\n", .{@typeName(enumInfo.tag_type)});

    inline for (enumInfo.fields) |field| {
        std.debug.print("Field: {s}\n", .{field.name});
    }
}

