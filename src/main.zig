const std = @import("std");
const cwd = std.Io.Dir.cwd();
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const alloc = init.arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);

    if (args.len <= 2) {
        print("Usage: <word> <file_path>\n", .{});
        return;
    }

    const search: []const u8 = args[1];
    const filename: []const u8 = args[2];

    const content = try std.Io.Dir.readFileAlloc(
        cwd,
        io,
        filename,
        alloc,
        .unlimited,
    );
    defer alloc.free(content);
    // splitScalar: divide data based 1 character '\n' (new line)
    var lines = std.mem.splitScalar(u8, content, '\n');

    while (lines.next()) |line| {
        if (std.mem.find(u8, line, search)) |pos| {
            const before = line[0..pos];
            const matched = line[pos .. pos + search.len];
            const after = line[pos + search.len ..];

            // \x1b[32m = green
            // \x1b[0m = reset
            print("{s}\x1b[32m{s}\x1b[0m{s}\n", .{ before, matched, after });
        }
    }
}
