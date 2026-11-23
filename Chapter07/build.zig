const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Executable: reverse_string
    const exe = b.addExecutable(.{
        .name = "reverse_string",
        .root_module = b.createModule(.{ .root_source_file = b.path("reverse_string.zig"), .target = target, .optimize = optimize }),
    });
    b.installArtifact(exe);

    // Run step: forwards args given after `--`, e.g. `zig build run-reverse -- hello world`
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs();
    const run_step = b.step("run-reverse", "Run reverse_string with args (zig build run-reverse -- hello world)");
    run_step.dependOn(&run_cmd.step);

    // Unit tests for Chapter 7 files
    const t_reverse = b.addTest(.{
        .root_module = b.createModule(.{ .root_source_file = b.path("reverse_string.zig"), .target = target, .optimize = optimize }),
    });

    const t_square_src = b.addTest(.{
        .root_module = b.createModule(.{ .root_source_file = b.path("src/square.zig"), .target = target, .optimize = optimize }),
    });

    const t_skipping = b.addTest(.{
        .root_module = b.createModule(.{ .root_source_file = b.path("skipping.zig"), .target = target, .optimize = optimize }),
    });

    const test_step = b.step("test", "Run Chapter 07 unit tests");
    test_step.dependOn(&t_reverse.step);
    test_step.dependOn(&t_square_src.step);
    test_step.dependOn(&t_skipping.step);
}
