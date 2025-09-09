const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Define a custom boolean option for dark mode
    const enable_dark_mode = b.option(bool, "dark_mode", "Enable Dark Mode UI") orelse false;

    // Create an options module to pass the value to the program
    const options = b.addOptions();
    options.addOption(bool, "is_dark_mode_enabled", enable_dark_mode);

    // Create module for the executable
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ui-app",
        .root_module = exe_mod,
    });

    // Add the options under the name "config"
    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}