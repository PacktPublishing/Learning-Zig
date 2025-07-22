const std = @import("std");
const testing = std.testing;
const expect = std.testing.expect;

test "allocator resize functionality" {
    // Create a general-purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        // Check for memory leaks
        const leak_status = gpa.deinit();
        // Can't use try in defer, so we'll use this approach instead
        if (leak_status == .leak) {
            std.debug.print("Memory leak detected\n", .{});
            unreachable;
        }
    }
    const allocator = gpa.allocator();

    // Allocate initial memory
    const initial_size: usize = 100;
    var memory: []u8 = try allocator.alloc(u8, initial_size);
    // Use defer to ensure memory is freed if we exit early
    // This will be a no-op if memory is an empty slice (after resize to 0)
    defer if (memory.len > 0) allocator.free(memory);
    
    // Fill memory with a pattern to verify contents
    @memset(memory, 0xAA);
    try expect(memory.len == initial_size);
    try expect(memory[0] == 0xAA);
    try expect(memory[initial_size - 1] == 0xAA);

    // Case 1: Resize to a smaller size (shrinking)
    const smaller_size: usize = 50;
    const shrink_success = allocator.resize(memory, smaller_size);
    // Shrinking may succeed or fail depending on the allocator implementation
    // If it succeeds, update our slice to reflect the new size
    if (shrink_success) {
        memory = memory.ptr[0..smaller_size];
        std.debug.print("Shrink succeeded\n", .{});
    } else {
        // If shrinking fails, we need to allocate a new buffer
        const new_memory = try allocator.alloc(u8, smaller_size);
        @memcpy(new_memory, memory[0..smaller_size]);
        allocator.free(memory);
        memory = new_memory;
        std.debug.print("Shrink failed, allocated new buffer\n", .{});
    }
    // Verify the content is preserved
    try expect(memory[0] == 0xAA);
    try expect(memory[smaller_size - 1] == 0xAA);

    // Case 2: Resize to a larger size (growing)
    const larger_size: usize = 200;
    const grow_success = allocator.resize(memory, larger_size);
    // This may succeed or fail depending on the allocator implementation
    // and whether there's adjacent free memory
    if (grow_success) {
        // If successful, update our slice to reflect the new size
        memory = memory.ptr[0..larger_size];
        // Original content should be preserved
        try expect(memory[0] == 0xAA);
        try expect(memory[smaller_size - 1] == 0xAA);
        // Initialize the newly allocated portion
        @memset(memory[smaller_size..], 0xBB);
        try expect(memory[larger_size - 1] == 0xBB);
    } else {
        // If resize fails, the original memory is unchanged
        try expect(memory.len == smaller_size);
        
        // When resize fails, we typically need to:
        // 1. Allocate new memory of the desired size
        // 2. Copy the contents from the old memory
        // 3. Free the old memory
        var new_memory = try allocator.alloc(u8, larger_size);
        
        @memcpy(new_memory[0..memory.len], memory);
        @memset(new_memory[memory.len..], 0xBB);
        
        try expect(new_memory.len == larger_size);
        try expect(new_memory[0] == 0xAA);
        try expect(new_memory[smaller_size - 1] == 0xAA);
        try expect(new_memory[larger_size - 1] == 0xBB);
        
        // Free the old memory and use the new memory instead
        allocator.free(memory);
        memory = new_memory;
    }

    // Case 3: Resize to zero (equivalent to free)
    // This should always succeed
    _ = allocator.resize(memory, 0);
    // After resizing to 0, the memory is freed and should not be accessed
    // Mark that we've already freed the memory
    memory = &[_]u8{};
    
    // Case 4: Demonstrate using a fixed buffer allocator which has limited capacity
    var buffer: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fixed_allocator = fba.allocator();
    
    var fixed_memory = try fixed_allocator.alloc(u8, 100);
    defer fixed_allocator.free(fixed_memory);
    
    @memset(fixed_memory, 0xCC);
    
    // Shrinking should succeed
    const fixed_shrink = fixed_allocator.resize(fixed_memory, 50);
    try expect(fixed_shrink);
    fixed_memory = fixed_memory.ptr[0..50];
    try expect(fixed_memory.len == 50);
    
    // Growing beyond buffer capacity should fail
    const fixed_grow = fixed_allocator.resize(fixed_memory, 300);
    try expect(!fixed_grow);
    try expect(fixed_memory.len == 50);
}

test "failing allocator with resize index" {
    // Create a FailingAllocator that will fail on the 2nd resize operation
    var failing_allocator = std.testing.FailingAllocator.init(std.testing.allocator, .{
        .resize_fail_index = 2, // Fail on the 3rd resize operation (index 2)
    });
    const allocator = failing_allocator.allocator();
    
    // Allocate some memory
    var buffer: []u8 = try allocator.alloc(u8, 64);
    defer allocator.free(buffer);

    // Demonstrate resize behavior
    // First resize operation
    if (allocator.resize(buffer, 50)) {
        // Update the slice to reflect the new size
        buffer = buffer.ptr[0..50];
    }

    // Second resize operation - this should fail based on our configuration
    if (allocator.resize(buffer, 30)) {
        // Update the slice to reflect the new size
        buffer = buffer.ptr[0..30];
    }
    
    // Verify that the third resize failed
    try expect(buffer.len == 50);
}