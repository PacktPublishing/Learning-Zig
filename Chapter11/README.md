Chapter 11 – Build System Examples

This chapter contains four independent mini-projects demonstrating Zig’s build system features.

Each example is a separate folder with its own `build.zig` and `src/main.zig`.

How to use (run from inside each example folder):
- Build: `zig build`
- Run: `zig build run`

Examples:

1) Example1_BasicExecutable
   - Minimal executable using addExecutable/installArtifact and a run step.

2) Example2_CrossCompilation
   - Demonstrates target selection and validates an allowlist of supported targets.
   - Prints the selected target arch and OS.
   - Try valid builds like:
     * zig build -Dtarget=x86_64-linux-gnu
     * zig build -Dtarget=aarch64-macos-none
   - Disallowed targets will cause a build error with a helpful message.

3) Example3_ReleaseModes
   - Showcases how different optimization modes affect safety/UB for integer overflow.
   - Try:
     * zig build run -Doptimize=Debug (panics)
     * zig build run -Doptimize=ReleaseSafe (panics)
     * zig build run -Doptimize=ReleaseFast (wraps/undefined behavior)

4) Example4_CustomOptions
   - Passes a custom compile-time option (dark_mode) via addOptions.
   - Try:
     * zig build run
     * zig build run -Ddark_mode=true
