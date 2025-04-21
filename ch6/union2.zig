const std = @import("std");

const Response = union(enum) {
    Data: i32,

    Message: []const u8,

    pub fn isData(self: Response) bool {
        return std.mem.eql(u8, @tagName(self), "Data");
    }
};

pub fn main() void {
    const resp = Response{ .Data = 100 };
    if (resp.isData()) {
        std.debug.print("Received data: {d}\n", .{resp.Data});
    }
}
