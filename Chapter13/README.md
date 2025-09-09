# zig-file-guard (fg)

A fast, cross-platform file monitoring tool written in Zig. It scans a directory tree and reports file changes to the console: created, deleted, modified, moved/renamed, permissions, and timestamps. Move detection is inode-based when available.

This README reflects the current state of the codebase (Zig 0.15.x, executable name: fg) and adds setup, usage, and testing details.


## Requirements
- Zig 0.15.1 (recommended for reproducibility)
- Optional: mise for tool pinning
  - mise trust
  - mise install

Dependencies are fetched automatically by Zig. CLI parsing uses ikskuh/zig-args (declared as dependency "args" in `build.zig.zon`).


## Build and run
- Build: zig build
- Run through build system: zig build run -- --help
- Or run installed binary: ./zig-out/bin/fg --help
- The binary links against libc.

Examples:
- Monitor current directory once: ./zig-out/bin/fg .
- Monitor continuously every 2s: ./zig-out/bin/fg --continuous --interval=2 .


## Usage
Syntax: fg [OPTIONS] [PATH]
- If PATH is omitted, the current directory (.) is monitored.

Options (long form shown; short forms in parentheses):
- -h, --help                  Show help
- -v, --verbose               Verbose output
- -i, --include-patterns=CSV  Comma-separated glob patterns to include (default: *)
- -x, --exclude-patterns=CSV  Comma-separated glob patterns to exclude
- -d, --max-depth=N           Maximum traversal depth (null/unset = unlimited; 0 = root-only)
- -s, --follow-symlinks       Follow symbolic links during traversal
- -c, --hash-content          Compute SHA-256 for files (slower, enables content-level detection)
- -t, --monitor-timestamps    Detect timestamp changes (default: true)
- -z, --monitor-size          Detect size changes (default: true)
- -C, --monitor-content       Detect content changes (requires --hash-content)
- -p, --monitor-permissions   Detect permission changes
- -m, --detect-moves          Detect moves/renames (default: true; inode-based)
- -w, --continuous            Monitor continuously (loop)
- -n, --interval=SECONDS      Polling interval for continuous mode (default: 60)

Notes:
- --monitor-content requires --hash-content; the CLI enforces this.
- If you pass multiple PATHs, only the first positional argument is used.


## Pattern semantics
- Patterns are matched against the traversal path (join(dir, entry_name)), not only basenames and not the resolved target path of symlinks.
- Glob examples: *.txt, */*.txt, subdir/*.zig
- Exclude patterns take precedence over include.
- Because matching is done on full traversal paths, a simple pattern like *.txt will match file tails anywhere in the tree. Use more specific patterns if needed.


## Traversal, depth, and symlinks
- max_depth=null (default) means unlimited depth; 0 means root-only; children increment depth before recursion.
- follow_symlinks=false by default. When true, traversal may include symlinked entries. Pattern matching still applies to the traversal path name (the symlink itself), not the resolved absolute target path.


## Change detection and hashing
- Order of checks: content (when enabled), then size, permissions, timestamps.
- inode-based move detection needs non-zero inode values; on some filesystems/platforms inode may be 0 and move detection is skipped.
- Hashing reads files with a 4KB buffer. Enable only when you need content-level detection.


## Examples
- Only text files, once: `./zig-out/bin/fg -i "*.txt" .`
- Include .txt and .md but exclude logs and temp: `./zig-out/bin/fg -i "*.txt,*.md" -x "*.log,*.tmp" .`
- Root-only scan (depth 0): `./zig-out/bin/fg -d 0 .`
- Follow symlinks at root-only and include any entry: `./zig-out/bin/fg -s -d 0 -i "*" .`
- Continuous every 3s with content monitoring: `./zig-out/bin/fg -w -n 3 -c -C .`


## Testing
- Run all tests: zig build test
- Run a single module during iteration:
  - zig test src/pattern.zig
  - zig test src/file_index.zig
  - zig test src/file_metadata.zig
  - zig test src/change_detection.zig
  - zig test src/traversal.zig
- Filter tests with --test-filter when using zig test directly.


## Troubleshooting
- Ensure Zig 0.14.0 for reproducibility. If using `mise`: `mise trust && mise install`.
- If move detection seems missing, your filesystem may report inode 0.
- Continuous monitoring logs traversal errors and retries next interval; in one-shot mode, errors bubble up.


## Project structure
- build.zig / build.zig.zon
- src/
  - main.zig (entrypoint)
  - cli.zig (CLI and monitor loop)
  - config.zig (TraversalConfig)
  - pattern.zig (fnmatch-based globbing)
  - traversal.zig (directory walk with include/exclude, depth, symlinks)
  - file_metadata.zig (path, stat data, optional checksum)
  - file_index.zig (maps paths and inodes; deep clone; deinit)
  - change_detection.zig (diff indices, journal, change types)

Executable name: fg (installed to zig-out/bin/fg).
