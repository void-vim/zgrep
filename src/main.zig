const std = @import("std");
const cwd = std.Io.Dir.cwd();
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writter = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writter.interface;

    if (args.len <= 1) {
        try stdout.writeAll("Usage: zgrep <word> [FILE]\n");
        try stdout.flush();
        return;
    }

    const search: []const u8 = args[1];
    const file_path: []const u8 = if (args.len > 2) args[2] else "";

    var buffer: [4096]u8 = undefined;
    if (file_path.len > 0) {
        var file = try cwd.openFile(io, file_path, .{});
        defer file.close(io);

        var file_reader = file.reader(io, &buffer);
        try processReader(&file_reader.interface, search, stdout);
    } else {
        var stdin_reader = std.Io.File.stdin().reader(io, &buffer);
        try processReader(&stdin_reader.interface, search, stdout);
    }
}

fn processReader(reader: *std.Io.Reader, search: []const u8, stdout: *std.Io.Writer) !void {
    while (try reader.takeDelimiter('\n')) |line| {
        if (std.mem.find(u8, line, search)) |idx| {
            const before = line[0..idx];
            const matched = line[idx .. idx + search.len];
            const after = line[idx + search.len ..];

            // \x1b[1m = bold
            // \x1b[32m = green
            // \x1b[0m = reset
            try stdout.print("{s}\x1b[1m\x1b[32m{s}\x1b[0m{s}\n", .{
                before,
                matched,
                after,
            });
            try stdout.flush();
        }
    }
}
