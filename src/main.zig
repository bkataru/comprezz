const std = @import("std");
const comprezz = @import("comprezz");
const io = std.io;
const process = std.process;
const fs = std.fs;
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    if (args.len <= 1) {
        try printUsage();
        std.process.exit(0);
    }

    const command = args[1];

    if (mem.eql(u8, command, "--help") or mem.eql(u8, command, "-h")) {
        try printUsage();
        return;
    }

    if (mem.eql(u8, command, "--version") or mem.eql(u8, command, "-v")) {
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
        try stdout.writeAll("comprezz 0.1.0\n");
        try stdout.flush();
        return;
    }

    if (mem.eql(u8, command, "-d") or mem.eql(u8, command, "--decompress")) {
        var stderr_buffer: [4096]u8 = undefined;
        var stderr_writer = fs.File.stderr().writer(&stderr_buffer);
        const stderr = &stderr_writer.interface;
        try stderr.writeAll("error: decompression not yet implemented\n");
        try stderr.flush();
        std.process.exit(1);
    }

    var input_file: ?[]const u8 = null;
    var output_file: ?[]const u8 = null;
    var compression_level = comprezz.Level.default;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (mem.eql(u8, arg, "-o") or mem.eql(u8, arg, "--output")) {
            if (i + 1 >= args.len) {
                var stderr_buffer: [4096]u8 = undefined;
                var stderr_writer = fs.File.stderr().writer(&stderr_buffer);
                const stderr = &stderr_writer.interface;
                try stderr.writeAll("error: -o requires an output file\n");
                try stderr.flush();
                std.process.exit(1);
            }
            output_file = args[i + 1];
            i += 1;
        } else if (mem.eql(u8, arg, "-l") or mem.eql(u8, arg, "--level")) {
            if (i + 1 >= args.len) {
                var stderr_buffer: [4096]u8 = undefined;
                var stderr_writer = fs.File.stderr().writer(&stderr_buffer);
                const stderr = &stderr_writer.interface;
                try stderr.writeAll("error: -l requires a compression level\n");
                try stderr.flush();
                std.process.exit(1);
            }
            compression_level = parseLevel(args[i + 1]) catch {
                var stderr_buffer: [4096]u8 = undefined;
                var stderr_writer = fs.File.stderr().writer(&stderr_buffer);
                const stderr = &stderr_writer.interface;
                try stderr.print("error: invalid compression level: {s}\n", .{args[i + 1]});
                try stderr.flush();
                std.process.exit(1);
            };
            i += 1;
        } else if (!mem.startsWith(u8, arg, "-")) {
            if (input_file == null) {
                input_file = arg;
            } else {
                var stderr_buffer: [4096]u8 = undefined;
                var stderr_writer = fs.File.stderr().writer(&stderr_buffer);
                const stderr = &stderr_writer.interface;
                try stderr.writeAll("error: multiple input files specified\n");
                try stderr.flush();
                std.process.exit(1);
            }
        }
    }

    // Create input reader with buffer
    var input_buffer: [8192]u8 = undefined;
    var input_file_handle: ?fs.File = null;
    var input_file_reader_var: fs.File.Reader = undefined;
    var stdin_reader_var: fs.File.Reader = undefined;

    const input_reader = if (input_file) |path| blk: {
        input_file_handle = try fs.cwd().openFile(path, .{});
        input_file_reader_var = input_file_handle.?.reader(&input_buffer);
        break :blk &input_file_reader_var.interface;
    } else blk: {
        stdin_reader_var = fs.File.stdin().reader(&input_buffer);
        break :blk &stdin_reader_var.interface;
    };
    defer if (input_file_handle) |f| f.close();

    // Create output writer with buffer
    var output_buffer: [8192]u8 = undefined;
    var output_file_handle: ?fs.File = null;
    var output_file_writer_var: fs.File.Writer = undefined;
    var stdout_writer_var2: fs.File.Writer = undefined;

    const output_writer = if (output_file) |path| blk: {
        output_file_handle = try fs.cwd().createFile(path, .{});
        output_file_writer_var = output_file_handle.?.writer(&output_buffer);
        break :blk &output_file_writer_var.interface;
    } else blk: {
        stdout_writer_var2 = fs.File.stdout().writer(&output_buffer);
        break :blk &stdout_writer_var2.interface;
    };
    defer if (output_file_handle) |f| f.close();

    const options = comprezz.Options{ .level = compression_level };
    try comprezz.compress(input_reader, output_writer, options);
    try output_writer.flush();
}

fn parseLevel(level_str: []const u8) !comprezz.Level {
    if (mem.eql(u8, level_str, "fast")) return .fast;
    if (mem.eql(u8, level_str, "default")) return .default;
    if (mem.eql(u8, level_str, "best")) return .best;
    if (mem.eql(u8, level_str, "4")) return .level_4;
    if (mem.eql(u8, level_str, "5")) return .level_5;
    if (mem.eql(u8, level_str, "6")) return .level_6;
    if (mem.eql(u8, level_str, "7")) return .level_7;
    if (mem.eql(u8, level_str, "8")) return .level_8;
    if (mem.eql(u8, level_str, "9")) return .level_9;
    return error.InvalidLevel;
}

fn printUsage() !void {
    const usage =
        \\Usage: comprezz [OPTIONS] [INPUT_FILE]
        \\
        \\Compress files using gzip format.
        \\
        \\Options:
        \\  -o, --output FILE      Output file (default: stdout)
        \\  -l, --level LEVEL      Compression level: fast, default, best, or 4-9
        \\  -h, --help            Show this help message
        \\  -v, --version         Show version
        \\
        \\If no INPUT_FILE is specified, reads from stdin.
        \\
        \\Examples:
        \\  comprezz input.txt -o output.gz
        \\  comprezz -l best input.txt > output.gz
        \\  cat file.txt | comprezz > file.gz
        \\
    ;
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.writeAll(usage);
    try stdout.flush();
}
