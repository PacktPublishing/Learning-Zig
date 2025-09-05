const Result = union(enum) {
    Success: i32,
    Error: []const u8,
};
