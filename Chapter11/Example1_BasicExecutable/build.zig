const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimization options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the module for the executable
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create the executable artifact
    const exe = b.addExecutable(.{
        .name = "hello-zig",
        .root_module = exe_mod,
    });

    // Install the executable into zig-out/bin
    b.installArtifact(exe);

    // Create a "run" step to execute the compiled binary
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep()); // Ensure it's built first.

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}