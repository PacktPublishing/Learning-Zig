const std = @import("std");

fn isAllowedTarget(t: std.Target) bool {
    const Arch = std.Target.Cpu.Arch;
    const OsTag = std.Target.Os.Tag;
    const Abi = std.Target.Abi;

    const allowed = [_]struct { arch: Arch, os: OsTag, abi: Abi }{
        .{ .arch = .x86_64, .os = .linux, .abi = .gnu },
        .{ .arch = .aarch64, .os = .macos, .abi = .none },
    };

    for (allowed) |a| {
        if (t.cpu.arch == a.arch and t.os.tag == a.os and t.abi == a.abi) return true;
    }
    return false;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Validate chosen target against allowlist to provide clear feedback.
    const resolved = target.result;
    if (!isAllowedTarget(resolved)) {
        std.log.err("Target not allowed: {s}-{s}-{s}. Allowed: x86_64-linux-gnu, aarch64-macos-none", .{
            @tagName(resolved.cpu.arch),
            @tagName(resolved.os.tag),
            @tagName(resolved.abi),
        });
        @panic("Disallowed target");
    }

    // Create the module for the executable
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "cross-platform-app",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);
}