# Building a Generic Stack in Zig (Step by Step)

This tutorial walks you through creating the generic stack implemented in `ch12_1/generic_stack.zig`. Along the way you'll learn about:
- Type factories: `pub fn Stack(comptime T: type) type { ... }`
- Using `@This()` for a convenient `Self` alias
- Managing heap memory with an `Allocator`
- Accepting `anytype` and coercing to a concrete `T`
- Returning typed values with error unions (e.g., `!T`)
- Writing basic tests with `zig test`

If you just want to run the tests for the finished implementation:

- Command: `zig test ch12_1/generic_stack.zig`

---

## 0) Goal and shape of the API
We want a fixed-capacity, heap-backed stack that works for any element type `T`.
- Create a type factory `Stack(T)` that returns a struct type tailored to `T`.
- API:
  - `init(allocator, cap) !Self`
  - `deinit()`
  - `isEmpty() bool`, `isFull() bool`, `capacity() usize`
  - `push(item: anytype) !void`
  - `pop() !T`
  - `peek() !T`
- Errors: `StackOverflow` when full, `StackUnderflow` when empty.

---

## 1) Define the type factory
A type factory is just a function that returns a type. We want to pass the element type at compile time.

```zig
pub fn Stack(comptime T: type) type {
    return struct {
        // implementation follows
    };
}
```

- `comptime T: type` means callers must supply a concrete type (e.g., `i32`, `[]const u8`).
- `return struct { ... };` creates a new struct type parameterized by `T`.

---

## 2) Add a Self alias and fields
Inside the returned struct, alias the type to `Self` and declare the fields we need:

```zig
const std = @import("std");

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        items: []T, // owned buffer holding up to "capacity" Ts
        len: usize, // current number of elements
    };
}
```

- `@This()` is Zig’s way of referring to the current struct type; it lets us name the type `Self` for ergonomic method signatures.
- `items` is a slice of `T` that will point to a heap-allocated buffer we own.
- `len` tracks how many items are on the stack.

---

## 3) Initialize with a heap buffer
We provide an `init` that allocates a buffer large enough to hold `cap` items of type `T`.

```zig
pub fn init(allocator: std.mem.Allocator, cap: usize) !Self {
    const buf = try allocator.alloc(T, cap);
    return .{ .allocator = allocator, .items = buf, .len = 0 };
}
```

- `!Self` means this can fail with an error (e.g., out of memory). `try` propagates any error.
- `allocator.alloc(T, cap)` requests a buffer of `cap` elements of type `T`.

---

## 4) Deinitialize and guard against use-after-free
Make sure to release the buffer and optionally poison the struct to catch bugs.

```zig
pub fn deinit(self: *Self) void {
    self.allocator.free(self.items);
    self.* = undefined; // helps surface accidental use-after-free
}
```

---

## 5) Convenience helpers
These helpers make the core operations clearer:

```zig
pub fn isEmpty(self: *const Self) bool { return self.len == 0; }

pub fn isFull(self: *const Self) bool { return self.len == self.items.len; }

pub fn capacity(self: *const Self) usize { return self.items.len; }
```

---

## 6) Pushing values: anytype + coercion to T
We’d like `push` to accept either `T` or something that can be coerced to `T` (e.g., a comptime literal).

```zig
pub fn push(self: *Self, item: anytype) !void {
    if (self.isFull()) return error.StackOverflow;
    const converted: T = item; // works if item is T or comptime-coercible to T
    self.items[self.len] = converted;
    self.len += 1;
}
```

Notes:
- `anytype` accepts anything at the call site; we immediately force it to `T` via `const converted: T = item;`.
- Zig does NOT implicitly cast runtime numeric values. If you have a `u8` variable and your stack is `Stack(i32)`, you must cast explicitly.

Example explicit cast when pushing a `u8` into a `Stack(i32)`:

```zig
const std = @import("std");
const gpa = std.heap.page_allocator; // example allocator

var s = try Stack(i32).init(gpa, 4);
defer s.deinit();

var small: u8 = 7;
try s.push(@intCast(i32, small)); // explicit numeric cast
```

- String literals coerce to `[]const u8`, so they work naturally with `Stack([]const u8)`.

---

## 7) Popping and peeking
Both operations fail with `StackUnderflow` if the stack is empty.

```zig
pub fn pop(self: *Self) !T {
    if (self.len == 0) return error.StackUnderflow;
    self.len -= 1;
    return self.items[self.len];
}

pub fn peek(self: *const Self) !T {
    if (self.len == 0) return error.StackUnderflow;
    return self.items[self.len - 1];
}
```

---

## 8) Tests to verify behavior
Put tests in the same file (as in `generic_stack.zig`) to exercise the core behavior:

```zig
const expect = std.testing.expect;
const expectError = std.testing.expectError;

test "generic stack basics with ints" {
    const gpa = std.testing.allocator;
    var s = try Stack(i32).init(gpa, 3);
    defer s.deinit();

    try expect(s.isEmpty());
    try expect(s.capacity() == 3);

    // comptime integer literals coerce to i32
    try s.push(10);
    try s.push(20);
    try expect(s.len == 2);
    try expect(try s.peek() == 20);

    // fill to capacity and check overflow
    try s.push(30);
    try expect(s.isFull());
    try expectError(error.StackOverflow, s.push(40));

    const v1 = try s.pop();
    const v2 = try s.pop();
    try expect(v1 == 30);
    try expect(v2 == 20);
    try expect(try s.pop() == 10);
    try expectError(error.StackUnderflow, s.pop());
}

test "generic stack with slices shows anytype + coercion" {
    const gpa = std.testing.allocator;
    var s = try Stack([]const u8).init(gpa, 2);
    defer s.deinit();

    // string literals coerce to []const u8
    try s.push("hello");
    try s.push("world");

    const b = try s.pop();
    const a = try s.pop();
    try expect(std.mem.eql(u8, a, "hello"));
    try expect(std.mem.eql(u8, b, "world"));
}
```

Run them with:

```bash
zig test ch12_1/generic_stack.zig
```

---

## 9) Common pitfalls
- Forgetting to `deinit`: you’ll leak the heap buffer. Use `defer s.deinit();` in tests and examples.
- Pushing a runtime numeric with a different integer type into `Stack(T)` without an explicit cast (e.g., `@intCast(i32, my_u8)`).
- Accessing the stack after `deinit`: we intentionally set `self.* = undefined` to help catch this during development.

---

## 10) Where to look in this repo
The complete, working implementation lives here:
- `ch12_1/generic_stack.zig`

Use this tutorial to understand each line and then compare with the final file.

---

## 11) Extensions to try
- Make the stack dynamically grow (e.g., double capacity on overflow).
- Add a `clear()` method that just sets `len = 0`.
- Add an `iterator()` that yields items from top to bottom.
- Make `push` return the new length (`!usize`) for convenience.
