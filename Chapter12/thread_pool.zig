const std = @import("std");

fn worker(slot: usize, task_id: usize) void {
    std.debug.print("Worker slot {d} executing task {d}\n", .{ slot, task_id });
    // Simulate some work
    std.Thread.sleep(10 * std.time.ns_per_ms);
}

pub fn main() !void {
    const num_workers = 5; // fixed-size pool
    const num_tasks = 10; // total tasks to execute

    var threads: [num_workers]std.Thread = undefined;

    var next_task: usize = 0;
    while (next_task < num_tasks) {
        const remaining = num_tasks - next_task;
        const batch_size: usize = if (remaining < num_workers) remaining else num_workers;

        // Dispatch up to num_workers tasks in this batch
        var i: usize = 0;
        while (i < batch_size) : (i += 1) {
            const task_id = next_task + i;
            threads[i] = try std.Thread.spawn(.{}, worker, .{ i, task_id });
        }

        // Wait for current batch to finish before scheduling the next tasks
        i = 0;
        while (i < batch_size) : (i += 1) {
            threads[i].join();
        }

        next_task += batch_size;
    }

    std.debug.print("All {d} tasks completed using {d} worker slots.\n", .{ num_tasks, num_workers });
}
