const Point = struct {
    x: i32,
    y: i32,
};

fn translate(p: Point, dx: i32, dy: i32) Point {
    return Point{ .x = p.x + dx, .y = p.y + dy };
}
