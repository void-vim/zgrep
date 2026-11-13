const std = @import("std");
const cwd = std.Io.Dir.cwd();
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);

    if (args.len <= 1) {
        print("Usage: zgrep <word> [FILE]\n", .{});
        return;
    }

    const search: []const u8 = args[1];
    const file_path: []const u8 = if (args.len > 2) args[2] else "";

    var stdin_buffer: [4096]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);

    const input: []u8 = blk: switch (file_path.len) {
        else => {
            if (file_path.len > 0) {
                break :blk try std.Io.Dir.readFileAlloc(
                    cwd,
                    io,
                    file_path,
                    alloc,
                    .unlimited,
                );
            } else {
                break :blk try stdin_reader.interface.allocRemaining(
                    alloc,
                    .unlimited,
                );
            }
        },
    };
    defer alloc.free(input);

    // splitScalar: divide data based 1 character '\n' (new line)
    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (std.mem.find(u8, line, search)) |idx| {
            const before = line[0..idx];
            const matched = line[idx .. idx + search.len];
            const after = line[idx + search.len ..];

            // \x1b[1m = bold
            // \x1b[32m = green
            // \x1b[0m = reset
            print("{s}\x1b[1m\x1b[32m{s}\x1b[0m{s}\n", .{
                before,
                matched,
                after,
            });
        }
    }
}
