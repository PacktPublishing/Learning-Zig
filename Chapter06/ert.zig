pub fn main() !void {
    try topFunction();
}

fn topFunction() !void {
    try midFunction();
}

fn midFunction() !void {
    try bottomFunction();
}

fn bottomFunction() !void {
    return error.FileNotFound;
}
